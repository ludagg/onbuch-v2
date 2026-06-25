#!/usr/bin/env node
// OnBuch — Générateur de chapitres du fascicule de Physique via l'API NVIDIA.
// Délègue la rédaction lourde aux modèles NVIDIA (économie du budget Claude).
// Claude reste l'orchestrateur : ce script écrit le .tex, compile avec tectonic
// et reboucle sur les erreurs de compilation en renvoyant l'erreur au modèle.
//
// Usage :
//   NVIDIA_API_KEYS="nvapi-...,nvapi-..." node generate.mjs ch07            # un chapitre
//   NVIDIA_API_KEYS="nvapi-..."          node generate.mjs ch07 ch06 ch10   # plusieurs (en parallèle)
//   NVIDIA_API_KEYS="nvapi-..."          node generate.mjs all              # tous
// Variables :
//   NVIDIA_API_KEYS  (obligatoire) une ou plusieurs clés séparées par des virgules
//   NVIDIA_MODEL     (défaut: deepseek-ai/deepseek-r1) modèle du catalogue build.nvidia.com
//   MAX_TOKENS       (défaut: 16384)   plafond de sortie par appel
//   MAX_FIX_ROUNDS   (défaut: 3)       tentatives de correction de compilation
//   CONCURRENCY      (défaut: nb de clés) chapitres générés en parallèle

import { readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const execFileP = promisify(execFile);
const HERE = dirname(fileURLToPath(import.meta.url));
// Appel DIRECT à NVIDIA par défaut (l'environnement atteint integrate.api.nvidia.com).
// Repli possible via le proxy Vercel /api/nv (réponse SSE) avec NVIDIA_PROXY=1.
const DIRECT = process.env.NVIDIA_PROXY !== '1';
const ENDPOINT = process.env.NVIDIA_ENDPOINT ||
  (DIRECT ? 'https://integrate.api.nvidia.com/v1/chat/completions' : 'https://onbuch-v2.vercel.app/api/nv');
// Modèle rapide accessible à ces clés. (deepseek-r1 = id inexistant → 404.)
const MODEL = process.env.NVIDIA_MODEL || 'deepseek-ai/deepseek-v4-flash';
const MAX_TOKENS = Number(process.env.MAX_TOKENS || 32768);
// 0 par défaut : NVIDIA génère, on compile UNE fois et on s'arrête sur erreur.
// Les corrections de compilation sont faites à la main (Claude) — chirurgical,
// sans régénérer (zéro coût NVIDIA, zéro dérive de contenu). Mettre >0 pour
// réactiver la correction auto par le modèle.
const MAX_FIX_ROUNDS = Number(process.env.MAX_FIX_ROUNDS || 0);
const KEYS = (process.env.NVIDIA_API_KEYS || '').split(',').map((s) => s.trim()).filter(Boolean);
const CONCURRENCY = Number(process.env.CONCURRENCY || KEYS.length || 1);

if (!KEYS.length) {
  console.error('❌ NVIDIA_API_KEYS manquante (une ou plusieurs clés séparées par des virgules).');
  process.exit(1);
}

// ── Spécifications des chapitres (titres exacts + consigne de contenu) ──
const CHAPTERS = {
  ch01: { title: 'Forces et champs', spec: 'Notion de champ ; champ de gravitation g ; champ électrostatique E (loi de Coulomb, charge ponctuelle, plusieurs charges, condensateur plan) ; champ magnétique B (aimants, champ terrestre, champ créé par un courant : fil, spire, solénoïde, règle de la main droite) ; lignes de champ, spectres, superposition. Figures TikZ pour vecteurs/lignes de champ, condensateur, solénoïde ; \\imgph pour les spectres réels de limaille de fer.' },
  ch02: { title: 'Les lois de Newton', spec: 'Vecteurs position/vitesse/accélération ; référentiels galiléens, repère de Frenet ; quantité de mouvement ; 1re, 2e, 3e lois de Newton ; bilan des forces ; théorème du centre d\'inertie. Figures TikZ : bilan de forces, plan incliné, repère de Frenet.' },
  ch03: { title: 'Mouvements dans un champ uniforme', spec: 'Projectile dans le champ de pesanteur (équations horaires, trajectoire parabolique, portée, flèche) ; particule chargée dans un champ E uniforme (déviation dans un condensateur, oscilloscope) ; aspects énergétiques. Figures : trajectoire parabolique (pgfplots), déviation d\'une charge entre armatures (TikZ).' },
  ch04: { title: 'Mouvements circulaires uniformes', spec: 'Accélération centripète ; particule chargée dans un champ B uniforme (force de Lorentz, rayon, période, spectrographe de masse, cyclotron) ; satellites et planètes (gravitation, lois de Kepler, satellite géostationnaire, vitesses cosmiques). Figures TikZ : charge en cercle dans B, orbite de satellite.' },
  ch05: { title: 'Généralités sur les systèmes oscillants', spec: 'Phénomènes périodiques ; période, fréquence, pulsation ; grandeur sinusoïdale, amplitude, phase, déphasage ; représentation de Fresnel ; oscillations libres/forcées/amorties ; introduction à la résonance. Figures : signaux sinusoïdaux et déphasage (pgfplots), diagramme de Fresnel (TikZ), oscillations amorties (pgfplots).' },
  ch06: { title: 'Les oscillateurs mécaniques', spec: 'Pendule élastique (masse-ressort horizontal et vertical) ; pendule simple ; pendule de torsion ; équation différentielle x\'\' + w0^2 x = 0, solution, période propre ; énergie mécanique (conservation, amortissement) ; oscillations forcées et résonance. Figures TikZ : masse-ressort, pendule simple, pendule de torsion ; pgfplots : énergie(t), courbe de résonance.' },
  ch07: { title: 'Les oscillateurs électriques', spec: 'Condensateur (charge, capacité, énergie) ; dipôle RC (charge/décharge, constante de temps tau=RC) ; bobine, auto-induction, dipôle RL (tau=L/R) ; oscillations libres du circuit LC puis RLC (équation différentielle, pseudo-période, amortissement) ; oscillations forcées en régime sinusoïdal, résonance d\'intensité ; analogie électromécanique. Schémas circuitikz : circuits RC, RL, LC, RLC série, montage charge/décharge avec interrupteur ; pgfplots : oscillogrammes u(t)/i(t), courbe de résonance d\'intensité.' },
  ch08: { title: 'Les ondes mécaniques', spec: 'Onde progressive (transversale/longitudinale) ; célérité, double périodicité, longueur d\'onde (lambda = vT) ; onde le long d\'une corde et d\'un ressort ; ondes à la surface de l\'eau (cuve à ondes) ; réflexion, réfraction, diffraction ; interférences mécaniques. Figures : onde sur une corde (pgfplots), diffraction par une fente (TikZ), interférences à deux sources (TikZ) ; \\imgph possible pour une cuve à ondes réelle.' },
  ch09: { title: 'La lumière', spec: 'Modèle ondulatoire ; interférences lumineuses (fentes de Young, interfrange, conditions) ; diffraction ; aspect corpusculaire : effet photoélectrique (Einstein, travail d\'extraction, fréquence seuil, h.nu = W0 + Ec), photon, dualité ; spectres (émission/absorption), niveaux d\'énergie de l\'atome, transitions. Figures : schéma des fentes de Young (TikZ), diagramme de niveaux d\'énergie (TikZ) ; \\imgph pour le montage réel de Young, les figures de franges et les spectres de raies.' },
  ch10: { title: 'La radioactivité', spec: 'Noyau, nucléons, isotopes ; stabilité, diagramme (N,Z) ; radioactivité alpha, beta-, beta+, gamma ; lois de conservation (Soddy) ; familles radioactives ; décroissance radioactive (loi N=N0 e^{-lambda t}, constante lambda, demi-vie, activité, datation) ; réactions provoquées : fission, fusion ; énergie de liaison, défaut de masse (E=Delta m c^2). Figures pgfplots : courbe de décroissance, diagramme (N,Z), courbe d\'Aston ; TikZ : familles radioactives.' },
};

const ORDER = ['ch01','ch02','ch03','ch04','ch05','ch06','ch07','ch08','ch09','ch10'];

function stripThink(s) {
  if (!s) return '';
  let out = s.replace(/<think>[\s\S]*?<\/think>/g, '');
  const i = out.indexOf('<think>');
  if (i >= 0) out = out.slice(0, i);
  return out.trim();
}
// Retire d'éventuels fences markdown ```latex ... ```
function stripFences(s) {
  return s.replace(/^```(?:latex|tex)?\s*/i, '').replace(/```\s*$/i, '').trim();
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Lit un flux SSE OpenAI (data: {...}\n\n … data: [DONE]) et concatène le contenu.
// Logue la progression (caractères générés) ~toutes les 2000 car.
async function readSSE(res, label) {
  let buf = '', out = '', lastLog = 0;
  const dec = new TextDecoder();
  for await (const chunk of res.body) {
    buf += dec.decode(chunk, { stream: true });
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, i).trim();
      buf = buf.slice(i + 1);
      if (!line.startsWith('data:')) continue;
      const d = line.slice(5).trim();
      if (d === '[DONE]') continue;
      try { out += JSON.parse(d).choices?.[0]?.delta?.content || ''; } catch { /* keep-alive */ }
    }
    if (out.length - lastLog >= 2000) { lastLog = out.length; console.log(`[${label}]   …${out.length} car.`); }
  }
  return out;
}

