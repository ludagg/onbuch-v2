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
//
// Mode `exam_help` : l'app envoie l'URL d'une épreuve (PDF). La fonction la
// télécharge côté serveur (pas de blocage CORS comme dans le navigateur) et en
// extrait le texte (pdf-parse) ; repli sur la vision si une image est jointe.

import pdfParse from 'pdf-parse/lib/pdf-parse.js';

const NVIDIA_ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';

const TRANSCRIBE_PROMPT = `Tu transcris fidèlement le contenu d'une photo d'exercice scolaire en texte.
- Restitue l'énoncé COMPLET : consignes, données, équations (x^2, sqrt(...), <=, >=), et décris brièvement tout schéma/figure.
- Ne résous PAS l'exercice, ne commente pas.
- Si l'image est illisible ou n'est pas un exercice scolaire, réponds exactement : ILLISIBLE`;

const SOLVE_PROMPT = `Tu es le Tuteur IA d'OnBuch (Léo), pour les élèves camerounais (BEPC, Probatoire, Baccalauréat).

ADAPTE-TOI à la demande — c'est la règle la plus importante :
- CORRECTION D'UN EXERCICE complet : donne une correction pédagogique, étape par étape, en français clair, et termine par une ligne commençant par "Réponse :" suivie du résultat final. Inutile de recopier tout l'énoncé : entre dans le vif du sujet.
- QUESTION DE SUIVI ou question simple ("pourquoi cette étape ?", "et si x=2 ?", une définition…) : réponds DIRECTEMENT, brièvement, sans replaquer la structure complète ni réécrire l'énoncé. Va à l'essentiel.
Sois rigoureux, bienveillant et CONCIS. Mieux vaut court et juste que long.

OUTILS DE MISE EN FORME — l'app sait rendre du Markdown enrichi, des maths LaTeX, des courbes et des figures. Utilise-les UNIQUEMENT quand ils aident vraiment la compréhension, JAMAIS par défaut. Si une phrase suffit, n'ajoute ni tableau, ni graphique, ni figure.
- Markdown : titres courts, listes, **gras**, et TABLEAUX seulement si des valeurs s'y prêtent (tableau de variation/signe, comparaison).
- Maths en LaTeX : en ligne avec \\( ... \\) et en bloc avec \\[ ... \\] (\\frac, \\sqrt, \\Delta, \\times, \\le, \\ge, etc.). N'utilise PAS le symbole "$" pour les maths.
- COURBE de fonction (seulement si un tracé éclaire vraiment) : insère un bloc dont le langage est exactement onbuch-plot, contenant un JSON valide :
\`\`\`onbuch-plot
{"title":"f(x)=x^2-5x+6","type":"line","series":[{"label":"f","points":[[-1,12],[0,6],[1,2],[2,0],[3,0],[4,2],[5,6]]}]}
\`\`\`
  Règles : JSON STRICT ; "type" = "line" ou "bar" ; "points" = listes [x, y] de NOMBRES que TU calcules ; 10 à 20 points pour une courbe lisse. À RÉSERVER aux fonctions.
- FIGURE / SCHÉMA (géométrie : triangles, cercles, repères ; circuits ; schémas SVT/physique — seulement si l'énoncé l'exige) : N'UTILISE PAS onbuch-plot. Insère un bloc dont le langage est exactement onbuch-svg, contenant un SVG autonome et valide, par exemple :
\`\`\`onbuch-svg
<svg viewBox="0 0 320 240" xmlns="http://www.w3.org/2000/svg"><polygon points="20,220 300,220 120,40" fill="none" stroke="#1C1714" stroke-width="2"/><text x="8" y="234" font-size="14" fill="#1C1714">A</text></svg>
\`\`\`
  Règles SVG : SVG pur (PAS de script, ni image/police externe, ni CSS externe ; tout en attributs) ; "viewBox" défini ; coordonnées EXACTES et proportionnelles à l'énoncé (longueurs/angles) ; géométrie = traits DROITS (line, polygon), pas de courbes, ferme les polygones ; nomme les sommets/points avec des balises text (A, B, C…), marque les angles droits et cotations utiles ; couleurs : traits #1C1714, accents orange #F59321 et bleu #2D6CDF, fond transparent ; compact et lisible.
  Choisis le bon outil : onbuch-svg pour une FIGURE/SCHÉMA, onbuch-plot pour une COURBE de fonction.`;

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

