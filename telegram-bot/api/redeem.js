// OnBuch — /api/redeem : échange un CODE (paiement Mobile Money validé par
// l'admin via le bot) contre des crédits Tuteur.
//
// L'app envoie { code, jwt } où `jwt` est un jeton Appwrite court (Account
// .createJWT()). On VÉRIFIE le jwt auprès d'Appwrite pour obtenir l'UID réel,
// puis on crédite `tutor_quota/{uid}` côté serveur (la collection des codes est
// verrouillée serveur — jamais exposée au client).
//
// Hébergé ici (et non dans une fonction Appwrite) car le projet Appwrite a
// atteint sa limite de fonctions ; ce projet Vercel détient déjà la clé serveur.

const AW = process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1';
const PROJ = process.env.APPWRITE_PROJECT || '6a30463b00001375e229';
const DB = process.env.APPWRITE_DB || '6a3047f8001d11d1b3c1';
const KEY = process.env.APPWRITE_API_KEY;
const COL = 'payment_requests';
const QUOTA = 'tutor_quota';

async function aw(method, path, { body, jwt } = {}) {
  const headers = { 'X-Appwrite-Project': PROJ, 'Content-Type': 'application/json' };
  if (jwt) headers['X-Appwrite-JWT'] = jwt; else headers['X-Appwrite-Key'] = KEY;
  const r = await fetch(`${AW}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const j = await r.json().catch(() => ({}));
  return { ok: r.ok, status: r.status, j };
}
const q = (o) => 'queries%5B%5D=' + encodeURIComponent(JSON.stringify(o));

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(200).json({ ok: false, error: 'POST only' });

  let body = req.body || {};
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch { body = {}; } }
  const code = String(body.code || '').trim().toUpperCase();
  const jwt = String(body.jwt || '').trim();
  if (!code || code.length < 4) return res.status(200).json({ ok: false, error: 'Code invalide.' });
  if (!jwt) return res.status(200).json({ ok: false, error: 'Connecte-toi pour utiliser un code.' });

  // 1) Vérifier le JWT → UID réel.
  const acc = await aw('GET', '/account', { jwt });
  if (!acc.ok || !acc.j.$id) return res.status(200).json({ ok: false, error: 'Session expirée, reconnecte-toi.' });
  const uid = acc.j.$id;

  // 2) Retrouver la demande au code donné (clé serveur).
  const list = await aw('GET', `/databases/${DB}/collections/${COL}/documents?${q({ method: 'equal', attribute: 'code', values: [code] })}&${q({ method: 'limit', values: [1] })}`);
  const doc = (list.j.documents || [])[0];
  if (!doc) return res.status(200).json({ ok: false, error: 'Code introuvable. Vérifie la saisie.' });

  if (doc.status === 'redeemed') return res.status(200).json({ ok: false, error: 'Ce code a déjà été utilisé.' });
  if (doc.status !== 'approved') return res.status(200).json({ ok: false, error: "Ce code n'est pas valide." });
  if (doc.expiresAt && new Date(doc.expiresAt).getTime() < Date.now()) {
    await aw('PATCH', `/databases/${DB}/collections/${COL}/documents/${doc.$id}`, { body: { data: { status: 'expired' } } });
    return res.status(200).json({ ok: false, error: 'Ce code a expiré. Refais une demande sur Telegram.' });
  }
  const credits = Number(doc.credits || 0);
  if (credits <= 0) return res.status(200).json({ ok: false, error: 'Code sans crédits — contacte le support.' });

  // 3) Marquer redeemed AVANT de créditer (anti-rejeu).
  const claim = await aw('PATCH', `/databases/${DB}/collections/${COL}/documents/${doc.$id}`, {
    body: { data: { status: 'redeemed', redeemedByUid: uid, redeemedAt: new Date().toISOString() } },
  });
  if (!claim.ok) return res.status(200).json({ ok: false, error: 'Réessaie dans un instant.' });

  // 4) Créditer tutor_quota/{uid} (même schéma que verify-purchase).
  const cur = await aw('GET', `/databases/${DB}/collections/${QUOTA}/documents/${uid}`);
  let credited;
  if (cur.ok) {
    const total = Number(cur.j.credits || 0) + credits;
    credited = await aw('PATCH', `/databases/${DB}/collections/${QUOTA}/documents/${uid}`, { body: { data: { credits: total } } });
  } else if (cur.status === 404) {
    credited = await aw('POST', `/databases/${DB}/collections/${QUOTA}/documents`, {
      body: { documentId: uid, data: { credits, freeUsedToday: 0, freeResetDate: '' } },
    });
  } else {
    credited = { ok: false };
  }
  if (!credited.ok) {
    // rollback pour ne pas pénaliser l'utilisateur
    await aw('PATCH', `/databases/${DB}/collections/${COL}/documents/${doc.$id}`, { body: { data: { status: 'approved', redeemedByUid: '', redeemedAt: '' } } });
    return res.status(200).json({ ok: false, error: 'Crédit impossible, réessaie.' });
  }
  return res.status(200).json({ ok: true, credits });
}
