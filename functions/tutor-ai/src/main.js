// Tuteur IA — pipeline hybride côté serveur (proxy NVIDIA), résultat écrit
// dans la collection Appwrite `tutor_jobs` (l'app interroge ce document).
//
// 1) Un modèle VISION (Llama 4 Maverick) transcrit l'énoncé depuis la photo.
// 2) Un modèle de RAISONNEMENT (DeepSeek V4) résout et rédige la correction
//    (Markdown + LaTeX + éventuels blocs `onbuch-plot`).
//
// La fonction est appelée en ASYNCHRONE (les corrections prennent 20-30 s, au
// delà de la limite des exécutions synchrones d'Appwrite). Elle écrit le
// résultat dans `tutor_jobs/{jobId}` ; l'app interroge ce document.

const NVIDIA_ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';

const TRANSCRIBE_PROMPT = `Tu transcris fidèlement le contenu d'une photo d'exercice scolaire en texte.
- Restitue l'énoncé COMPLET : consignes, données, équations (x^2, sqrt(...), <=, >=), et décris brièvement tout schéma/figure.
- Ne résous PAS l'exercice, ne commente pas.
- Si l'image est illisible ou n'est pas un exercice scolaire, réponds exactement : ILLISIBLE`;

const SOLVE_PROMPT = `Tu es le Tuteur IA d'OnBuch, pour les élèves camerounais (BEPC, Probatoire, Baccalauréat).
On te donne l'énoncé d'un exercice (transcrit depuis une photo). Tu dois :
1. Rappeler brièvement l'énoncé.
2. Donner une correction pédagogique claire, étape par étape, numérotée.
3. Expliquer le raisonnement simplement, en français.
4. Terminer par une ligne commençant par "Réponse :" suivie du résultat final.

FORMAT — l'app rend du Markdown enrichi. Utilise au mieux :
- Markdown : titres courts, listes, **gras**, et TABLEAUX Markdown quand c'est utile (valeurs, variation, signe).
- Maths en LaTeX : en ligne avec \\( ... \\) et en bloc avec \\[ ... \\] (\\frac, \\sqrt, \\Delta, \\times, \\le, \\ge, etc.). N'utilise PAS le symbole "$" pour les maths.
- GRAPHIQUES / COURBES : quand un tracé aide, insère un bloc de code dont le langage est exactement onbuch-plot, contenant un JSON valide :
\`\`\`onbuch-plot
{"title":"f(x)=x^2-5x+6","type":"line","series":[{"label":"f","points":[[-1,12],[0,6],[1,2],[2,0],[3,0],[4,2],[5,6]]}]}
\`\`\`
  Règles : JSON STRICT ; "type" = "line" ou "bar" ; "points" = listes [x, y] de NOMBRES que TU calcules ; 10 à 20 points pour une courbe lisse ; uniquement si pertinent.

Reste rigoureux, bienveillant et concis.`;

const LESSON_PROMPT = `Tu es le Tuteur IA d'OnBuch. On te donne un chapitre du programme scolaire camerounais (système francophone). Rédige un COURS clair, structuré et pédagogique en français :
1. Une courte introduction (à quoi sert ce chapitre).
2. Les définitions et notions clés.
3. Les propriétés / formules / méthodes importantes.
4. Un ou deux exemples concrets.
5. Une synthèse « à retenir ».

FORMAT — l'app rend du Markdown enrichi :
- Markdown : titres courts, listes, **gras**, tableaux si utile.
- Maths en LaTeX : en ligne \\( ... \\) et en bloc \\[ ... \\]. N'utilise PAS le symbole "$".
Reste rigoureux, clair et adapté à un élève du secondaire.`;

class NvError extends Error {
  constructor(status) {
    super(`nvidia_${status}`);
    this.status = status;
  }
}

async function callNvidia(apiKey, model, messages, maxTokens) {
  const r = await fetch(NVIDIA_ENDPOINT, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.2,
      top_p: 0.7,
      max_tokens: maxTokens,
      stream: false,
    }),
  });
  if (!r.ok) throw new NvError(r.status);
  const data = await r.json();
  let content = data?.choices?.[0]?.message?.content || '';
  content = content.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
  return content;
}