const QUIZ_PROMPT = `Tu génères un QCM de révision pour un chapitre du programme scolaire camerounais.
Réponds UNIQUEMENT avec un JSON valide, sans aucun texte autour ni balise de code, au format EXACT :
{"questions":[{"q":"énoncé de la question","options":["option A","option B","option C","option D"],"answer":0,"explanation":"courte justification"}]}
Règles :
- Exactement 5 questions, chacune avec 4 options.
- "answer" = index (0 à 3) de la bonne option.
- "explanation" = justification courte et claire.
- Questions variées et pertinentes, niveau secondaire, en français.
- Pas de LaTeX ni de symbole "$" ; écris les maths simplement (x^2, racine de, etc.).`;

// Transcription FIDÈLE de plusieurs pages de cours (pas de résumé à ce stade).
const COURSE_TRANSCRIBE_PROMPT = `Tu transcris fidèlement le contenu de pages de cours scolaire (manuscrit ou imprimé) en texte structuré.
- Restitue TOUT le contenu pédagogique dans l'ordre : titres, définitions, propriétés, formules (écris les maths simplement : x^2, sqrt(...), <=, >=), exemples, et décris brièvement schémas/figures.
- Conserve la structure. Ne résume pas, ne corrige pas, n'ajoute rien.
- Si une page est illisible ou n'est pas un cours, ignore-la. Si AUCUNE page n'est exploitable, réponds exactement : ILLISIBLE`;

// Fiche de révision synthétique à partir d'un contenu de cours.
const SUMMARY_PROMPT = `Tu es le Tuteur IA d'OnBuch. On te donne le contenu d'un cours (programme scolaire camerounais). Rédige une FICHE DE RÉVISION synthétique, claire et mémorisable, en français :
1. Un titre court et une phrase qui situe le chapitre.
2. **L'essentiel à retenir** : les idées-clés en puces courtes.
3. **Définitions** importantes.
4. **Formules / propriétés / méthodes** clés (en LaTeX).
5. Un mini-exemple ou cas typique si utile.
6. **Pièges à éviter** ou moyen mnémotechnique.
7. **À retenir** : 3 à 5 points ultra-condensés.

FORMAT — l'app rend du Markdown enrichi :
- Markdown : titres courts, listes, **gras**, tableaux si utile.
- Maths en LaTeX : en ligne \\( ... \\) et en bloc \\[ ... \\]. N'utilise PAS le symbole "$".
C'est une FICHE, pas un cours complet : va à l'essentiel, sois condensé et structuré.`;

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

// Cache d'un QCM généré (collection quizzes, keyée par chapterId).
async function writeQuiz(chapterId, content) {
  const db = process.env.DATABASE_ID;
  if (!db || !chapterId) return;
  const now = new Date().toISOString();
  let r = await awFetch('POST', `/databases/${db}/collections/quizzes/documents`,
    { documentId: chapterId, data: { chapterId, content, createdAt: now }, permissions: ['read("any")'] });
  if (r.status === 409) {
    await awFetch('PATCH', `/databases/${db}/collections/quizzes/documents/${chapterId}`,
      { data: { content, createdAt: now } });
  }
}

