// /api/nv — proxy STREAMING même-origine vers l'API NVIDIA (runtime Edge).
//
// Pourquoi Edge + streaming : l'API NVIDIA bloque le CORS navigateur (appel
// direct impossible). Et les modèles lents (Nemotron Ultra « reasoning »)
// dépassent la durée d'une fonction serverless classique → 504
// FUNCTION_INVOCATION_TIMEOUT. En streaming, on relaie les tokens (SSE) au fur
// et à mesure : la connexion reste vivante tant que ça génère → pas de timeout,
// et l'atelier voit la progression.
//
// Requête : POST JSON { key, model, messages, max_tokens? }
// Réponse : flux SSE brut de NVIDIA (stream:true).

export const config = { runtime: 'edge' };

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default async function handler(req) {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'POST uniquement.' }), {
      status: 405, headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }

  let body;
  try { body = await req.json(); } catch (_) { body = {}; }
  const key = (body && body.key ? String(body.key) : '').trim();
  const model = (body && body.model ? String(body.model) : '').trim();
  const messages = body && Array.isArray(body.messages) ? body.messages : null;
  const maxTokens = Number(body && body.max_tokens) || 4000;
  if (!key || !model || !messages) {
    return new Response(JSON.stringify({ error: 'Paramètres manquants (key, model, messages).' }), {
      status: 400, headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }

  let upstream;
  try {
    upstream = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Accept: 'text/event-stream' },
      body: JSON.stringify({ model, messages, temperature: 0.4, top_p: 0.9, max_tokens: maxTokens, stream: true }),
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Proxy NVIDIA : ' + String(e) }), {
      status: 502, headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }

  if (!upstream.ok || !upstream.body) {
    const t = await upstream.text().catch(() => '');
    return new Response(t || JSON.stringify({ error: 'NVIDIA ' + upstream.status }), {
      status: upstream.status || 502, headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }

  // Relaie le flux SSE tel quel au navigateur.
  return new Response(upstream.body, {
    status: 200,
    headers: { ...CORS, 'Content-Type': 'text/event-stream; charset=utf-8', 'Cache-Control': 'no-cache, no-transform' },
  });
}
