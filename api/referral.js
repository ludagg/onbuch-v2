// /api/referral — fonction serverless Vercel (parrainage OnBuch).
//
// Récompense en crédits OnBuch (collection `tutor_quota`). Identité du filleul
// vérifiée par son JWT Appwrite (non falsifiable). Écrit la collection
// `referrals` (1 doc par filleul → un seul parrainage possible).
//
// Règles : parrain +REFERRER, filleul +REFEREE. Le filleul est crédité tout de
// suite (claim) ; le parrain seulement quand le filleul atteint le palier XP
// (settle) — anti-faux-comptes.
//
// Actions (POST JSON { action, jwt, ... }) :
//   - "code"   { jwt }          → renvoie/crée mon code de parrainage
//   - "claim"  { jwt, code }    → le filleul saisit le code de son parrain
//   - "settle" { jwt }          → crédite le parrain si le filleul a le palier
//   - "stats"  { jwt }          → mes stats de parrain (filleuls, crédits gagnés)
//
// Variables d'env requises : APPWRITE_API_KEY (clé serveur, databases.read/write).

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1';
const PROJECT = process.env.APPWRITE_PROJECT || '6a30463b00001375e229';
const DB = process.env.DATABASE_ID || '6a3047f8001d11d1b3c1';
const KEY = process.env.APPWRITE_API_KEY || '';

const REFERRER_CREDITS = parseInt(process.env.REFERRAL_REFERRER_CREDITS || '10', 10);
const REFEREE_CREDITS = parseInt(process.env.REFERRAL_REFEREE_CREDITS || '5', 10);
const MILESTONE_XP = parseInt(process.env.REFERRAL_MILESTONE_XP || '100', 10); // niveau 2

const DBASE = `${ENDPOINT}/databases/${DB}`;
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // sans I,O,0,1,L (ambigus)

function srvHeaders() {
  return { 'X-Appwrite-Project': PROJECT, 'X-Appwrite-Key': KEY, 'Content-Type': 'application/json' };
}

async function awFetch(url, opts) {
  const r = await fetch(url, opts);
  const text = await r.text();
  let body = null;
  try { body = text ? JSON.parse(text) : null; } catch { body = { raw: text }; }
  return { ok: r.ok, status: r.status, body };
}

// Identité de l'appelant via son JWT (renvoie l'uid, ou null si invalide).
async function uidFromJwt(jwt) {
  if (!jwt) return null;
  const r = await awFetch(`${ENDPOINT}/account`, {
    headers: { 'X-Appwrite-Project': PROJECT, 'X-Appwrite-JWT': jwt },
  });
  return r.ok && r.body && r.body.$id ? r.body.$id : null;
}

const getDoc = (col, id) => awFetch(`${DBASE}/collections/${col}/documents/${id}`, { headers: srvHeaders() });
const patchDoc = (col, id, data) =>
  awFetch(`${DBASE}/collections/${col}/documents/${id}`, { method: 'PATCH', headers: srvHeaders(), body: JSON.stringify({ data }) });
const createDoc = (col, id, data, permissions) =>
  awFetch(`${DBASE}/collections/${col}/documents`, {
    method: 'POST', headers: srvHeaders(),
    body: JSON.stringify({ documentId: id, data, ...(permissions ? { permissions } : {}) }),
  });

async function listDocs(col, queries) {
  const qs = (queries || []).map((q) => `queries[]=${encodeURIComponent(JSON.stringify(q))}`).join('&');
  return awFetch(`${DBASE}/collections/${col}/documents${qs ? '?' + qs : ''}`, { headers: srvHeaders() });
}

// Crédite (ou crée) le solde tutor_quota d'un utilisateur.
async function addCredits(uid, amount) {
  const cur = await getDoc('tutor_quota', uid);
  if (cur.ok) {
    const credits = (cur.body.credits || 0) + amount;
    await patchDoc('tutor_quota', uid, { credits });
    return credits;
  }
  const today = new Date().toISOString().slice(0, 10);
  await createDoc('tutor_quota', uid, { credits: amount, freeUsedToday: 0, freeResetDate: today }, [
    `read("user:${uid}")`,
  ]);
  return amount;
}

function genCode() {
  let c = 'OB';
  for (let i = 0; i < 4; i++) c += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  return c;
}

// Génère (et persiste) un code unique pour l'utilisateur s'il n'en a pas.
async function ensureCode(uid, userDoc) {
  if (userDoc && userDoc.referralCode) return userDoc.referralCode;
  for (let attempt = 0; attempt < 8; attempt++) {
    const code = genCode();
    const existing = await listDocs('users', [{ method: 'equal', attribute: 'referralCode', values: [code] }, { method: 'limit', values: [1] }]);
    if (existing.ok && existing.body.total === 0) {
      await patchDoc('users', uid, { referralCode: code });
      return code;
    }
  }
  return null;
}

