// OnBuch — Bot Telegram d'achat de crédits (webhook Vercel).
//
// Flux : /start → choix d'un pack → numéros Orange/MTN → l'utilisateur dépose et
// colle le SMS de confirmation → demande `pending` → l'admin valide (✅/❌ dans le
// groupe admin) → code à usage unique envoyé à l'acheteur → saisi dans l'app
// (fonction `redeem-code`) → crédite `tutor_quota`.
//
// État conversationnel stocké dans Appwrite (`payment_requests`, status=draft)
// car les fonctions serverless sont sans mémoire.
//
// Variables d'environnement (Vercel) — AUCUN secret dans le repo :
//   TELEGRAM_BOT_TOKEN, ADMIN_CHAT_ID, TG_SECRET (secret du webhook),
//   APPWRITE_ENDPOINT, APPWRITE_PROJECT, APPWRITE_DB, APPWRITE_API_KEY.

const BOT = process.env.TELEGRAM_BOT_TOKEN;
const ADMIN_CHAT_ID = process.env.ADMIN_CHAT_ID;
const TG_SECRET = process.env.TG_SECRET || '';
const AW = process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1';
const PROJ = process.env.APPWRITE_PROJECT || '6a30463b00001375e229';
const DB = process.env.APPWRITE_DB || '6a3047f8001d11d1b3c1';
const KEY = process.env.APPWRITE_API_KEY;
const COL = 'payment_requests';

// ── Numéros de dépôt (modifiables via env) ──────────────────────────────────
const MTN = { num: process.env.MTN_NUMBER || '676989643', name: process.env.MTN_NAME || 'NGABANG MARTIN' };
const ORANGE = { num: process.env.ORANGE_NUMBER || '689918156', name: process.env.ORANGE_NAME || 'OBAKER EPSE WANGUE' };

// ── Convertisseur FCFA → crédits (tranches marginales) ──────────────────────
// Reproduit exactement : 100→10, 500→60, 1000→150 ; au-delà, meilleur taux.
function creditsFor(amount) {
  const b = [[0, 100, 0.10], [100, 500, 0.125], [500, 1000, 0.18], [1000, Infinity, 0.18]];
  let c = 0;
  for (const [lo, hi, rate] of b) if (amount > lo) c += (Math.min(amount, hi) - lo) * rate;
  return Math.round(c);
}
const PACKS = [100, 500, 1000, 2000, 5000];

// ── Helpers Telegram ────────────────────────────────────────────────────────
async function tg(method, payload) {
  const r = await fetch(`https://api.telegram.org/bot${BOT}/${method}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload),
  });
  return r.json().catch(() => ({}));
}
const send = (chat_id, text, extra = {}) => tg('sendMessage', { chat_id, text, parse_mode: 'HTML', ...extra });

// ── Helpers Appwrite REST ───────────────────────────────────────────────────
async function aw(method, path, body) {
  const r = await fetch(`${AW}${path}`, {
    method, headers: { 'X-Appwrite-Project': PROJ, 'X-Appwrite-Key': KEY, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const j = await r.json().catch(() => ({}));
  return { ok: r.ok, status: r.status, j };
}
const q = (obj) => 'queries%5B%5D=' + encodeURIComponent(JSON.stringify(obj));
function createReq(data) { return aw('POST', `/databases/${DB}/collections/${COL}/documents`, { documentId: 'unique()', data, permissions: [] }); }
function updateReq(id, data) { return aw('PATCH', `/databases/${DB}/collections/${COL}/documents/${id}`, { data }); }
async function latestForUser(uid) {
  const path = `/databases/${DB}/collections/${COL}/documents?${q({ method: 'equal', attribute: 'telegramUserId', values: [String(uid)] })}&${q({ method: 'orderDesc', attribute: '$createdAt' })}&${q({ method: 'limit', values: [1] })}`;
  const { j } = await aw('GET', path);
  return (j.documents || [])[0] || null;
}
async function reqById(id) {
  const { ok, j } = await aw('GET', `/databases/${DB}/collections/${COL}/documents/${id}`);
  return ok ? j : null;
}

function genCode() {
  const a = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  let s = ''; for (let i = 0; i < 6; i++) s += a[Math.floor(Math.random() * a.length)];
  return 'OB' + s;
}
function parseTxn(text) {
  const id = (text.match(/\b(?:ID|TID|Txn|Trans(?:action)?|R[ée]f(?:[ée]rence)?)[:\s#]*([A-Z0-9.\-]{6,})/i) || [])[1] || '';
  const sender = (text.match(/\b(?:6|2376)\d{7,8}\b/) || [])[0] || '';
  return { id: id.slice(0, 60), sender: sender.slice(0, 30) };
}
const esc = (s) => String(s).replace(/[<&>]/g, (c) => ({ '<': '&lt;', '&': '&amp;', '>': '&gt;' }[c]));

// ── Messages ────────────────────────────────────────────────────────────────
function packKeyboard() {
  return {
    inline_keyboard: [
      ...PACKS.map((a) => [{ text: `${a} FCFA → ${creditsFor(a)} crédits`, callback_data: `pack:${a}` }]),
      [{ text: '✏️ Autre montant', callback_data: 'pack:0' }],
    ],
  };
}
function welcome() {
  return (
    `👋 <b>Bienvenue sur OnBuch Crédits !</b>\n\n` +
    `Recharge tes crédits Tuteur Léo par Mobile Money 📲\n\n` +
    `<b>Comment ça marche :</b>\n` +
    `1️⃣ Choisis un montant ci-dessous\n` +
    `2️⃣ Dépose la somme au numéro indiqué (Orange ou MTN)\n` +
    `3️⃣ Colle ici le <b>SMS de confirmation</b>\n` +
    `4️⃣ Après validation, tu reçois un <b>code</b> à saisir dans l'app ✅\n\n` +
    `Choisis ton montant :`
  );
}
function depositInstructions(amount) {
  const cr = creditsFor(amount);
  return (
    `💰 <b>Montant : ${amount} FCFA</b> → <b>${cr} crédits</b>\n\n` +
    `Dépose <b>${amount} FCFA</b> sur l'un de ces numéros :\n\n` +
    `🟡 <b>MTN MoMo</b>\n<code>${MTN.num}</code> — ${esc(MTN.name)}\n\n` +
    `🟠 <b>Orange Money</b>\n<code>${ORANGE.num}</code> — ${esc(ORANGE.name)}\n\n` +
    `Puis <b>colle ici le SMS de confirmation</b> du dépôt (preuve). ` +
    `Je le transmets pour validation, tu recevras ton code rapidement. ⏳`
  );
}

