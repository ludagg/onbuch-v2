// Tuteur IA — pipeline hybride côté serveur (proxy NVIDIA).
//
// 1) Un modèle VISION (Llama 4 Maverick) transcrit l'énoncé depuis la photo.
// 2) Un modèle de RAISONNEMENT (DeepSeek V4) résout et rédige la correction.
//
// La clé NVIDIA vit ici (NVIDIA_API_KEY), jamais dans l'app. Le client envoie
// seulement l'image (base64) et reçoit la correction.

const NVIDIA_ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';

const TRANSCRIBE_PROMPT = `Tu transcris fidèlement le contenu d'une photo d'exercice scolaire en texte.
- Restitue l'énoncé COMPLET : consignes, données, équations (en notation simple : x^2, sqrt(...), <=, >=), et décris brièvement tout schéma/figure.
- Ne résous PAS l'exercice, ne commente pas.
- Si l'image est illisible ou n'est pas un exercice scolaire, réponds exactement : ILLISIBLE`;

const SOLVE_PROMPT = `Tu es le Tuteur IA d'OnBuch, pour les élèves camerounais (BEPC, Probatoire, Baccalauréat).
On te donne l'énoncé d'un exercice (transcrit depuis une photo). Tu dois :
1. Rappeler brièvement l'énoncé.
2. Donner une correction pédagogique claire, étape par étape, numérotée (1., 2., 3.).
3. Expliquer le raisonnement simplement, en français.
4. Terminer par une ligne commençant par "Réponse :" suivie du résultat final.

FORMAT (l'app affiche du texte brut) :
- TEXTE SIMPLE lisible sur mobile.
- PAS de LaTeX ni de symbole "$". PAS de Markdown (#, *, **, _, backticks).
- Maths en notation courante : x^2, sqrt(...), Δ = b^2 - 4ac, etc.
- Sépare les étapes par des sauts de ligne.
Reste rigoureux, bienveillant et concis.`;

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
  if (!r.ok) {
    throw new NvError(r.status);
  }
  const data = await r.json();
  let content = data?.choices?.[0]?.message?.content || '';
  // Retire d'éventuels blocs de raisonnement <think>…</think>.
  content = content.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
  return content;
}

export default async ({ req, res, log, error }) => {
  const apiKey = process.env.NVIDIA_API_KEY;
  const visionModel = process.env.VISION_MODEL || 'meta/llama-4-maverick-17b-128e-instruct';
  const reasoningModel = process.env.NVIDIA_MODEL || 'deepseek-ai/deepseek-v4-pro';

  if (!apiKey) {
    error('NVIDIA_API_KEY absente des variables de la fonction.');
    return res.json({ error: 'Tuteur IA non configuré côté serveur.' }, 500);
  }

  let input = {};
  try {
    input = req.bodyJson ?? (req.bodyRaw ? JSON.parse(req.bodyRaw) : {});
  } catch (_) {
    input = {};
  }
  const image = input.image;
  const question = (input.question || '').toString().trim();
  if (!image || typeof image !== 'string') {
    return res.json({ error: 'Image manquante.' }, 400);
  }

  try {
    // 1) Transcription de l'énoncé depuis la photo (modèle vision).
    const transcript = await callNvidia(apiKey, visionModel, [
      { role: 'system', content: TRANSCRIBE_PROMPT },
      {
        role: 'user',
        content: [
          { type: 'text', text: "Transcris fidèlement l'exercice de cette image." },
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${image}` } },
        ],
      },
    ], 800);

    if (!transcript || /^illisible/i.test(transcript.trim())) {
      return res.json({
        error: "Photo illisible. Reprends une photo nette et bien cadrée de l'exercice.",
      });
    }

    // 2) Correction par le modèle de raisonnement (DeepSeek).
    const userMsg = question
      ? `${question}\n\nÉnoncé (transcrit depuis une photo) :\n${transcript}`
      : `Voici l'énoncé d'un exercice, transcrit depuis une photo. Corrige-le.\n\n${transcript}`;

    const correction = await callNvidia(apiKey, reasoningModel, [
      { role: 'system', content: SOLVE_PROMPT },
      { role: 'user', content: userMsg },
    ], 1200);

    if (!correction) {
      return res.json({ error: "Le Tuteur n'a pas pu rédiger la correction. Réessaie." }, 502);
    }
    return res.json({ correction });
  } catch (e) {
    if (e instanceof NvError) {
      error(`NVIDIA ${e.status}`);
      const msg = e.status === 429
        ? 'Trop de requêtes. Réessaie dans un instant.'
        : `Erreur du Tuteur (${e.status}).`;
      return res.json({ error: msg }, 502);
    }
    error(`Exception: ${String(e)}`);
    return res.json({ error: 'Connexion au Tuteur impossible.' }, 502);
  }
};
