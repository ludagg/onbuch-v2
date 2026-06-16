// Tuteur IA — proxy serveur vers l'API vision NVIDIA (compatible OpenAI).
//
// La clé NVIDIA vit ici, en variable d'environnement de la fonction
// (NVIDIA_API_KEY). Elle n'est jamais envoyée à l'app : le client transmet
// seulement l'image (base64) et reçoit la correction.

const NVIDIA_ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';

const SYSTEM_PROMPT = `Tu es le Tuteur IA d'OnBuch, une application éducative pour les élèves camerounais (système francophone : BEPC, Probatoire, Baccalauréat).
À partir de la photo d'un exercice, tu dois :
1. Restituer brièvement l'énoncé tel que tu le lis.
2. Donner une correction pédagogique claire, étape par étape, numérotée (1., 2., 3.).
3. Expliquer le raisonnement simplement et en français.
4. Terminer par une ligne commençant par "Réponse :" suivie du résultat final.

FORMAT (très important, l'app affiche du texte brut) :
- Écris en TEXTE SIMPLE lisible sur mobile.
- N'utilise PAS de LaTeX ni de symboles "$".
- N'utilise PAS de Markdown (#, *, **, _, backticks).
- Écris les maths en notation courante : x^2, sqrt(...), <=, >=, Δ = b^2 - 4ac, etc.
- Sépare les étapes par des sauts de ligne.

Reste rigoureux, bienveillant et concis. Si l'image est illisible ou n'est pas un exercice scolaire, dis-le poliment et demande une meilleure photo.`;

export default async ({ req, res, log, error }) => {
  const apiKey = process.env.NVIDIA_API_KEY;
  const model = process.env.NVIDIA_MODEL || 'meta/llama-4-maverick-17b-128e-instruct';

  if (!apiKey) {
    error('NVIDIA_API_KEY absente des variables de la fonction.');
    return res.json({ error: 'Tuteur IA non configuré côté serveur.' }, 500);
  }

  // Lecture du corps (JSON) de façon tolérante selon la version du runtime.
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

  const userText = question ||
    "Voici la photo d'un exercice. Corrige-le en détaillant chaque étape.";

  const payload = {
    model,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      {
        role: 'user',
        content: [
          { type: 'text', text: userText },
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${image}` } },
        ],
      },
    ],
    temperature: 0.2,
    top_p: 0.7,
    max_tokens: 1024,
    stream: false,
  };

  try {
    const r = await fetch(NVIDIA_ENDPOINT, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!r.ok) {
      const detail = await r.text();
      error(`NVIDIA ${r.status}: ${detail.slice(0, 500)}`);
      const msg = r.status === 429
        ? 'Trop de requêtes. Réessaie dans un instant.'
        : `Erreur du Tuteur (${r.status}).`;
      return res.json({ error: msg }, 502);
    }

    const data = await r.json();
    const content = data?.choices?.[0]?.message?.content?.trim();
    if (!content) {
      return res.json({ error: "Le Tuteur n'a pas pu lire l'exercice. Réessaie avec une photo plus nette." }, 502);
    }
    return res.json({ correction: content });
  } catch (e) {
    error(`Exception: ${String(e)}`);
    return res.json({ error: 'Connexion au Tuteur impossible.' }, 502);
  }
};
