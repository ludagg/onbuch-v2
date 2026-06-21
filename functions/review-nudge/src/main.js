// Cron quotidien OnBuch : envoie un push « révisions du jour » aux élèves ayant
// des révisions dues (collection `review_queue`). Lecture avec la clé serveur
// (bypass documentSecurity), un seul push par élève (compte agrégé).

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

export default async ({ res, log, error }) => {
  const db = process.env.DATABASE_ID;
  if (!db) { error('DATABASE_ID manquant.'); return res.json({ ok: false }); }
  const now = new Date();

  // Liste les items de révision (collection petite : limite large + filtrage JS).
  const q = encodeURIComponent(JSON.stringify({ method: 'limit', values: [1000] }));
  let docs = [];
  try {
    const r = await awFetch('GET', `/databases/${db}/collections/review_queue/documents?queries[]=${q}`);
    if (r.ok) { const j = await r.json(); docs = Array.isArray(j.documents) ? j.documents : []; }
    else { error(`list review_queue ${r.status}`); }
  } catch (e) { error(String(e)); }

  // Agrège les révisions DUES par élève.
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
      const ok = await sendPush(
        uid, 'Léo · Révisions du jour',
        `Tu as ${n} révision${n > 1 ? 's' : ''} à faire aujourd'hui 📚`, '/tutor',
      );
      if (ok) sent++;
    } catch (e) { error(`push ${uid}: ${String(e)}`); }
  }
  log(`review-nudge: ${Object.keys(counts).length} élève(s) dus, ${sent} push envoyés.`);
  return res.json({ ok: true, due: Object.keys(counts).length, sent });
};
