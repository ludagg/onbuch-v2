// result-lookup — résout une recherche de résultat pour une source configurée
// par l'admin (collection `result_sources`).
//
// Flux : l'app envoie { configId, query } en SYNCHRONE. La fonction :
//   1. charge la source `result_sources/{configId}` ;
//   2. selon `sourceType` :
//        - `pdf` : télécharge le PDF (pdfUrl), en extrait le texte et y cherche
//                  le numéro / le nom du candidat ;
//        - `api` : interroge l'API externe configurée (apiUrl) et normalise la
//                  réponse ;
//   3. renvoie un résultat NORMALISÉ : { ok, found, result|null, message }.
//
// Le type `manual` est résolu côté app (lecture directe d'`exam_results`) ;
// s'il arrive ici, on le résout aussi par sécurité.
//
// Variables d'environnement à définir sur la fonction :
//   - APPWRITE_API_KEY : clé serveur Appwrite (scope databases.read).
//   - DATABASE_ID (optionnel, défaut ci-dessous).
// Appwrite injecte APPWRITE_FUNCTION_API_ENDPOINT et APPWRITE_FUNCTION_PROJECT_ID.

import { Client, Databases, Query } from 'node-appwrite';
import PdfParse from 'pdf-parse';

const DATABASE_ID = process.env.DATABASE_ID || '6a3047f8001d11d1b3c1';
const SOURCES_COLLECTION = 'result_sources';
const EXAM_RESULTS_COLLECTION = 'exam_results';

// Mots-clés de mention reconnus dans un PDF (du plus fort au plus faible).
const MENTIONS = ['EXCELLENT', 'TRES BIEN', 'TRÈS BIEN', 'BIEN', 'ASSEZ BIEN', 'PASSABLE'];

// Normalise pour comparaison : majuscules, sans accents, alphanumérique espacé.
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

// ── Recherche dans un PDF ────────────────────────────────────────────────────
async function searchPdf(source, rawQuery, log) {
  const url = (source.pdfUrl || '').trim();
  if (!url) return { found: false, message: 'Aucun PDF configuré pour cet examen.' };

  let buffer;
  try {
    const resp = await fetch(url);
    if (!resp.ok) throw new Error('HTTP ' + resp.status);
    buffer = Buffer.from(await resp.arrayBuffer());
  } catch (e) {
    log && log('PDF fetch failed: ' + e.message);
    return { found: false, error: true, message: 'Document de résultats inaccessible. Réessaie plus tard.' };
  }

  let text = '';
  try {
    const parsed = await PdfParse(buffer);
    text = parsed.text || '';
  } catch (e) {
    log && log('PDF parse failed: ' + e.message);
    return { found: false, error: true, message: 'Lecture du document impossible.' };
  }

  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  const q = norm(rawQuery);
  if (!q) return { found: false };

  let matched = null;
  if (isNumeric(rawQuery)) {
    // Recherche par numéro : on veut le numéro comme TOKEN entier dans la ligne.
    const num = q.replace(/\s+/g, '');
    for (const line of lines) {
      const tokens = norm(line).split(' ');
      if (tokens.includes(num)) { matched = line; break; }
    }
  } else {
    // Recherche par nom : tous les mots du nom doivent figurer dans la ligne.
    const words = q.split(' ').filter((w) => w.length > 1);
    for (const line of lines) {
      const nl = norm(line);
      if (words.length && words.every((w) => nl.includes(w))) { matched = line; break; }
    }
  }

  if (!matched) {
    return {
      found: false,
      message: source.notFoundMessage || 'Nom / numéro introuvable dans la liste publiée.',
    };
  }

  // Tente d'extraire nom, numéro et mention de la ligne trouvée.
  const numToken = (matched.match(/\b\d{3,}\b/) || [])[0] || '';
  const upperMention = norm(matched);
  const mention = MENTIONS.find((m) => upperMention.includes(norm(m))) || '';
  // Le nom = portion alphabétique la plus longue de la ligne.
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
      admitted: true, // un PDF de résultats liste les admis
      mention: mention ? mention.replace(/\b\w/g, (c) => c.toUpperCase()) : '',
    },
  };
}

// ── Recherche via API externe ────────────────────────────────────────────────
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

async function searchApi(source, rawQuery, log) {
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
    log && log('API call failed: ' + e.message);
    return { found: false, error: true, message: 'Service de résultats indisponible. Réessaie plus tard.' };
  }

  // Déballe les enveloppes courantes puis prend le 1er élément d'un tableau.
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

// ── Recherche manuelle (exam_results) ────────────────────────────────────────
async function searchManual(databases, source, rawQuery) {
  try {
    const res = await databases.listDocuments(DATABASE_ID, EXAM_RESULTS_COLLECTION, [
      Query.equal('examType', source.examType || ''),
      Query.equal('tableNumber', rawQuery.trim()),
      ...(source.year ? [Query.equal('year', source.year)] : []),
      Query.limit(1),
    ]);
    if (!res.documents.length) return { found: false };
    const d = res.documents[0];
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

export default async ({ req, res, log, error }) => {
  const reply = (obj, code = 200) => res.json({ ok: true, ...obj }, code);
  const fail = (msg) => res.json({ ok: false, message: msg }, 200);

  let payload;
  try {
    payload = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
  } catch {
    return fail('Requête invalide.');
  }
  const configId = (payload.configId || '').toString().trim();
  const query = (payload.query || '').toString().trim();
  if (!configId || !query) return fail('Paramètres manquants.');

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT)
    .setKey(process.env.APPWRITE_API_KEY || '');
  const databases = new Databases(client);

  let source;
  try {
    source = await databases.getDocument(DATABASE_ID, SOURCES_COLLECTION, configId);
  } catch (e) {
    error && error('config load failed: ' + e.message);
    return fail('Examen introuvable ou non configuré.');
  }

  const type = (source.sourceType || 'manual').toString().toLowerCase();
  try {
    let out;
    if (type === 'pdf') out = await searchPdf(source, query, log);
    else if (type === 'api') out = await searchApi(source, query, log);
    else out = await searchManual(databases, source, query);

    if (out.error) return fail(out.message || 'Recherche indisponible.');
    return reply({ found: !!out.found, result: out.result || null, message: out.message || '' });
  } catch (e) {
    error && error('lookup failed: ' + e.message);
    return fail('Recherche indisponible. Réessaie plus tard.');
  }
};
