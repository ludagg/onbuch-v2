// /api/result-lookup — fonction serverless Vercel (zéro-config /api).
//
// Résout une recherche de résultat pour une source configurée par l'admin
// (collection `result_sources`). Remplace la fonction Appwrite `result-lookup`
// (le plan Appwrite a atteint sa limite de fonctions).
//
// Aucun secret nécessaire : `result_sources` et `exam_results` sont en lecture
// publique (read("any")) → on lit via l'API REST Appwrite avec le seul header
// projet. Modes :
//   - `pdf` : télécharge le PDF (pdfUrl), en extrait le texte, cherche nom/num.
//   - `api` : interroge l'API externe configurée (apiUrl) et normalise.
//   - `manual` : lecture directe d'`exam_results` (fallback ; l'app le fait déjà).
//
// Requête : POST JSON { configId, query }  (ou GET ?configId=…&query=…).
// Réponse : { ok, found, result|null, message }.

const PdfParse = require('pdf-parse');

const APPWRITE_ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1';
const APPWRITE_PROJECT = process.env.APPWRITE_PROJECT || '6a30463b00001375e229';
const DATABASE_ID = process.env.DATABASE_ID || '6a3047f8001d11d1b3c1';
const SOURCES_COLLECTION = 'result_sources';
const EXAM_RESULTS_COLLECTION = 'exam_results';

const MENTIONS = ['EXCELLENT', 'TRES BIEN', 'TRÈS BIEN', 'BIEN', 'ASSEZ BIEN', 'PASSABLE'];