function send(res, status, obj) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(obj));
}

module.exports = async (req, res) => {
  // CORS (l'app web appelle en cross-origin ; le mobile s'en moque).
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return send(res, 200, { ok: true });
  if (req.method !== 'POST') return send(res, 405, { ok: false, error: 'POST only' });
  if (!KEY) return send(res, 500, { ok: false, error: 'server not configured' });

  let payload = req.body;
  if (typeof payload === 'string') { try { payload = JSON.parse(payload); } catch { payload = {}; } }
  if (!payload || typeof payload !== 'object') payload = {};
  const { action, jwt, code } = payload;

  const uid = await uidFromJwt(jwt);
  if (!uid) return send(res, 401, { ok: false, error: 'Connecte-toi pour utiliser le parrainage.' });

  try {
    if (action === 'code') {
      const me = await getDoc('users', uid);
      const myCode = await ensureCode(uid, me.ok ? me.body : null);
      return send(res, 200, { ok: true, code: myCode });
    }

    if (action === 'stats') {
      const me = await getDoc('users', uid);
      const myCode = await ensureCode(uid, me.ok ? me.body : null);
      const list = await listDocs('referrals', [
        { method: 'equal', attribute: 'referrerUid', values: [uid] },
        { method: 'limit', values: [100] },
      ]);
      const docs = (list.ok && list.body.documents) || [];
      const rewarded = docs.filter((d) => d.status === 'rewarded');
      const creditsEarned = rewarded.reduce((s, d) => s + (d.referrerBonus || 0), 0);
      return send(res, 200, {
        ok: true, code: myCode, total: docs.length, rewarded: rewarded.length,
        pending: docs.length - rewarded.length, creditsEarned,
      });
    }

    if (action === 'claim') {
      const c = String(code || '').trim().toUpperCase();
      if (!c) return send(res, 400, { ok: false, error: 'Entre un code de parrainage.' });

      // Déjà parrainé ? (1 doc par filleul, documentId = refereeUid)
      const existing = await getDoc('referrals', uid);
      if (existing.ok) return send(res, 409, { ok: false, error: 'Tu as déjà utilisé un code de parrainage.' });

      // Trouver le parrain par son code.
      const found = await listDocs('users', [
        { method: 'equal', attribute: 'referralCode', values: [c] },
        { method: 'limit', values: [1] },
      ]);
      const parrain = (found.ok && found.body.documents && found.body.documents[0]) || null;
      if (!parrain) return send(res, 404, { ok: false, error: 'Code de parrainage introuvable.' });
      if (parrain.$id === uid) return send(res, 400, { ok: false, error: 'Tu ne peux pas utiliser ton propre code.' });

      const now = new Date().toISOString();
      const created = await createDoc('referrals', uid, {
        referrerUid: parrain.$id, refereeUid: uid, code: c, status: 'pending',
        refereeBonus: REFEREE_CREDITS, referrerBonus: REFERRER_CREDITS, createdAt: now, rewardedAt: '',
      }, [`read("user:${parrain.$id}")`, `read("user:${uid}")`]);
      if (!created.ok) {
        // Course (déjà créé entre-temps) → considérer comme déjà parrainé.
        if (created.status === 409) return send(res, 409, { ok: false, error: 'Tu as déjà utilisé un code de parrainage.' });
        return send(res, 500, { ok: false, error: 'Parrainage impossible. Réessaie.' });
      }
      await patchDoc('users', uid, { referredBy: parrain.$id });
      const balance = await addCredits(uid, REFEREE_CREDITS);
      return send(res, 200, { ok: true, refereeBonus: REFEREE_CREDITS, balance });
    }

    if (action === 'settle') {
      const ref = await getDoc('referrals', uid);
      if (!ref.ok) return send(res, 200, { ok: true, settled: false });
      if (ref.body.status === 'rewarded') return send(res, 200, { ok: true, settled: true, already: true });

      // Vérifie le palier du filleul côté serveur (xp réel).
      const game = await getDoc('gamification', uid);
      const xp = (game.ok && game.body.xp) || 0;
      if (xp < MILESTONE_XP) return send(res, 200, { ok: true, settled: false, pending: true, xp, milestone: MILESTONE_XP });

      const bonus = ref.body.referrerBonus || REFERRER_CREDITS;
      await addCredits(ref.body.referrerUid, bonus);
      await patchDoc('referrals', uid, { status: 'rewarded', rewardedAt: new Date().toISOString() });
      return send(res, 200, { ok: true, settled: true, referrerBonus: bonus });
    }

    return send(res, 400, { ok: false, error: 'Action inconnue.' });
  } catch (e) {
    return send(res, 500, { ok: false, error: 'Erreur serveur. Réessaie.' });
  }
};