// Envoi d'un push à l'utilisateur (via Appwrite Messaging + provider FCM).
// L'app a enregistré le token FCM comme cible (account.createPushTarget), donc
// on cible par `users: [uid]`. `route` arrive dans data → navigation au tap.
function genId() {
  return ('job' + Date.now().toString(36) + Math.random().toString(36).slice(2, 10)).slice(0, 36);
}
async function sendPush(uid, title, body, route) {
  const payload = { messageId: genId(), title, body, users: [uid] };
  if (route) payload.data = { route };
  const r = await awFetch('POST', '/messaging/messages/push', payload);
  if (!r.ok) {
    const t = await r.text();
    throw new Error(`push ${r.status}: ${t.slice(0, 160)}`);
  }
  return true;
}

async function writeQuota(db, uid, q) {
  const data = { freeUsedToday: q.freeUsedToday, freeResetDate: q.freeResetDate, credits: q.credits };
  // On (re)pose toujours la permission de lecture du propriétaire, même au PATCH :
  // auto-répare les docs créés ailleurs (bot de rachat) sans permission, qui
  // rendaient le solde invisible dans l'app (« 0 crédits »).
  const permissions = [`read("user:${uid}")`];
  let r = await awFetch('POST', `/databases/${db}/collections/${QUOTA_COL}/documents`,
    { documentId: uid, data, permissions });
  if (r.status === 409) {
    r = await awFetch('PATCH', `/databases/${db}/collections/${QUOTA_COL}/documents/${uid}`, { data, permissions });
  }
  return r.ok;
}

// ── Contexte élève (Phase 1 « agent qui connaît l'élève ») ────────────────────
// Lit le profil (`users/{uid}`) + la mémoire longue (`student_memory/{uid}`) et
// renvoie un bloc texte compact pour personnaliser les réponses. Toujours
// tolérant : en cas d'échec, renvoie '' (la correction n'est jamais bloquée).
async function readStudentContext(db, uid) {
  if (!db || !uid) return '';
  try {
    const parts = [];
    // Les deux lectures sont indépendantes → en parallèle (gain de latence).
    const [ru, rm] = await Promise.all([
      awFetch('GET', `/databases/${db}/collections/users/documents/${uid}`),
      awFetch('GET', `/databases/${db}/collections/student_memory/documents/${uid}`),
    ]);
    if (ru.status === 200) {
      const u = await ru.json();
      const bits = [];
      if (u.classe) bits.push(`classe : ${u.classe}`);
      if (u.examen) bits.push(`examen visé : ${u.examen}`);
      if (u.serie) bits.push(`série : ${u.serie}`);
      if (u.studyField) bits.push(`filière souhaitée : ${u.studyField}`);
      if (u.careerGoal) bits.push(`objectif d'orientation : ${u.careerGoal}`);
      if (bits.length) parts.push(bits.join(' · '));
    }
    if (rm.status === 200) {
      const m = await rm.json();
      if (m.weaknesses) parts.push(`points faibles connus : ${String(m.weaknesses).slice(0, 400)}`);
      if (m.strengths) parts.push(`points forts : ${String(m.strengths).slice(0, 400)}`);
      if (m.goals) parts.push(`objectifs de révision : ${String(m.goals).slice(0, 300)}`);
    }
    return parts.join('\n');
  } catch (_) {
    return '';
  }
}

// Greffe le contexte élève sur un prompt système (sans le faire réciter).
function withStudent(basePrompt, ctx) {
  if (!ctx) return basePrompt;
  return `${basePrompt}

CONTEXTE ÉLÈVE (utilise-le pour adapter le NIVEAU, les EXEMPLES et le TON ; ne le récite jamais explicitement) :
${ctx}`;
}