function norm(s) {
  return String(s ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function isNumeric(s) {
  return /^[0-9][0-9\s-]*$/.test(String(s ?? '').trim());
}

// Lit un document Appwrite en lecture publique (sans clé serveur).
async function getSource(configId) {
  const url = `${APPWRITE_ENDPOINT}/databases/${DATABASE_ID}/collections/${SOURCES_COLLECTION}/documents/${configId}`;
  const resp = await fetch(url, { headers: { 'X-Appwrite-Project': APPWRITE_PROJECT } });
  if (!resp.ok) throw new Error('source HTTP ' + resp.status);
  return resp.json();
}

// ── PDF ──────────────────────────────────────────────────────────────────────
async function searchPdf(source, rawQuery) {
  const url = (source.pdfUrl || '').trim();
  if (!url) return { found: false, message: 'Aucun PDF configuré pour cet examen.' };

  let buffer;
  try {
    const resp = await fetch(url);
    if (!resp.ok) throw new Error('HTTP ' + resp.status);
    buffer = Buffer.from(await resp.arrayBuffer());
  } catch (e) {
    return { found: false, error: true, message: 'Document de résultats inaccessible. Réessaie plus tard.' };
  }

  let text = '';
  try {
    const parsed = await PdfParse(buffer);
    text = parsed.text || '';
  } catch (e) {
    return { found: false, error: true, message: 'Lecture du document impossible.' };
  }

  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  const q = norm(rawQuery);
  if (!q) return { found: false };

  let matched = null;
  if (isNumeric(rawQuery)) {
    const num = q.replace(/\s+/g, '');
    for (const line of lines) {
      if (norm(line).split(' ').includes(num)) { matched = line; break; }
    }
  } else {
    const words = q.split(' ').filter((w) => w.length > 1);
    for (const line of lines) {
      const nl = norm(line);
      if (words.length && words.every((w) => nl.includes(w))) { matched = line; break; }
    }
  }

  if (!matched) {
    return { found: false, message: source.notFoundMessage || 'Nom / numéro introuvable dans la liste publiée.' };
  }

  const numToken = (matched.match(/\b\d{3,}\b/) || [])[0] || '';
  const upperMention = norm(matched);
  const mention = MENTIONS.find((m) => upperMention.includes(norm(m))) || '';
  const alpha = matched
    .replace(/[0-9]+/g, ' ')
    .split(/\s{2,}|\t|\|/)
    .map((s) => s.trim())
    .filter((s) => s.length > 2)
    .sort((a, b) => b.length - a.length)[0] || matched.trim();

  return {
    found: true,
    result: {
      examType: source.examType || source.label || '',
      year: source.year || '',
      tableNumber: isNumeric(rawQuery) ? rawQuery.trim() : numToken,
      candidateName: alpha,
      admitted: true,
      mention: mention ? mention.replace(/\b\w/g, (c) => c.toUpperCase()) : '',
    },
  };
}

// ── API externe ───────────────────────────────────────────────────────────────
function pick(obj, keys) {
  for (const k of keys) {
    if (obj && obj[k] != null && String(obj[k]).trim() !== '') return obj[k];
  }
  return undefined;
}

function toBool(v) {
  if (typeof v === 'boolean') return v;
  const s = String(v ?? '').trim().toLowerCase();
  return ['true', '1', 'admis', 'admise', 'pass', 'passed', 'oui', 'yes'].includes(s);
}

async function searchApi(source, rawQuery) {
  let url = (source.apiUrl || '').trim();
  if (!url) return { found: false, error: true, message: 'API non configurée pour cet examen.' };
  const enc = encodeURIComponent(rawQuery.trim());
  url = url.includes('{query}')
    ? url.replace(/\{query\}/g, enc)
    : url + (url.includes('?') ? '&' : '?') + 'query=' + enc;

  let json;
  try {
    const resp = await fetch(url, { headers: { Accept: 'application/json' } });
    if (resp.status === 404) return { found: false };
    if (!resp.ok) throw new Error('HTTP ' + resp.status);
    json = await resp.json();
  } catch (e) {
    return { found: false, error: true, message: 'Service de résultats indisponible. Réessaie plus tard.' };
  }

  let r = json;
  if (r && typeof r === 'object' && !Array.isArray(r)) {
    r = r.result ?? r.data ?? r.candidate ?? r;
  }
  if (Array.isArray(r)) r = r[0];
  if (!r || typeof r !== 'object') return { found: false };

  const candidateName = pick(r, ['candidateName', 'name', 'nom', 'fullName', 'nomComplet']);
  if (!candidateName) return { found: false };

  return {
    found: true,
    result: {
      examType: pick(r, ['examType', 'examen']) || source.examType || source.label || '',
      serie: pick(r, ['serie', 'series', 'série']) || '',
      year: pick(r, ['year', 'annee', 'année']) || source.year || '',
      tableNumber: String(pick(r, ['tableNumber', 'numero', 'numéro', 'table', 'candidateNumber', 'matricule']) || rawQuery.trim()),
      candidateName: String(candidateName),
      center: pick(r, ['center', 'centre']) || '',
      city: pick(r, ['city', 'ville']) || '',
      admitted: toBool(pick(r, ['admitted', 'admis', 'passed', 'success'])),
      mention: pick(r, ['mention']) || '',
      average: String(pick(r, ['average', 'moyenne']) || ''),
      threshold: String(pick(r, ['threshold', 'seuil', 'admissibilite']) || ''),
    },
  };
}

// ── Manuel (exam_results, lecture publique) ───────────────────────────────────
async function searchManual(source, rawQuery) {
  try {
    const base = `${APPWRITE_ENDPOINT}/databases/${DATABASE_ID}/collections/${EXAM_RESULTS_COLLECTION}/documents`;
    const queries = [
      JSON.stringify({ method: 'equal', attribute: 'examType', values: [source.examType || ''] }),
      JSON.stringify({ method: 'equal', attribute: 'tableNumber', values: [rawQuery.trim()] }),
      ...(source.year ? [JSON.stringify({ method: 'equal', attribute: 'year', values: [source.year] })] : []),
      JSON.stringify({ method: 'limit', values: [1] }),
    ];
    const qs = queries.map((q) => 'queries[]=' + encodeURIComponent(q)).join('&');
    const resp = await fetch(`${base}?${qs}`, { headers: { 'X-Appwrite-Project': APPWRITE_PROJECT } });
    if (!resp.ok) return { found: false };
    const data = await resp.json();
    if (!data.documents || !data.documents.length) return { found: false };
    const d = data.documents[0];
    return {
      found: true,
      result: {
        id: d.$id,
        examType: d.examType || '',
        serie: d.serie || '',
        year: d.year || '',
        tableNumber: d.tableNumber || '',
        candidateName: d.candidateName || '',
        center: d.center || '',
        city: d.city || '',
        admitted: d.admitted === true,
        mention: d.mention || '',
        average: d.average || '',
        threshold: d.threshold || '',
      },
    };
  } catch {
    return { found: false };
  }
}

module.exports = async (req, res) => {
  // CORS (l'app web onbuch-app.vercel.app appelle ce domaine).
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(204).end(); return; }

  const reply = (obj) => res.status(200).json({ ok: true, ...obj });
  const fail = (msg) => res.status(200).json({ ok: false, message: msg });

  let body = {};
  if (req.method === 'POST') {
    body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
  } else {
    body = req.query || {};
  }
  const configId = (body.configId || '').toString().trim();
  const query = (body.query || '').toString().trim();
  if (!configId || !query) return fail('Paramètres manquants.');

  let source;
  try {
    source = await getSource(configId);
  } catch (e) {
    return fail('Examen introuvable ou non configuré.');
  }

  const type = (source.sourceType || 'manual').toString().toLowerCase();
  try {
    let out;
    if (type === 'pdf') out = await searchPdf(source, query);
    else if (type === 'api') out = await searchApi(source, query);
    else out = await searchManual(source, query);

    if (out.error) return fail(out.message || 'Recherche indisponible.');
    return reply({ found: !!out.found, result: out.result || null, message: out.message || '' });
  } catch (e) {
    return fail('Recherche indisponible. Réessaie plus tard.');
  }
};
