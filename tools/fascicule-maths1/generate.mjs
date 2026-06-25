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

// ── Spécifications des chapitres (titres exacts + thèmes pour les EXERCICES) ──
const CHAPTERS = {
  ch01: { title: 'Généralités sur les fonctions numériques', spec: 'Ensemble de définition ; parité (paire/impaire), périodicité ; sens de variation, taux de variation ; éléments de symétrie (axe x=a, centre) ; fonctions associées (f(x)+k, f(x+a), |f|, kf) ; comparaison de fonctions, majorant/minorant. Exercices : déterminer un ensemble de définition, étudier parité/variations, transformations de courbes.' },
  ch02: { title: 'Polynômes et fractions rationnelles', spec: 'Polynôme à une variable, degré, coefficients ; égalité de polynômes ; racines, factorisation, division euclidienne et division suivant les puissances ; identités remarquables ; fractions rationnelles (simplification, décomposition simple) ; signe d\'un polynôme/d\'une fraction. Exercices : factorisation, division, racines, signe, équations.' },
  ch03: { title: 'Équations, inéquations et systèmes du second degré', spec: 'Trinôme du second degré ; forme canonique ; discriminant, racines ; somme et produit des racines ; signe du trinôme ; équations et inéquations du 2nd degré ; équations bicarrées et s\'y ramenant ; systèmes (somme-produit, systèmes linéaires/non linéaires). Exercices : résolution, paramètres, signe, problèmes.' },
  ch04: { title: 'Limites et continuité (introduction)', spec: 'Notion intuitive de limite en un point et à l\'infini ; limites des fonctions de référence ; opérations sur les limites ; formes indéterminées simples ; continuité en un point et sur un intervalle ; lecture graphique. Exercices : calculs de limites simples, étude de continuité, asymptotes simples.' },
  ch05: { title: 'Dérivation', spec: 'Nombre dérivé (taux d\'accroissement, limite) ; tangente à une courbe ; fonction dérivée ; dérivées des fonctions de référence et opérations (somme, produit, quotient, puissances) ; dérivée et sens de variation ; extremums. Exercices : calcul de dérivées, tangentes, variations, optimisation simple.' },
  ch06: { title: 'Étude et représentation des fonctions', spec: 'Plan d\'étude d\'une fonction ; domaine, parité, limites/asymptotes (verticale, horizontale, oblique simple) ; tableau de variations ; points particuliers ; tracé de la courbe. Fonctions polynômes, rationnelles et irrationnelles simples. Exercices : études complètes de fonctions, tracés (pgfplots), positions relatives.' },
  ch07: { title: 'Suites numériques', spec: 'Modes de génération (explicite, récurrente) ; sens de variation, suites majorées/minorées/bornées ; suites arithmétiques (raison, terme général, somme) ; suites géométriques (raison, terme général, somme) ; applications (intérêts, contextes). Exercices : nature d\'une suite, terme général, sommes, problèmes concrets.' },
  ch08: { title: 'Angles orientés et trigonométrie', spec: 'Cercle trigonométrique, radian ; angles orientés, mesure principale ; lignes trigonométriques (cos, sin, tan) ; valeurs remarquables ; relations fondamentales ; angles associés. Exercices : mesures d\'angles, calculs de lignes trigonométriques, simplifications, repérage sur le cercle.' },
  ch09: { title: 'Formules et équations trigonométriques', spec: 'Formules d\'addition et de duplication ; transformation de a cos x + b sin x ; équations trigonométriques (cos x = a, sin x = a, tan x = a) ; inéquations simples ; résolution sur un intervalle. Exercices : démonstration et utilisation de formules, équations/inéquations trigonométriques.' },
  ch10: { title: 'Dénombrement', spec: 'Principe additif et multiplicatif ; cardinal d\'un ensemble fini ; p-listes (avec répétition) ; arrangements ; permutations ; combinaisons et propriétés (symétrie, triangle de Pascal) ; introduction au binôme de Newton. Exercices : tirages, comités, anagrammes, chemins, dénombrements avec contraintes.' },
  ch11: { title: 'Statistiques à une variable', spec: 'Vocabulaire (population, caractère, effectifs, fréquences) ; séries statistiques, regroupement en classes ; représentations (diagrammes, histogramme, polygone) ; paramètres de position (moyenne, médiane, mode, quartiles) ; paramètres de dispersion (étendue, variance, écart-type). Exercices : calculs de paramètres, interprétation, tableaux et graphiques.' },
  ch12: { title: 'Barycentre et lignes de niveau', spec: 'Barycentre de deux et de n points pondérés ; isobarycentre ; homogénéité ; associativité (barycentres partiels) ; coordonnées du barycentre ; réduction de sommes vectorielles ; lignes de niveau (M ↦ MA² + MB², M ↦ MA/MB). Exercices : construction et calcul de barycentres, réductions, alignements, lieux.' },
  ch13: { title: 'Produit scalaire dans le plan', spec: 'Définition (formes : projeté, coordonnées, norme et angle) ; propriétés (bilinéarité, symétrie) ; orthogonalité ; applications : calcul de longueurs et d\'angles, relations métriques dans le triangle (Al-Kashi, médianes), équations de droites et de cercles, lignes de niveau (M ↦ MA·MB). Exercices : calculs, orthogonalité, distances, lieux.' },
  ch14: { title: 'Géométrie analytique : droites et cercles', spec: 'Repère, coordonnées, distance, milieu ; vecteurs et colinéarité ; équations de droites (cartésienne, paramétrique, réduite), coefficient directeur, parallélisme/perpendicularité ; équation d\'un cercle (centre, rayon), positions relatives droite-cercle. Exercices : équations, intersections, distance point-droite, problèmes de configuration.' },
  ch15: { title: 'Transformations du plan', spec: 'Translations, symétries (centrale et axiale), homothéties, rotations ; définitions, propriétés (conservation des distances/angles/alignement/barycentre selon la transformation) ; expressions analytiques ; images de figures ; composées simples. Exercices : déterminer/construire des images, nature d\'une transformation, composées, propriétés.' },
  ch16: { title: 'Géométrie dans l\'espace (introduction)', spec: 'Droites et plans de l\'espace ; positions relatives (parallélisme, intersection) ; règles d\'incidence ; parallélisme et orthogonalité ; repérage dans l\'espace (coordonnées), vecteurs de l\'espace ; sections planes simples (cube, pyramide). Exercices : positions relatives, coordonnées, vecteurs, sections.' },
};

