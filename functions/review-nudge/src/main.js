// Fonction « ops » OnBuch (triple rôle — la formule Appwrite limite le nombre
// de fonctions, on mutualise) :
//   1. CRON quotidien (appel sans body) : push « révisions du jour » aux élèves
//      ayant des révisions dues (collection `review_queue`).
//   2. ADMIN (appel avec body {action,userId}, exécution réservée à team:admins) :
//      gestion des comptes Auth — status / block / unblock / delete.
//   3. ÉVÉNEMENT (création d'un doc `notifications`) : diffuse un push à tous les
//      élèves (broadcast) reprenant titre/message/route de la notification admin.
// La clé serveur est en variable d'environnement ; les actions admin vérifient
// en plus que l'appelant est bien membre de l'équipe `admins`.

async function awFetch(method, path, body) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const project = process.env.APPWRITE_PROJECT;
  const key = process.env.APPWRITE_API_KEY;
  return fetch(`${endpoint}${path}`, {
    method,
    headers: { 'X-Appwrite-Project': project, 'X-Appwrite-Key': key, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
}

function genId() {
  return ('rev' + Date.now().toString(36) + Math.random().toString(36).slice(2, 10)).slice(0, 36);
}

async function sendPush(uid, title, body, route) {
  const payload = { messageId: genId(), title, body, users: [uid] };
  if (route) payload.data = { route };
  const r = await awFetch('POST', '/messaging/messages/push', payload);
  return r.ok;
}

// Citations de secours (utilisées si la collection `daily_quotes` est vide ou
// indisponible) — la fonction marche donc même sans configuration admin.
const FALLBACK_QUOTES = [
  { text: "Chaque petit effort d'aujourd'hui construit le grand résultat de demain. Au travail 💪", author: 'Léo' },
  { text: "L'éducation est l'arme la plus puissante pour changer le monde.", author: 'Nelson Mandela' },
  { text: "Peu importe la lenteur à laquelle tu avances, tant que tu n'abandonnes pas.", author: 'Confucius' },
  { text: "Un exercice qui te résiste est un muscle qui grandit. Ne lâche pas 🔥", author: 'Léo' },
  { text: "Cela semble toujours impossible, jusqu'à ce qu'on le fasse.", author: 'Nelson Mandela' },
  { text: "Réviser 30 minutes par jour bat largement 5 heures la veille de l'examen.", author: 'Léo' },
  { text: "Nous sommes ce que nous faisons de manière répétée. L'excellence est donc une habitude.", author: 'Aristote' },
  { text: "L'eau goutte à goutte finit par creuser le roc. Avance pas à pas.", author: 'Proverbe africain' },
  { text: "Crois en toi autant que Léo croit en toi. Tu es capable ✨", author: 'Léo' },
  { text: "Ta seule limite, c'est celle que tu acceptes. Vise plus haut 🚀", author: 'Léo' },
  { text: "La patience cuit même la pierre. Continue, tes efforts vont payer.", author: 'Proverbe camerounais' },
  { text: "Discipline aujourd'hui, liberté demain. Un chapitre à la fois 📖", author: 'Léo' },
  { text: "Le savoir est une lumière qui ne s'éteint jamais, même la nuit.", author: 'Proverbe africain' },
  { text: "Repose-toi si tu es fatigué, mais n'abandonne jamais. Léo est là pour t'aider 🦁", author: 'Léo' },
];

// Lit les citations actives (triées) ; repli sur la liste intégrée.
async function getDailyQuotes(error) {
  const db = process.env.DATABASE_ID;
  if (!db) return FALLBACK_QUOTES;
  try {
    const ql = encodeURIComponent(JSON.stringify({ method: 'limit', values: [200] }));
    const qa = encodeURIComponent(JSON.stringify({ method: 'equal', attribute: 'active', values: [true] }));
    const qo = encodeURIComponent(JSON.stringify({ method: 'orderAsc', values: ['order'] }));
    const r = await awFetch('GET', `/databases/${db}/collections/daily_quotes/documents?queries[]=${ql}&queries[]=${qa}&queries[]=${qo}`);
    if (r.ok) {
      const j = await r.json();
      const arr = (Array.isArray(j.documents) ? j.documents : [])
        .map((d) => ({ text: (d.text || '').toString(), author: (d.author || '').toString() }))
        .filter((q) => q.text);
      if (arr.length) return arr;
    }
  } catch (e) { if (error) error(`getDailyQuotes: ${String(e)}`); }
  return FALLBACK_QUOTES;
}

// Citation du jour : déterministe (même citation pour tous), tourne chaque jour.
function quoteOfTheDay(quotes) {
  const dayIndex = Math.floor(Date.now() / 86400000);
  const n = quotes.length;
  return quotes[((dayIndex % n) + n) % n];
}

// Diffuse la citation du jour en push à TOUS les élèves (broadcast quotidien).
async function broadcastDailyQuote(log, error) {
  try {
    const quotes = await getDailyQuotes(error);
    if (!quotes.length) return;
    const q = quoteOfTheDay(quotes);
    const title = 'Léo · Citation du jour ✨';
    const body = q.author ? `« ${q.text} » — ${q.author}` : `« ${q.text} »`;
    // Image illustrant le push (Léo en sage). ID composé Appwrite Storage
    // `bucket:fichier` (jpeg/png/bmp). Surchargeable par la variable QUOTE_IMAGE.
    const image = process.env.QUOTE_IMAGE || 'annales_files:daily_quote_leo';
    const ids = await listAllUserIds(error);
    if (!ids.length) { log('citation du jour : aucun élève ciblé.'); return; }
    let sent = 0;
    const chunk = 400;
    for (let i = 0; i < ids.length; i += chunk) {
      const slice = ids.slice(i, i + chunk);
      const payload = { messageId: genId(), title, body, users: slice, data: { route: '/tutor' } };
      if (image) payload.image = image;
      const r = await awFetch('POST', '/messaging/messages/push', payload);
      if (r.ok) sent += slice.length;
      else error(`quote push ${r.status}: ${(await r.text()).slice(0, 160)}`);
    }
    log(`citation du jour « ${q.text.slice(0, 40)}… » : ${ids.length} ciblé(s), ${sent} OK.`);
  } catch (e) { error(`broadcastDailyQuote: ${String(e)}`); }
}

async function isAdmin(callerUid) {
  if (!callerUid) return false;
  const team = process.env.ADMIN_TEAM_ID || 'admins';
  const r = await awFetch('GET', `/users/${encodeURIComponent(callerUid)}/memberships`);
  if (!r.ok) return false;
  const j = await r.json();
  // Appartenance à l'équipe admins (comme le gate du back-office, qui ne
  // distingue pas « confirmé » — les membres créés via clé serveur n'ont pas
  // toujours le flag confirmed).
  return (j.memberships || []).some((m) => m.teamId === team);
}

// ── Rôle 2 : actions d'administration des comptes ─────────────────────────────
async function handleAdmin(req, res, error) {
  const callerUid = req.headers['x-appwrite-user-id'] || null;
  let input = {};
  try { input = req.bodyJson ?? (req.bodyRaw ? JSON.parse(req.bodyRaw) : {}); } catch (_) { input = {}; }
  const action = (input.action || '').toString();
  const userId = (input.userId || '').toString();

  if (!(await isAdmin(callerUid))) {
    return res.json({ ok: false, error: 'Accès refusé (admin requis).' }, 403);
  }
  if (!userId) {
    return res.json({ ok: false, error: 'userId manquant.' }, 400);
  }

  try {
    if (action === 'status') {
      const r = await awFetch('GET', `/users/${encodeURIComponent(userId)}`);
      if (!r.ok) return res.json({ ok: false, error: `Compte introuvable (${r.status}).` }, 404);
      const u = await r.json();
      return res.json({
        ok: true, status: u.status, email: u.email, name: u.name,
        registration: u.registration, accessedAt: u.accessedAt, emailVerification: u.emailVerification,
      });
    }
    if (action === 'block' || action === 'unblock') {
      const status = action === 'unblock';
      const r = await awFetch('PATCH', `/users/${encodeURIComponent(userId)}/status`, { status });
      if (!r.ok) { error(`status ${r.status}`); return res.json({ ok: false, error: `Échec (${r.status}).` }, 500); }
      return res.json({ ok: true, status });
    }
    if (action === 'delete') {
      const r = await awFetch('DELETE', `/users/${encodeURIComponent(userId)}`);
      if (!r.ok && r.status !== 404) { error(`delete ${r.status}`); return res.json({ ok: false, error: `Échec (${r.status}).` }, 500); }
      const db = process.env.DATABASE_ID;
      if (db) { try { await awFetch('DELETE', `/databases/${db}/collections/users/documents/${encodeURIComponent(userId)}`); } catch (_) {} }
      return res.json({ ok: true, deleted: true });
    }
    if (action === 'addCredits') {
      // Crédit manuel par l'admin : ajoute (ou retire si négatif) des crédits au
      // solde Tuteur de l'utilisateur (tutor_quota/{userId}). Le solde ne descend
      // jamais sous 0. La collection est en `read("user:<uid>")` → seule cette
      // fonction (clé serveur) peut y écrire.
      const amount = Math.trunc(Number(input.amount));
      if (!Number.isFinite(amount) || amount === 0) {
        return res.json({ ok: false, error: 'Montant de crédits invalide.' }, 400);
      }
      const db = process.env.DATABASE_ID;
      if (!db) return res.json({ ok: false, error: 'DATABASE_ID manquant.' }, 500);
      // Solde courant (le doc peut ne pas exister encore).
      let current = 0;
      const gr = await awFetch('GET', `/databases/${db}/collections/tutor_quota/documents/${encodeURIComponent(userId)}`);
      if (gr.ok) {
        const d = await gr.json();
        current = Number(d.credits || 0);
      } else if (gr.status !== 404) {
        error(`quota get ${gr.status}`);
        return res.json({ ok: false, error: `Échec lecture du solde (${gr.status}).` }, 500);
      }
      const next = Math.max(0, current + amount);
      // Créer (POST) ou, si déjà présent (409), mettre à jour (PATCH). On
      // (re)pose toujours la permission de lecture du propriétaire : certains
      // docs créés ailleurs (bot de rachat) arrivaient sans permission, rendant
      // le solde invisible dans l'app (→ « 0 crédits »). On l'auto-répare ici.
      const perms = [`read("user:${userId}")`];
      let wr = await awFetch('POST', `/databases/${db}/collections/tutor_quota/documents`,
        { documentId: userId, data: { credits: next, freeUsedToday: 0, freeResetDate: '' }, permissions: perms });
      if (wr.status === 409) {
        wr = await awFetch('PATCH', `/databases/${db}/collections/tutor_quota/documents/${encodeURIComponent(userId)}`,
          { data: { credits: next }, permissions: perms });
      }
      if (!wr.ok) { error(`quota write ${wr.status}`); return res.json({ ok: false, error: `Échec du crédit (${wr.status}).` }, 500); }
      // Notifier l'élève (best-effort) quand on ajoute des crédits.
      if (amount > 0) {
        try {
          await sendPush(userId, 'Crédits ajoutés 🎁',
            `Tu as reçu ${amount} crédit${amount > 1 ? 's' : ''} Tuteur. Nouveau solde : ${next}.`, '/credits');
        } catch (_) {/* push best-effort */}
      }
      return res.json({ ok: true, credits: next, added: amount });
    }
    return res.json({ ok: false, error: 'Action inconnue.' }, 400);
  } catch (e) {
    error(String(e));
    return res.json({ ok: false, error: 'Erreur serveur.' }, 500);
  }
}

// ── Rôle 3 : broadcast push à la création d'une notification admin ────────────
async function listAllUserIds(error) {
  const ids = [];
  let offset = 0;
  for (let page = 0; page < 50; page++) {
    const ql = encodeURIComponent(JSON.stringify({ method: 'limit', values: [100] }));
    const qo = encodeURIComponent(JSON.stringify({ method: 'offset', values: [offset] }));
    const r = await awFetch('GET', `/users?queries[]=${ql}&queries[]=${qo}`);
    if (!r.ok) { error(`list users ${r.status}`); break; }
    const j = await r.json();
    const batch = Array.isArray(j.users) ? j.users : [];
    for (const u of batch) ids.push(u.$id);
    if (batch.length < 100) break;
    offset += 100;
  }
  return ids;
}

async function handleNotificationPush(req, res, log, error) {
  let doc = {};
  try { doc = req.bodyJson ?? (req.bodyRaw ? JSON.parse(req.bodyRaw) : {}); } catch (_) { doc = {}; }
  const title = (doc.title || 'OnBuch').toString().slice(0, 120);
  const body = (doc.body || doc.title || 'Nouvelle notification').toString().slice(0, 1000);
  const route = (doc.route || '').toString();

  const ids = await listAllUserIds(error);
  if (ids.length === 0) { log('notif push: aucun élève ciblé.'); return res.json({ ok: true, users: 0, sent: 0 }); }

  let sent = 0;
  const chunk = 400; // borne la taille de chaque message push
  for (let i = 0; i < ids.length; i += chunk) {
    const slice = ids.slice(i, i + chunk);
    const payload = { messageId: genId(), title, body, users: slice };
    if (route) payload.data = { route };
    const r = await awFetch('POST', '/messaging/messages/push', payload);
    if (r.ok) sent += slice.length;
    else error(`push chunk ${r.status}: ${(await r.text()).slice(0, 200)}`);
  }
  log(`notif push « ${title} » : ${ids.length} élève(s) ciblé(s), ${sent} OK.`);
  return res.json({ ok: true, users: ids.length, sent });
}

// ── Rôle 1 : push « révisions du jour » (cron) ────────────────────────────────
async function handleNudge(res, log, error) {
  const db = process.env.DATABASE_ID;
  if (!db) { error('DATABASE_ID manquant.'); return res.json({ ok: false }); }
  const now = new Date();
  const q = encodeURIComponent(JSON.stringify({ method: 'limit', values: [1000] }));
  let docs = [];
  try {
    const r = await awFetch('GET', `/databases/${db}/collections/review_queue/documents?queries[]=${q}`);
    if (r.ok) { const j = await r.json(); docs = Array.isArray(j.documents) ? j.documents : []; }
    else { error(`list review_queue ${r.status}`); }
  } catch (e) { error(String(e)); }

  const counts = {};
  for (const d of docs) {
    if ((d.status || 'active') !== 'active') continue;
    const due = new Date(d.dueAt || 0);
    if (due <= now && d.userId) counts[d.userId] = (counts[d.userId] || 0) + 1;
  }
  let sent = 0;
  for (const uid of Object.keys(counts)) {
    const n = counts[uid];
    try {
      const ok = await sendPush(uid, 'Léo · Révisions du jour',
        `Tu as ${n} révision${n > 1 ? 's' : ''} à faire aujourd'hui 📚`, '/tutor');
      if (ok) sent++;
    } catch (e) { error(`push ${uid}: ${String(e)}`); }
  }
  log(`review-nudge: ${Object.keys(counts).length} élève(s) dus, ${sent} push envoyés.`);
  return res.json({ ok: true, due: Object.keys(counts).length, sent });
}

export default async ({ req, res, log, error }) => {
  // Déclenchement par ÉVÉNEMENT Appwrite (création d'une notification) → broadcast.
  const event = (req.headers['x-appwrite-event'] || '').toString();
  if (event) return handleNotificationPush(req, res, log, error);

  // Sinon : body avec `action` → administration ; rien → cron « révisions ».
  let hasAction = false;
  try {
    const b = req.bodyJson ?? (req.bodyRaw ? JSON.parse(req.bodyRaw) : {});
    hasAction = !!(b && b.action);
  } catch (_) { hasAction = false; }

  if (hasAction) return handleAdmin(req, res, error);
  // Cron quotidien (06 h UTC ≈ 07 h Cameroun) : citation motivante à TOUS les
  // élèves, puis rappels de révision aux élèves ayant des révisions dues.
  await broadcastDailyQuote(log, error);
  return handleNudge(res, log, error);
};