// ── Phase 2 : skills + boucle d'agent (RAG sur le programme OnBuch) ────────────
async function awGetJson(path) {
  try {
    const r = await awFetch('GET', path);
    if (r.status !== 200) return null;
    return await r.json();
  } catch (_) {
    return null;
  }
}
function _norm(s) {
  return (s || '').toString().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
}
// search_courses : retrouve les chapitres OnBuch pertinents (recherche mots-clés).
async function skillSearchCourses(db, query, subject) {
  const cj = await awGetJson(`/databases/${db}/collections/chapters/documents`);
  const sj = await awGetJson(`/databases/${db}/collections/subjects/documents`);
  const subjects = {};
  if (sj && Array.isArray(sj.documents)) for (const d of sj.documents) subjects[d.$id] = d.name || '';
  const chapters = (cj && Array.isArray(cj.documents)) ? cj.documents : [];
  const terms = _norm(query).split(/\s+/).filter((t) => t.length > 2);
  const scored = chapters.map((c) => {
    const hay = _norm(`${c.title} ${c.description || ''} ${subjects[c.subjectId] || ''}`);
    let score = 0;
    for (const t of terms) if (hay.includes(t)) score += 1;
    if (subject && _norm(subjects[c.subjectId] || '').includes(_norm(subject))) score += 0.5;
    return { c, score, subject: subjects[c.subjectId] || '?' };
  }).filter((x) => x.score > 0).sort((a, b) => b.score - a.score).slice(0, 5);
  if (!scored.length) return 'Aucun chapitre OnBuch correspondant.';
  return scored.map((x) => `- chapterId=${x.c.$id} | ${x.subject} › ${x.c.title}`).join('\n');
}
// get_chapter : renvoie le contenu de cours mis en cache (collection lessons).
async function skillGetChapter(db, chapterId) {
  if (!chapterId) return 'chapterId manquant.';
  const j = await awGetJson(`/databases/${db}/collections/lessons/documents/${encodeURIComponent(chapterId)}`);
  if (!j || !j.content) return 'Pas de contenu de cours en cache pour ce chapitre (réponds avec tes connaissances).';
  return String(j.content).slice(0, 3500);
}

const TOOLS_PROMPT = `
OUTILS — tu peux CONSULTER le programme OnBuch (cours camerounais) avant de répondre, UNIQUEMENT si cela ancre vraiment ta réponse dans le cours de l'élève. N'utilise PAS d'outil pour une question triviale ou un simple calcul.
Pour appeler un outil, réponds EXCLUSIVEMENT par ce bloc, SANS aucun texte autour :
\`\`\`onbuch-action
{"tool":"search_courses","args":{"query":"limites de fonctions","subject":"Maths"}}
\`\`\`
Outils :
- search_courses(query, subject?) → chapitres OnBuch pertinents (avec leur chapterId).
- get_chapter(chapterId) → contenu du cours de ce chapitre, pour t'appuyer dessus.
Après un résultat d'outil, soit tu appelles un autre outil, soit tu donnes ta RÉPONSE FINALE (texte normal, JAMAIS de bloc onbuch-action). Quand tu utilises un chapitre, cite-le naturellement (« d'après ton cours « … » »). N'utilise un outil que si c'est vraiment utile — 2 consultations maximum, sinon réponds directement.`;

function parseAction(text) {
  if (!text) return null;
  const m = text.match(/```onbuch-action\s*([\s\S]*?)```/);
  let raw = m ? m[1] : null;
  if (!raw) {
    const t = text.trim();
    if (t.startsWith('{') && t.includes('"tool"')) raw = t;
    else return null;
  }
  try {
    const obj = JSON.parse(raw.trim());
    if (obj && typeof obj.tool === 'string') return obj;
  } catch (_) {}
  return null;
}

