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
  ch01: { title: 'Architecture et fonctionnement de l\'ordinateur', spec: 'Structure d\'un ordinateur (unité centrale, périphériques d\'entrée/sortie, mémoires) ; processeur (UAL, unité de commande, registres, horloge/fréquence) ; mémoires (RAM, ROM, mémoire de masse, hiérarchie, capacités) ; bus ; modèle de von Neumann. Exercices : QCM, rôle des composants, calculs de capacité (octets, Kio/Mio/Gio) et de fréquence/débit.' },
  ch02: { title: 'Systèmes d\'exploitation et maintenance', spec: 'Rôles d\'un système d\'exploitation (gestion des ressources, des fichiers, des processus, des utilisateurs) ; types de SE ; arborescence de fichiers et chemins ; commandes de base ; maintenance préventive/curative, sauvegarde, antivirus. Exercices : QCM, chemins de fichiers, diagnostic de pannes, bonnes pratiques.' },
  ch03: { title: 'Systèmes de numération et codage de l\'information', spec: 'Systèmes binaire, octal, décimal, hexadécimal ; conversions entre bases ; opérations en binaire (addition) ; codage des entiers (binaire pur, complément à 2) ; codage des caractères (ASCII) ; unités de mesure de l\'information (bit, octet, multiples). BEAUCOUP d\'exercices de conversion et de codage, tous corrigés.' },
  ch04: { title: 'Système d\'information et modèle conceptuel des données (MCD)', spec: 'Notion de système d\'information ; méthode MERISE ; modèle conceptuel des données : entités, attributs, identifiants, associations, cardinalités (0,1 / 1,1 / 0,n / 1,n). Exercices : lire un MCD, construire un MCD à partir d\'un énoncé (gestion d\'école, bibliothèque, hôpital…), déterminer les cardinalités. MCD présentés sous forme de tableaux/descriptions (éviter les schémas TikZ complexes).' },
  ch05: { title: 'Du MCD au modèle relationnel', spec: 'Passage du MCD au modèle logique/relationnel : règles de transformation (entité → table, association selon les cardinalités, clés primaires et étrangères) ; notation relationnelle TABLE(att1, att2, #clé_étrangère). Exercices : transformer un MCD en relations, identifier clés primaires et étrangères.' },
  ch06: { title: 'Le langage SQL', spec: 'Langage de définition (CREATE TABLE) et de manipulation des données ; requêtes SELECT (projection, sélection WHERE, ORDER BY, DISTINCT), fonctions d\'agrégation (COUNT, SUM, AVG, MIN, MAX), GROUP BY, jointures entre tables ; INSERT, UPDATE, DELETE. BEAUCOUP de requêtes à écrire à partir d\'un schéma relationnel donné (contexte camerounais), toutes corrigées. Utiliser l\'environnement sqlcode.' },
  ch07: { title: 'Le tableur', spec: 'Cellule, ligne, colonne, références relatives et absolues ($A$1) ; formules et fonctions (SOMME, MOYENNE, MIN, MAX, SI, NB, NB.SI, RECHERCHEV) ; recopie de formules ; graphiques. Exercices : écrire des formules, prédire des résultats, concevoir une feuille de calcul (notes, factures, gestion). Présenter les feuilles sous forme de tableaux.' },
  ch08: { title: 'Algorithmique : variables et structures de contrôle', spec: 'Notion d\'algorithme ; variables et types ; affectation, lecture, écriture ; structures conditionnelles (Si…Alors…Sinon) ; structures itératives (Pour, Tant que, Répéter…Jusqu\'à). Exercices : écrire des algorithmes en pseudo-code (environnement algo), dérouler un algorithme (tableau de valeurs), trouver/corriger des erreurs. TOUS corrigés.' },
  ch09: { title: 'Tableaux et structures de données', spec: 'Tableaux à une dimension (déclaration, parcours, remplissage, somme, recherche d\'un élément, maximum/minimum, tri simple) ; introduction aux tableaux à deux dimensions ; chaînes de caractères. Exercices : algorithmes (pseudo-code) sur les tableaux, recherche, tri, comptage. TOUS corrigés.' },
  ch10: { title: 'Programmation en langage C', spec: 'Structure d\'un programme C ; types et variables ; entrées/sorties (printf, scanf) ; opérateurs ; structures de contrôle (if/else, for, while) ; tableaux ; fonctions. Exercices : écrire, compléter, corriger des programmes C ; prédire la sortie. Utiliser l\'environnement ccode. TOUS corrigés.' },
  ch11: { title: 'Les réseaux informatiques', spec: 'Notion de réseau, intérêts ; types (PAN, LAN, MAN, WAN) ; topologies (bus, étoile, anneau, maillée) ; matériels d\'interconnexion (carte réseau, switch, routeur, modem) ; adressage IP (classes A/B/C, masque de sous-réseau, identification réseau/hôte, nombre d\'hôtes) ; supports de transmission. Exercices : QCM, topologies, calculs d\'adressage IP et de nombre d\'hôtes, débit.' },
  ch12: { title: 'Internet, le web et la citoyenneté numérique', spec: 'Internet et ses services (web, messagerie, etc.) ; le web (URL, navigateur, serveur, HTTP) ; bases du HTML (balises de structure) ; sécurité informatique (mots de passe, malwares, bonnes pratiques) ; citoyenneté et droit numériques (protection des données, propriété intellectuelle, comportements responsables). Exercices : QCM, lecture/écriture de HTML simple, cas pratiques de sécurité et de citoyenneté.' },
};

const ORDER = ['ch01','ch02','ch03','ch04','ch05','ch06','ch07','ch08','ch09','ch10','ch11','ch12'];

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
  const sys = `Tu es un professeur d'informatique camerounais et un expert LaTeX (package listings). Tu produis du LaTeX pur, compilable avec tectonic/XeLaTeX, conforme au guide fourni. ${guide}`;
  const user = `Rédige le chapitre suivant du fascicule d'Informatique Terminales C/D/E.\n\nNuméro de chapitre attendu : ${id.replace('ch','')} (commence par \\chapter{${ch.title}}).\nTITRE : ${ch.title}\nCONTENU À COUVRIR : ${ch.spec}\n\nPhilosophie : cours = RÉSUMÉ court et simple ; puis ÉNORMÉMENT d'exercices type-examen (vise 20 à 30), TOUS corrigés. Respecte la structure : \\section{L'essentiel du cours} (résumé) → \\section{Exercices} (classés par \\rubrique, avec \\sujetbac) → \\section{Corrigés} (un \\corrige pour CHAQUE exercice). Code uniquement dans les environnements algo / ccode / sqlcode. Renvoie UNIQUEMENT le LaTeX du chapitre, sans préambule ni \\begin{document}.`;
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