// Appel NVIDIA en STREAMING dans les deux modes (progression + pas de timeout).
async function callNvidia(key, messages, label = MODEL.split('/').pop()) {
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const req = DIRECT
        ? { headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Accept: 'text/event-stream' },
            body: JSON.stringify({ model: MODEL, messages, temperature: 0.3, top_p: 0.9, max_tokens: MAX_TOKENS, stream: true }) }
        // Proxy Vercel /api/nv : la clé voyage dans le corps, le proxy force stream:true.
        : { headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ key, model: MODEL, messages, max_tokens: MAX_TOKENS }) };
      const r = await fetch(ENDPOINT, { method: 'POST', ...req });
      if (r.status === 429 || r.status >= 500) { await sleep(2000 * 2 ** attempt); continue; }
      if (!r.ok) throw new Error(`HTTP ${r.status}: ${(await r.text()).slice(0, 300)}`);
      return stripFences(stripThink(await readSSE(r, label)));
    } catch (e) {
      if (attempt === 4) throw e;
      await sleep(2000 * 2 ** attempt);
    }
  }
  throw new Error('NVIDIA: échec après retries');
}

// Compile preamble + ce chapitre seul ; renvoie {ok, log}
async function compileCheck(id, texBody) {
  const work = join(HERE, '.build', id);
  await mkdir(work, { recursive: true });
  await execFileP('cp', [join(HERE, 'preamble.tex'), work]);
  await execFileP('cp', ['-r', join(HERE, 'images'), work]).catch(() => {});
  await writeFile(join(work, 'chap.tex'), texBody);
  await writeFile(join(work, 'main.tex'),
    '\\input{preamble.tex}\n\\begin{document}\\mainmatter\n\\include{chap}\n\\end{document}\n');
  try {
    const { stdout, stderr } = await execFileP('tectonic',
      ['-X', 'compile', '--outdir', '.', '--keep-logs', 'main.tex'],
      { cwd: work, timeout: 300000, maxBuffer: 1 << 24 });
    return { ok: true, log: (stdout || '') + (stderr || '') };
  } catch (e) {
    const log = `${e.stdout || ''}\n${e.stderr || ''}`;
    const errs = log.split('\n').filter((l) => /error:|Error|Undefined|! /.test(l)).slice(0, 25).join('\n');
    return { ok: false, log: errs || log.slice(-1500) };
  }
}