// Boucle d'agent : le modèle peut appeler des skills (max 2) avant de répondre.
// Borne volontairement basse pour la latence (chaque tour = un appel modèle).
async function solveWithTools(apiKey, model, messages, db) {
  const convo = [...messages];
  for (let step = 0; step < 2; step++) {
    const out = await callNvidia(apiKey, model, convo, 3200);
    const action = parseAction(out);
    if (!action) return out; // réponse finale
    let result;
    try {
      if (action.tool === 'search_courses') {
        result = await skillSearchCourses(db, (action.args && action.args.query) || '', (action.args && action.args.subject) || '');
      } else if (action.tool === 'get_chapter') {
        result = await skillGetChapter(db, (action.args && action.args.chapterId) || '');
      } else {
        result = 'Outil inconnu.';
      }
    } catch (_) {
      result = 'Erreur lors de la consultation du cours.';
    }
    convo.push({ role: 'assistant', content: out });
    convo.push({ role: 'user', content: `RÉSULTAT OUTIL (${action.tool}) :\n${result}\n\nUtilise ce résultat. Réponds maintenant à l'élève, ou appelle un autre outil si vraiment nécessaire.` });
  }
  // Budget épuisé → forcer une réponse finale, sans outil.
  convo.push({ role: 'user', content: 'Donne maintenant ta réponse finale à l\'élève (texte normal, pas de bloc onbuch-action).' });
  return callNvidia(apiKey, model, convo, 3200);
}