// Construit un titre court à partir de l'énoncé (première ligne non vide).
function makeTitle(s) {
  const line = (s || '')
    .split('\n')
    .map((x) => x.trim())
    .find((x) => x.length > 0) || 'Exercice';
  return line.length > 120 ? `${line.slice(0, 117)}…` : line;
}

// Écrit le résultat dans tutor_jobs/{jobId}, lisible par l'utilisateur.
async function writeJob(jobId, uid, result, error) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const project = process.env.APPWRITE_PROJECT;
  const key = process.env.APPWRITE_API_KEY;
  const db = process.env.DATABASE_ID;
  const col = process.env.JOBS_COLLECTION || 'tutor_jobs';
  if (!endpoint || !project || !key || !db || !jobId) return;

  const data = { status: result.status, createdAt: new Date().toISOString() };
  if (result.correction) data.correction = result.correction;
  if (result.error) data.error = result.error;
  if (result.title) data.title = result.title;
  if (result.subject) data.subject = result.subject;

  const r = await fetch(`${endpoint}/databases/${db}/collections/${col}/documents`, {
    method: 'POST',
    headers: { 'X-Appwrite-Project': project, 'X-Appwrite-Key': key, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      documentId: jobId,
      data,
      permissions: uid ? [`read("user:${uid}")`] : [],
    }),
  });
  if (!r.ok) {
    const t = await r.text();
    error(`writeJob ${r.status}: ${t.slice(0, 200)}`);
  }
}

// ── Quota : free quotidien + crédits, stockés dans tutor_quota/{uid} ──────────
const QUOTA_COL = 'tutor_quota';
function todayStr() {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
}
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
async function readQuota(db, uid) {
  const r = await awFetch('GET', `/databases/${db}/collections/${QUOTA_COL}/documents/${uid}`);
  if (r.status === 200) {
    const d = await r.json();
    return { freeUsedToday: d.freeUsedToday || 0, freeResetDate: d.freeResetDate || '', credits: d.credits || 0 };
  }
  return { freeUsedToday: 0, freeResetDate: '', credits: 0 };
}
// Cache d'une fiche de cours générée (collection lessons, keyée par chapterId).
async function writeLesson(chapterId, content) {
  const db = process.env.DATABASE_ID;
  if (!db || !chapterId) return;
  const now = new Date().toISOString();
  let r = await awFetch('POST', `/databases/${db}/collections/lessons/documents`,
    { documentId: chapterId, data: { chapterId, content, createdAt: now }, permissions: ['read("any")'] });
  if (r.status === 409) {
    await awFetch('PATCH', `/databases/${db}/collections/lessons/documents/${chapterId}`,
      { data: { content, createdAt: now } });
  }
}

async function writeQuota(db, uid, q) {
  const data = { freeUsedToday: q.freeUsedToday, freeResetDate: q.freeResetDate, credits: q.credits };
  let r = await awFetch('POST', `/databases/${db}/collections/${QUOTA_COL}/documents`,
    { documentId: uid, data, permissions: [`read("user:${uid}")`] });
  if (r.status === 409) {
    r = await awFetch('PATCH', `/databases/${db}/collections/${QUOTA_COL}/documents/${uid}`, { data });
  }
  return r.ok;
}