async function generateChapter(id, key) {
  const ch = CHAPTERS[id];
  if (!ch) throw new Error(`Chapitre inconnu: ${id}`);
  const guide = await readFile(join(HERE, 'AGENT_GUIDE.md'), 'utf8');
  const sys = `Tu es un professeur agrégé de physique camerounais et un expert LaTeX. Tu produis du LaTeX pur, compilable avec tectonic/XeLaTeX, conforme au guide fourni. ${guide}`;
  const user = `Rédige le chapitre suivant du fascicule de Physique Terminales C/D/E/TI.\n\nNuméro de chapitre attendu : ${id.replace('ch','')} (commence par \\chapter{${ch.title}}).\nTITRE : ${ch.title}\nCONTENU À COUVRIR : ${ch.spec}\n\nRespecte SCRUPULEUSEMENT la structure imposée (cours → essentiel → méthodes → exercices d'application corrigés → exercices d'entraînement → sujets type Bac → corrigés). Renvoie UNIQUEMENT le LaTeX du chapitre, sans préambule ni \\begin{document}.`;
  let messages = [{ role: 'system', content: sys }, { role: 'user', content: user }];

  console.log(`[${id}] génération (modèle ${MODEL})…`);
  let tex = await callNvidia(key, messages, id);

  for (let round = 0; round <= MAX_FIX_ROUNDS; round++) {
    await writeFile(join(HERE, `${id}.tex`), tex);
    const { ok, log } = await compileCheck(id, tex);
    if (ok) { console.log(`[${id}] ✅ compile (round ${round})`); return { id, ok: true }; }
    console.log(`[${id}] ⚠️ erreur compile (round ${round}) :\n${log.slice(0, 400)}`);
    if (round === MAX_FIX_ROUNDS) { console.log(`[${id}] ❌ abandon après ${MAX_FIX_ROUNDS} corrections`); return { id, ok: false, log }; }
    messages = [
      { role: 'system', content: sys },
      { role: 'user', content: user },
      { role: 'assistant', content: tex },
      { role: 'user', content: `Ce LaTeX NE COMPILE PAS avec tectonic. Erreurs :\n${log}\n\nCorrige le problème et renvoie le chapitre LaTeX COMPLET corrigé (UNIQUEMENT le LaTeX, de \\chapter{...} à la fin). N'ajoute aucun package.` },
    ];
    tex = await callNvidia(key, messages, id);
  }
  return { id, ok: false };
}

// ── Orchestration : pool de concurrence, une clé par worker ──
async function run() {
  let targets = process.argv.slice(2);
  if (!targets.length) { console.error('Usage: node generate.mjs ch07 [ch06 ...] | all'); process.exit(1); }
  if (targets.includes('all')) targets = [...ORDER];
  targets = targets.filter((t) => CHAPTERS[t]);

  const queue = [...targets];
  const results = [];
  async function worker(slot) {
    const key = KEYS[slot % KEYS.length];
    while (queue.length) {
      const id = queue.shift();
      try { results.push(await generateChapter(id, key)); }
      catch (e) { console.error(`[${id}] erreur: ${e.message}`); results.push({ id, ok: false, error: e.message }); }
    }
  }
  await Promise.all(Array.from({ length: Math.min(CONCURRENCY, targets.length) }, (_, i) => worker(i)));
  await rm(join(HERE, '.build'), { recursive: true, force: true }).catch(() => {});

  console.log('\n=== RÉSUMÉ ===');
  for (const r of results) console.log(`${r.ok ? '✅' : '❌'} ${r.id}${r.error ? ' — ' + r.error : ''}`);
  const ko = results.filter((r) => !r.ok);
  process.exit(ko.length ? 1 : 0);
}
run();