export default async ({ req, res, error }) => {
  const apiKey = process.env.NVIDIA_API_KEY;
  // Modèle Omni multimodal de NVIDIA (texte + image en un seul appel) — défaut
  // unifié pour la vision et le raisonnement. Surchargé par les variables d'env
  // VISION_MODEL / NVIDIA_MODEL si renseignées.
  const visionModel = process.env.VISION_MODEL || 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning';
  const reasoningModel = process.env.NVIDIA_MODEL || 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning';

  let input = {};
  try {
    input = req.bodyJson ?? (req.bodyRaw ? JSON.parse(req.bodyRaw) : {});
  } catch (_) {
    input = {};
  }
  const image = (typeof input.image === 'string' && input.image) ? input.image : null;
  // Plusieurs pages (mode résumé de cours). Borné à 8 pages pour le payload.
  const imageList = (Array.isArray(input.images) ? input.images : (image ? [image] : []))
    .filter((s) => typeof s === 'string' && s)
    .slice(0, 8);
  const question = (input.question || '').toString().trim();
  // URL d'une épreuve (PDF) à lire côté serveur — mode `exam_help`.
  const examUrl = (input.examUrl || '').toString().trim();
  const mode = (input.mode || '').toString();
  const chapterId = (input.chapterId || '').toString() || null;
  const subject = (input.subject || '').toString().trim().slice(0, 40);
  const jobId = (input.jobId || '').toString() || null;
  const uid = req.headers['x-appwrite-user-id'] || null;
  // Si true : prévenir l'utilisateur par push quand le job est prêt (génération
  // en arrière-plan ; il peut quitter l'app).
  const notify = input.notify === true || input.notify === 'true';
  // Activé seulement une fois la génération réellement lancée (pas sur les
  // erreurs précoces type quota dépassé).
  let willNotify = false;
  // Historique de conversation (suivi) : [{role:'user'|'assistant', content}]
  const messages = Array.isArray(input.messages)
    ? input.messages
        .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
        .slice(-12)
        .map((m) => ({ role: m.role, content: m.content.slice(0, 6000) }))
    : null;

  const finish = async (result) => {
    await writeJob(jobId, uid, result, error);
    if (willNotify && uid) {
      try {
        if (result.status === 'done') {
          const body = mode === 'summary'
            ? 'Ta fiche de révision est prête ✅'
            : 'Ta correction est prête ✅';
          await sendPush(uid, 'Léo a terminé', body, jobId ? `/tutor/job/${jobId}` : '/tutor');
        } else if (result.status === 'error') {
          await sendPush(uid, 'Génération interrompue', result.error || 'Réessaie depuis le Tuteur.', '/tutor');
        }
      } catch (e) {
        error(`sendPush: ${String(e)}`);
      }
    }
    return res.json(result);
  };

  if (!apiKey) {
    error('NVIDIA_API_KEY absente.');
    return finish({ status: 'error', error: 'Tuteur IA non configuré côté serveur.' });
  }
  if (!image && !imageList.length && !question && !examUrl && !(messages && messages.length)) {
    return finish({ status: 'error', error: 'Aucun exercice fourni (photo ou texte).' });
  }

  // Vérification du quota (free quotidien + crédits) avant tout appel coûteux.
  const db = process.env.DATABASE_ID;
  const freeDaily = parseInt(process.env.FREE_DAILY || '3', 10);
  let quota = null;
  // Cours, quiz et fiches de révision (lesson/quiz/summary) sont gratuits : pas de quota.
  const isFree = mode === 'lesson' || mode === 'quiz' || mode === 'summary';
  if (db && uid && !isFree) {
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
    if (isFree) return;
    if (quota && db && uid) {
      if (quota.freeUsedToday < freeDaily) quota.freeUsedToday += 1;
      else if (quota.credits > 0) quota.credits -= 1;
      try { await writeQuota(db, uid, quota); } catch (e) { error(`writeQuota: ${String(e)}`); }
    }
  };

  // Le quota est validé : la génération démarre → on préviendra par push.
  if (notify && uid) willNotify = true;

  try {
    // Contexte élève (personnalisation) — uniquement pour les réponses de type
    // correction / explication / suivi (SOLVE_PROMPT), pas pour cours/quiz/fiche.
    const usesSolve = mode !== 'summary' && mode !== 'lesson' && mode !== 'quiz';
    const studentCtx = usesSolve ? await readStudentContext(db, uid) : '';
    // Boucle d'agent (RAG) seulement pour les réponses SOLVE et si la base est
    // accessible. Sinon, comportement direct (inchangé).
    const wantTools = usesSolve && !!db;
    const solveSys = wantTools
      ? `${withStudent(SOLVE_PROMPT, studentCtx)}\n\n${TOOLS_PROMPT}`
      : withStudent(SOLVE_PROMPT, studentCtx);

    // ── Résumé de cours → fiche de révision (multi-pages) ───────────────────
    if (mode === 'summary') {
      let courseText = '';
      if (imageList.length) {
        const content = [{
          type: 'text',
          text: `Transcris fidèlement le contenu de cours de ces ${imageList.length} page(s), dans l'ordre.`,
        }];
        for (const im of imageList) {
          content.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${im}` } });
        }
        courseText = await callNvidia(apiKey, visionModel, [
          { role: 'system', content: COURSE_TRANSCRIBE_PROMPT },
          { role: 'user', content },
        ], 2400);
        if (!courseText || /^illisible/i.test(courseText.trim())) {
          return finish({ status: 'error', error: 'Pages illisibles. Reprends des photos nettes et bien cadrées du cours.' });
        }
      }
      if (question) courseText = courseText ? `${courseText}\n\n${question}` : question;
      if (!courseText.trim()) {
        return finish({ status: 'error', error: 'Aucun contenu de cours fourni.' });
      }
      const fiche = await callNvidia(apiKey, reasoningModel, [
        { role: 'system', content: SUMMARY_PROMPT },
        { role: 'user', content: courseText.slice(0, 24000) },
      ], 3600);
      if (!fiche) {
        return finish({ status: 'error', error: "Le Tuteur n'a pas pu rédiger la fiche. Réessaie." });
      }
      return finish({ status: 'done', correction: fiche, title: subject ? `Fiche : ${subject}` : 'Fiche de révision', subject });
    }

    // Suivi de conversation (texte uniquement, pas de vision).
    if (messages && messages.length) {
      const convo = [{ role: 'system', content: solveSys }, ...messages];
      const reply = wantTools
        ? await solveWithTools(apiKey, reasoningModel, convo, db)
        : await callNvidia(apiKey, reasoningModel, convo, 3200);
      if (!reply) {
        return finish({ status: 'error', error: "Le Tuteur n'a pas pu répondre. Réessaie." });
      }
      await consumeQuota();
      const lastUser = [...messages].reverse().find((m) => m.role === 'user');
      return finish({ status: 'done', correction: reply, title: makeTitle(lastUser ? lastUser.content : 'Question'), subject });
    }

    // Énoncé : texte d'une épreuve PDF (examUrl, lue côté serveur), sinon
    // transcrit depuis la photo, sinon directement le texte saisi.
    let enonce;
    let instruction = '';
    let examText = '';
    // Photo envoyée directement au modèle Omni (lecture + correction en UN seul
    // appel, au lieu de transcrire puis raisonner).
    let imageForSolve = null;
    if (examUrl) {
      try {
        const r = await fetch(examUrl);
        if (r.ok) {
          const buf = Buffer.from(await r.arrayBuffer());
          const parsed = await pdfParse(buf);
          examText = (parsed && parsed.text ? parsed.text : '').replace(/[ \t]+\n/g, '\n').trim();
        } else {
          error(`examUrl HTTP ${r.status}`);
        }
      } catch (e) {
        error(`examUrl fetch/parse: ${String(e)}`);
      }
    }
    if (examText && examText.length >= 200) {
      // Épreuve numérique lisible → on passe TOUT le sujet (toutes pages).
      enonce = examText.slice(0, 20000);
      instruction = question || "Aide-moi sur cette épreuve.";
    } else if (image) {
      // Omni : pas de transcription séparée — l'image part directement au solveur.
      imageForSolve = image;
      enonce = '';
      instruction = question; // question = instruction optionnelle en mode photo
    } else if (examUrl) {
      // PDF non extractible (probablement scanné) et aucune image fournie.
      return finish({ status: 'error', error: "Je n'ai pas réussi à lire le PDF de l'épreuve (sans doute scanné). Recopie ici l'énoncé de l'exercice et je te le corrige étape par étape." });
    } else {
      enonce = question; // mode texte : l'énoncé est le texte saisi
    }

    const isLesson = mode === 'lesson';
    const isQuiz = mode === 'quiz';
    const userMsg = (isLesson || isQuiz)
      ? enonce
      : (instruction ? `${instruction}\n\nÉnoncé :\n${enonce}` : `Voici l'énoncé d'un exercice. Corrige-le.\n\n${enonce}`);

    // Contenu du message élève : image directe (Omni) ou texte.
    const solveUserContent = imageForSolve
        ? [
            {
              type: 'text',
              text: (instruction && instruction.trim())
                  ? `${instruction.trim()}\n\nVoici la photo de l'exercice. Lis-la puis corrige-le étape par étape. Si la photo est illisible, dis-le et demande une photo plus nette.`
                  : "Voici la photo d'un exercice. Lis-la puis corrige-le étape par étape. Si la photo est illisible, dis-le et demande une photo plus nette.",
            },
            { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageForSolve}` } },
          ]
        : userMsg;

    let correction;
    if (isLesson || isQuiz) {
      correction = await callNvidia(apiKey, reasoningModel, [
        { role: 'system', content: isLesson ? LESSON_PROMPT : QUIZ_PROMPT },
        { role: 'user', content: userMsg },
      ], 3200);
    } else {
      const convo = [{ role: 'system', content: solveSys }, { role: 'user', content: solveUserContent }];
      correction = wantTools
        ? await solveWithTools(apiKey, reasoningModel, convo, db)
        : await callNvidia(apiKey, reasoningModel, convo, 3200);
    }

    if (!correction) {
      return finish({ status: 'error', error: "Le Tuteur n'a pas pu rédiger la correction. Réessaie." });
    }

    await consumeQuota();
    if (isLesson && chapterId) {
      try { await writeLesson(chapterId, correction); } catch (e) { error(`writeLesson: ${String(e)}`); }
    }
    if (isQuiz && chapterId) {
      try { await writeQuiz(chapterId, correction); } catch (e) { error(`writeQuiz: ${String(e)}`); }
    }
    return finish({ status: 'done', correction, title: makeTitle(enonce || instruction || subject || 'Correction'), subject });
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