// ── Handler webhook ─────────────────────────────────────────────────────────
export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(200).send('OnBuch Credits bot');
  if (TG_SECRET && req.headers['x-telegram-bot-api-secret-token'] !== TG_SECRET) {
    return res.status(401).json({ ok: false });
  }
  const u = req.body || {};
  try {
    if (u.callback_query) await onCallback(u.callback_query);
    else if (u.message && u.message.text) await onMessage(u.message);
  } catch (e) {
    console.error('handler error', e);
  }
  return res.status(200).json({ ok: true });
}

async function onMessage(m) {
  const chatId = m.chat.id;
  const from = m.from || {};
  const text = (m.text || '').trim();

  if (/^\/(start|menu|recharger)\b/i.test(text)) {
    return send(chatId, welcome(), { reply_markup: packKeyboard() });
  }
  if (/^\/(aide|help)\b/i.test(text)) {
    return send(chatId, `Tape /start pour recharger.\nQuestion ? Décris ton souci, un admin te répondra.`);
  }

  const draft = await latestForUser(from.id);

  // 1) L'utilisateur a un brouillon (pack choisi) en attente du SMS.
  if (draft && draft.status === 'draft') {
    if (text.replace(/\D/g, '').length < 4) {
      return send(chatId, `Colle le <b>SMS de confirmation</b> complet du dépôt (avec le montant et l'ID de transaction). 📋`);
    }
    const { id, sender } = parseTxn(text);
    await updateReq(draft.$id, {
      status: 'pending', rawMessage: text.slice(0, 1990), txnId: id, senderNumber: sender,
      telegramUsername: from.username || '', telegramChatId: String(chatId),
    });
    await send(chatId, `✅ Bien reçu ! Ta demande de <b>${draft.amount} FCFA → ${draft.credits} crédits</b> est <b>en cours de vérification</b>. ⏳\nTu recevras ton code ici dès validation.`);
    await notifyAdmin({ ...draft, status: 'pending', rawMessage: text, txnId: id, senderNumber: sender, username: from.username });
    return;
  }

  // 2) Montant tapé directement (montant personnalisé) → crée un brouillon.
  const n = parseInt(text.replace(/[ .,]/g, ''), 10);
  if (/^\d[\d .,]*$/.test(text) && n >= 100 && n <= 100000) {
    return startDraft(chatId, from, n);
  }

  // 3) Sinon : aide.
  return send(chatId, `Pour recharger, tape /start et choisis un montant. 👇`, { reply_markup: packKeyboard() });
}

