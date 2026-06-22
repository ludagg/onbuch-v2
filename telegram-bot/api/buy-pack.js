// OnBuch — /api/buy-pack : achète un ou plusieurs packs de cours (matières) avec
// les CRÉDITS OnBuch (tutor_quota.credits). Pas de Mobile Money : on dépense les
// crédits déjà au compte de l'élève.
//
// L'app envoie { jwt, subjectIds:[...] }. On vérifie le jwt → UID, on calcule le
// total en crédits (bundle -30 % dès 2 packs premium), on contrôle le solde, on
// débite et on enregistre la propriété (`pack_purchases`).
//
// Hébergé dans le projet Vercel du bot (qui détient déjà la clé serveur), car le
// projet Appwrite a atteint sa limite de fonctions.

const AW = process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1';
const PROJ = process.env.APPWRITE_PROJECT || '6a30463b00001375e229';
const DB = process.env.APPWRITE_DB || '6a3047f8001d11d1b3c1';
const KEY = process.env.APPWRITE_API_KEY;
const SUBJECTS = 'subjects';
const PURCHASES = 'pack_purchases';
const QUOTA = 'tutor_quota';

async function aw(method, path, { body, jwt } = {}) {
  const headers = { 'X-Appwrite-Project': PROJ, 'Content-Type': 'application/json' };
  if (jwt) headers['X-Appwrite-JWT'] = jwt; else headers['X-Appwrite-Key'] = KEY;
  const r = await fetch(`${AW}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const j = await r.json().catch(() => ({}));
  return { ok: r.ok, status: r.status, j };
}
const q = (o) => 'queries%5B%5D=' + encodeURIComponent(JSON.stringify(o));
const cors = (res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
};
const fail = (res, error, extra = {}) => res.status(200).json({ ok: false, error, ...extra });

function totalCredits(prices) {
  const sub = prices.reduce((s, p) => s + p, 0);
  return prices.length >= 2 ? Math.round(sub * 0.7) : sub;
}

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(200).json({ ok: false, error: 'POST only' });

  let body = req.body || {};
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch { body = {}; } }
  const jwt = String(body.jwt || '').trim();
  const ids = Array.isArray(body.subjectIds) ? body.subjectIds.map(String) : [];
  if (!jwt) return fail(res, 'Connecte-toi pour acheter un pack.');
  if (ids.length === 0) return fail(res, 'Aucun pack sélectionné.');

  // 1) JWT → UID.
  const acc = await aw('GET', '/account', { jwt });
  if (!acc.ok || !acc.j.$id) return fail(res, 'Session expirée, reconnecte-toi.');
  const uid = acc.j.$id;

  // 2) Matières premium non déjà possédées.
  const prices = [];
  const toBuy = [];
  for (const id of ids) {
    const s = await aw('GET', `/databases/${DB}/collections/${SUBJECTS}/documents/${id}`);
    if (!s.ok) continue;
    const premium = s.j.premium === true;
    const price = Number(s.j.priceCredits || 0);
    if (!premium || price <= 0) continue;
    const owned = await aw('GET', `/databases/${DB}/collections/${PURCHASES}/documents?${q({ method: 'equal', attribute: 'uid', values: [uid] })}&${q({ method: 'equal', attribute: 'subjectId', values: [id] })}&${q({ method: 'limit', values: [1] })}`);
    if ((owned.j.documents || []).length > 0) continue;
    prices.push(price);
    toBuy.push({ id, price });
  }
  if (toBuy.length === 0) return fail(res, 'Rien à acheter (déjà acquis ou gratuit).');

  const total = totalCredits(prices);

  // 3) Solde.
  const qd = await aw('GET', `/databases/${DB}/collections/${QUOTA}/documents/${uid}`);
  const balance = qd.ok ? Number(qd.j.credits || 0) : 0;
  if (balance < total) return fail(res, 'Crédits insuffisants.', { need: total, balance });

  // 4) Débiter puis enregistrer la propriété.
  const debit = await aw('PATCH', `/databases/${DB}/collections/${QUOTA}/documents/${uid}`, { body: { data: { credits: balance - total } } });
  if (!debit.ok) return fail(res, 'Débit impossible, réessaie.');

  const owned = [];
  for (const it of toBuy) {
    const r = await aw('POST', `/databases/${DB}/collections/${PURCHASES}/documents`, {
      body: {
        documentId: 'unique()',
        data: { uid, subjectId: it.id, priceCredits: it.price, createdAt: new Date().toISOString() },
        permissions: [`read("user:${uid}")`],
      },
    });
    if (r.ok) owned.push(it.id);
  }

  return res.status(200).json({ ok: true, spent: total, newBalance: balance - total, owned });
}