const ORDER = ['ch01','ch02','ch03','ch04','ch05','ch06','ch07','ch08','ch09','ch10','ch11','ch12','ch13','ch14','ch15','ch16'];

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
  // Les fichiers générés commencent par \section → on les place sous un chapitre factice.
  await writeFile(join(work, 'main.tex'),
    '\\input{preamble.tex}\n\\begin{document}\\mainmatter\n\\chapter{Test}\n\\input{chap}\n\\end{document}\n');
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
  const sys = `Tu es un professeur agrégé de mathématiques camerounais et un expert LaTeX (amsmath, tikz, pgfplots). Tu produis du LaTeX pur, compilable avec tectonic/XeLaTeX, conforme au guide fourni. ${guide}`;
  const user = `Rédige LES EXERCICES (et leurs corrigés) du chapitre suivant du fascicule de Mathématiques Première C.\n\nTITRE DU CHAPITRE : ${ch.title}\nTHÈMES À COUVRIR : ${ch.spec}\n\nN'écris PAS de cours. Commence directement par \\section{Exercices d'application}. Respecte la structure : Exercices d'application (corrigés) → Exercices d'entraînement (non corrigés) → Problèmes type Probatoire/Bac → Corrigés (des exercices d'application et des problèmes). Programme de Première C uniquement. Renvoie UNIQUEMENT le LaTeX, sans \\chapter, sans préambule, sans \\begin{document}.`;
  let messages = [{ role: 'system', content: sys }, { role: 'user', content: user }];

  console.log(`[${id}] génération (modèle ${MODEL})…`);
  let tex = await callNvidia(key, messages, id);

  for (let round = 0; round <= MAX_FIX_ROUNDS; round++) {
    await writeFile(join(HERE, `exo${id.slice(2)}.tex`), tex);
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