async function startDraft(chatId, from, amount) {
  const credits = creditsFor(amount);
  await createReq({
    telegramUserId: String(from.id), telegramUsername: from.username || '', telegramChatId: String(chatId),
    amount, credits, status: 'draft', createdAt: new Date().toISOString(),
  });
  return send(chatId, depositInstructions(amount));
}

async function onCallback(cb) {
  const data = cb.data || '';
  const msg = cb.message || {};
  const chatId = msg.chat ? msg.chat.id : null;

  // Choix d'un pack par l'acheteur.
  if (data.startsWith('pack:')) {
    await tg('answerCallbackQuery', { callback_query_id: cb.id });
    const amount = parseInt(data.slice(5), 10);
    if (amount === 0) {
      return send(chatId, `✏️ Tape le montant que tu veux recharger (en FCFA), ex. <code>1500</code>.`);
    }
    return startDraft(chatId, cb.from, amount);
  }

  // Décision admin (✅/❌) — UNIQUEMENT depuis le groupe admin.
  if (data.startsWith('ok:') || data.startsWith('no:')) {
    if (String(chatId) !== String(ADMIN_CHAT_ID)) {
      return tg('answerCallbackQuery', { callback_query_id: cb.id, text: 'Non autorisé.' });
    }
    const id = data.slice(3);
    const r = await reqById(id);
    if (!r) return tg('answerCallbackQuery', { callback_query_id: cb.id, text: 'Demande introuvable.' });
    if (r.status !== 'pending') {
      return tg('answerCallbackQuery', { callback_query_id: cb.id, text: `Déjà ${r.status}.` });
    }
    const who = cb.from.username ? '@' + cb.from.username : (cb.from.first_name || 'admin');
    if (data.startsWith('ok:')) {
      const code = genCode();
      const expiresAt = new Date(Date.now() + 24 * 3600 * 1000).toISOString();
      await updateReq(id, { status: 'approved', code, reviewedBy: who, reviewedAt: new Date().toISOString(), expiresAt });
      await send(r.telegramChatId, `🎉 <b>Paiement validé !</b>\n\nTon code : <code>${code}</code>\n\nOuvre l'app OnBuch → <b>Crédits</b> → <b>« J'ai un code »</b>, saisis-le pour recevoir tes <b>${r.credits} crédits</b>.\n⏳ Valable 24 h.`);
      await tg('answerCallbackQuery', { callback_query_id: cb.id, text: 'Approuvé ✅' });
      await editAdmin(msg, `✅ <b>APPROUVÉ</b> par ${esc(who)} — code envoyé (${r.credits} cr).`);
    } else {
      await updateReq(id, { status: 'rejected', reviewedBy: who, reviewedAt: new Date().toISOString() });
      await send(r.telegramChatId, `❌ <b>Paiement non validé.</b>\nVérifie ton dépôt puis renvoie le SMS, ou contacte le support.`);
      await tg('answerCallbackQuery', { callback_query_id: cb.id, text: 'Rejeté ❌' });
      await editAdmin(msg, `❌ <b>REJETÉ</b> par ${esc(who)}.`);
    }
  }
}

function adminText(r) {
  return (
    `🧾 <b>Nouvelle demande de crédits</b>\n\n` +
    `👤 ${r.username ? '@' + esc(r.username) : 'sans @'} (id <code>${esc(r.telegramUserId)}</code>)\n` +
    `💰 <b>${r.amount} FCFA</b> → <b>${r.credits} crédits</b>\n` +
    (r.txnId ? `🔖 Txn : <code>${esc(r.txnId)}</code>\n` : '') +
    (r.senderNumber ? `📱 Émetteur : <code>${esc(r.senderNumber)}</code>\n` : '') +
    `\n<b>SMS collé :</b>\n<i>${esc((r.rawMessage || '').slice(0, 600))}</i>\n\n` +
    `Vérifie la réception réelle puis tranche 👇`
  );
}
async function notifyAdmin(r) {
  if (!ADMIN_CHAT_ID) return;
  await send(ADMIN_CHAT_ID, adminText(r), {
    reply_markup: { inline_keyboard: [[
      { text: '✅ Approuver', callback_data: `ok:${r.$id}` },
      { text: '❌ Rejeter', callback_data: `no:${r.$id}` },
    ]] },
  });
}
async function editAdmin(msg, suffix) {
  const base = (msg.text || '').split('\n').slice(0, 6).join('\n');
  await tg('editMessageText', { chat_id: msg.chat.id, message_id: msg.message_id, parse_mode: 'HTML', text: `${esc(base)}\n\n${suffix}` });
}
