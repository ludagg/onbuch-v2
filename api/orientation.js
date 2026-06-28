// /api/orientation — assistant d'orientation « Léo Orientation » (Vercel Edge).
//
// DÉDIÉ à l'orientation, SÉPARÉ du tuteur : pas de tutor_jobs, pas de quota
// photo. Modèle rapide (texte). La clé NVIDIA reste SERVEUR (env NVIDIA_API_KEY).
// Accès réservé aux élèves connectés (JWT Appwrite vérifié).
//
// Requête : POST JSON { jwt, messages:[{role,content}], profile? }
// Réponse : flux texte brut (deltas de tokens) — l'app les concatène.

export const config = { runtime: 'edge' };

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1';
const PROJECT = process.env.APPWRITE_PROJECT || '6a30463b00001375e229';
const NV_KEY = process.env.NVIDIA_API_KEY || '';
const MODEL = process.env.ORIENTATION_MODEL || 'meta/llama-3.1-8b-instruct';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

const SYSTEM = `Tu es Léo, le conseiller d'orientation d'OnBuch, expert du système éducatif CAMEROUNAIS (MINESEC, MINESUP, Office du Bac, GCE Board) et de l'enseignement supérieur au Cameroun et à l'étranger.

Ton rôle : aider l'élève à choisir sa voie — filières post-bac, universités et grandes écoles (UY1, ENS, ENSP/Polytechnique, ENAM, IRIC, FMSB, ENSET, IUT, FASA, écoles privées…), concours, métiers et débouchés, et bourses.

Règles :
- Réponds en français, de façon CONCISE, structurée (puces courtes), concrète et bienveillante, adaptée à un lycéen/bachelier camerounais.
- Appuie-toi sur le profil de l'élève s'il est fourni (classe, série, objectif).
- Donne des pistes réalistes au Cameroun (écoles réelles, concours réels, séries d'accès).
- Si la question n'a rien à voir avec l'orientation, les études ou la carrière, ramène poliment vers l'orientation (tu n'es pas le tuteur des cours).
- N'invente pas de dates de concours précises si tu n'es pas sûr ; conseille de vérifier les sources officielles.`;

function profileLine(p) {
  if (!p || typeof p !== 'object') return '';
  const bits = [];
  if (p.classe) bits.push(`classe : ${p.classe}`);
  if (p.serie) bits.push(`série : ${p.serie}`);
  if (p.examen) bits.push(`examen : ${p.examen}`);
  if (p.careerGoal) bits.push(`objectif de carrière : ${p.careerGoal}`);
  if (p.studyField) bits.push(`domaine visé : ${p.studyField}`);
  if (p.studyDestination) bits.push(`destination d'études : ${p.studyDestination}`);
  return bits.length ? `Profil de l'élève — ${bits.join(' ; ')}.` : '';
}

async function uidFromJwt(jwt) {
  if (!jwt) return null;
  try {
    const r = await fetch(`${ENDPOINT}/account`, {
      headers: { 'X-Appwrite-Project': PROJECT, 'X-Appwrite-JWT': jwt },
    });
    if (!r.ok) return null;
    const b = await r.json();
    return b && b.$id ? b.$id : null;
  } catch (_) {
    return null;
  }
}

function err(status, message) {
  return new Response(JSON.stringify({ error: message }), {
    status, headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

export default async function handler(req) {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method !== 'POST') return err(405, 'POST uniquement.');
  if (!NV_KEY) return err(500, 'Assistant non configuré (clé serveur manquante).');

  let body;
  try { body = await req.json(); } catch (_) { body = {}; }
  const jwt = body && body.jwt ? String(body.jwt) : '';
  const messages = body && Array.isArray(body.messages) ? body.messages : null;
  if (!messages || messages.length === 0) return err(400, 'Aucun message.');

  const uid = await uidFromJwt(jwt);
  if (!uid) return err(401, 'Connecte-toi pour utiliser l\'assistant.');

  // Nettoie + borne l'historique (12 derniers tours) ; rôles autorisés.
  const convo = messages
    .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
    .slice(-12)
    .map((m) => ({ role: m.role, content: m.content.slice(0, 4000) }));

  const sys = [{ role: 'system', content: SYSTEM }];
  const pl = profileLine(body.profile);
  if (pl) sys.push({ role: 'system', content: pl });

  let upstream;
  try {
    upstream = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${NV_KEY}`, 'Content-Type': 'application/json', Accept: 'text/event-stream' },
      body: JSON.stringify({ model: MODEL, messages: [...sys, ...convo], temperature: 0.5, top_p: 0.9, max_tokens: 900, stream: true }),
    });
  } catch (e) {
    return err(502, 'Service IA indisponible. Réessaie.');
  }
  if (!upstream.ok || !upstream.body) {
    return err(502, 'Service IA indisponible (' + upstream.status + ').');
  }

  // Relaie le flux SSE NVIDIA en texte brut (deltas) pour une conso simple côté app.
  const reader = upstream.body.getReader();
  const dec = new TextDecoder();
  const enc = new TextEncoder();
  let buf = '';
  const stream = new ReadableStream({
    async pull(controller) {
      const { done, value } = await reader.read();
      if (done) { controller.close(); return; }
      buf += dec.decode(value, { stream: true });
      let nl;
      while ((nl = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line.startsWith('data:')) continue;
        const d = line.slice(5).trim();
        if (!d || d === '[DONE]') continue;
        try {
          const delta = JSON.parse(d)?.choices?.[0]?.delta?.content || '';
          if (delta) controller.enqueue(enc.encode(delta));
        } catch (_) { /* fragment partiel */ }
      }
    },
    cancel() { try { reader.cancel(); } catch (_) {} },
  });

  return new Response(stream, { headers: { ...CORS, 'Content-Type': 'text/plain; charset=utf-8' } });
}
