// /api/nv — proxy même-origine vers l'API NVIDIA (zéro-config /api Vercel).
//
// Pourquoi : l'API NVIDIA (integrate.api.nvidia.com) ne renvoie pas d'en-tête
// CORS → un navigateur ne peut PAS l'appeler directement (« Failed to fetch »).
// L'Atelier Exercices appelle donc ce proxy, qui est sur le MÊME domaine que
// l'admin (pas de CORS pour le navigateur) et relaie côté serveur vers NVIDIA
// (pas de CORS serveur→serveur).
//
// On relaie UNE seule complétion par appel (une fiche) → court, pas de timeout
// de gros batch. La clé NVIDIA est fournie par l'admin (jamais stockée ici).
//
// Requête : POST JSON { key, model, messages, max_tokens? }
// Réponse : la réponse JSON brute de NVIDIA (même status).

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(204).end(); return; }
  if (req.method !== 'POST') { res.status(405).json({ error: 'POST uniquement.' }); return; }

  let body = {};
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
  } catch (_) { body = {}; }

  const key = (body.key || '').toString().trim();
  const model = (body.model || '').toString().trim();
  const messages = Array.isArray(body.messages) ? body.messages : null;
  const maxTokens = Number(body.max_tokens) || 4000;
  if (!key || !model || !messages) {
    res.status(400).json({ error: 'Paramètres manquants (key, model, messages).' });
    return;
  }

  try {
    const r = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ model, messages, temperature: 0.4, top_p: 0.9, max_tokens: maxTokens }),
    });
    const text = await r.text();
    res.status(r.status);
    res.setHeader('Content-Type', 'application/json');
    res.send(text);
  } catch (e) {
    res.status(502).json({ error: 'Proxy NVIDIA : ' + String(e) });
  }
};

// Une fiche par appel → 60 s suffisent largement (max plan Hobby).
module.exports.config = { maxDuration: 60 };