export default async ({ req, res, error }) => {
  const apiKey = process.env.NVIDIA_API_KEY;
  const visionModel = process.env.VISION_MODEL || 'meta/llama-4-maverick-17b-128e-instruct';
  const reasoningModel = process.env.NVIDIA_MODEL || 'deepseek-ai/deepseek-v4-pro';

  let input = {};
  try {
    input = req.bodyJson ?? (req.bodyRaw ? JSON.parse(req.bodyRaw) : {});
  } catch (_) {
    input = {};
  }
  const image = (typeof input.image === 'string' && input.image) ? input.image : null;
  const question = (input.question || '').toString().trim();
  const mode = (input.mode || '').toString();
  const chapterId = (input.chapterId || '').toString() || null;
  const subject = (input.subject || '').toString().trim().slice(0, 40);
  const jobId = (input.jobId || '').toString() || null;
  const uid = req.headers['x-appwrite-user-id'] || null;
  // Historique de conversation (suivi) : [{role:'user'|'assistant', content}]
  const messages = Array.isArray(input.messages)
    ? input.messages
        .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
        .slice(-12)
        .map((m) => ({ role: m.role, content: m.content.slice(0, 6000) }))
    : null;

  const finish = async (result) => {
    await writeJob(jobId, uid, result, error);
    return res.json(result);
  };

  if (!apiKey) {
    error('NVIDIA_API_KEY absente.');
    return finish({ status: 'error', error: 'Tuteur IA non configuré côté serveur.' });
  }
  if (!image && !question && !(messages && messages.length)) {
    return finish({ status: 'error', error: 'Aucun exercice fourni (photo ou texte).' });
  }

  // Vérification du quota (free quotidien + crédits) avant tout appel coûteux.
  const db = process.env.DATABASE_ID;
  const freeDaily = parseInt(process.env.FREE_DAILY || '3', 10);
  let quota = null;
  // Les cours (mode lesson) sont gratuits et mutualisés : pas de quota.
  if (db && uid && mode !== 'lesson') {
    quota = await readQuota(db, uid);
    if (quota.freeResetDate !== todayStr()) {
      quota.freeUsedToday = 0;
      quota.freeResetDate = todayStr();
    }
    const hasFree = quota.freeUsedToday < freeDaily;
    const hasCredit = quota.credits > 0;
    if (!hasFree && !hasCredit) {
      return finish({ status: 'error', error: 'Quota du jour atteint. Recharge des crédits pour continuer.', quota: true });
    }
  }

  const consumeQuota = async () => {
    if (mode === 'lesson') return;
    if (quota && db && uid) {
      if (quota.freeUsedToday < freeDaily) quota.freeUsedToday += 1;
      else if (quota.credits > 0) quota.credits -= 1;
      try { await writeQuota(db, uid, quota); } catch (e) { error(`writeQuota: ${String(e)}`); }
    }
  };

  try {
    // Suivi de conversation (texte uniquement, pas de vision).
    if (messages && messages.length) {
      const reply = await callNvidia(apiKey, reasoningModel, [
        { role: 'system', content: SOLVE_PROMPT },
        ...messages,
      ], 3200);
      if (!reply) {
        return finish({ status: 'error', error: "Le Tuteur n'a pas pu répondre. Réessaie." });
      }
      await consumeQuota();
      const lastUser = [...messages].reverse().find((m) => m.role === 'user');
      return finish({ status: 'done', correction: reply, title: makeTitle(lastUser ? lastUser.content : 'Question'), subject });
    }

    // Énoncé : transcrit depuis la photo, ou directement le texte saisi.
    let enonce;
    let instruction = '';
    if (image) {
      enonce = await callNvidia(apiKey, visionModel, [
        { role: 'system', content: TRANSCRIBE_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: "Transcris fidèlement l'exercice de cette image." },
            { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${image}` } },
          ],
        },
      ], 800);
      if (!enonce || /^illisible/i.test(enonce.trim())) {
        return finish({ status: 'error', error: "Photo illisible. Reprends une photo nette et bien cadrée de l'exercice." });
      }
      instruction = question; // question = instruction optionnelle en mode photo
    } else {
      enonce = question; // mode texte : l'énoncé est le texte saisi
    }

    const isLesson = mode === 'lesson';
    const userMsg = isLesson
      ? enonce
      : (instruction ? `${instruction}\n\nÉnoncé :\n${enonce}` : `Voici l'énoncé d'un exercice. Corrige-le.\n\n${enonce}`);

    const correction = await callNvidia(apiKey, reasoningModel, [
      { role: 'system', content: isLesson ? LESSON_PROMPT : SOLVE_PROMPT },
      { role: 'user', content: userMsg },
    ], 3200);

    if (!correction) {
      return finish({ status: 'error', error: "Le Tuteur n'a pas pu rédiger la correction. Réessaie." });
    }

    await consumeQuota();
    if (isLesson && chapterId) {
      try { await writeLesson(chapterId, correction); } catch (e) { error(`writeLesson: ${String(e)}`); }
    }
    return finish({ status: 'done', correction, title: makeTitle(enonce), subject });
  } catch (e) {
    if (e instanceof NvError) {
      error(`NVIDIA ${e.status}`);
      const msg = e.status === 429
        ? 'Trop de requêtes. Réessaie dans un instant.'
        : `Erreur du Tuteur (${e.status}).`;
      return finish({ status: 'error', error: msg });
    }
    error(`Exception: ${String(e)}`);
    return finish({ status: 'error', error: 'Connexion au Tuteur impossible.' });
  }
};
