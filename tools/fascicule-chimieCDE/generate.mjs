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

// ── Spécifications des chapitres (titres exacts + consigne de contenu) — COURS UNIQUEMENT ──
const CHAPTERS = {
  ch01: { title: 'Généralités sur la chimie organique', spec: 'Le carbone et ses liaisons (tétravalence, chaînes) ; analyse élémentaire (détermination des pourcentages C, H, O, N) ; détermination de la formule brute puis moléculaire (densité de vapeur, masse molaire) ; formules développée, semi-développée, topologique ; squelette carboné ; isomérie (de chaîne, de position, de fonction ; stéréo-isomérie : Z/E, énantiomérie introduite) ; groupes fonctionnels et familles ; nomenclature systématique (règles IUPAC). Formules chemfig.' },
  ch02: { title: 'Les alcanes', spec: 'Définition (CnH2n+2), série homologue, nomenclature (ramifiés) ; isomérie de chaîne ; propriétés physiques ; propriétés chimiques : combustion complète/incomplète, halogénation radicalaire (mécanisme : initiation, propagation, terminaison), craquage et reformage ; le pétrole et le gaz naturel. Formules chemfig, équations mhchem.' },
  ch03: { title: 'Les alcènes et les alcynes', spec: 'Alcènes (CnH2n) : double liaison, nomenclature, isomérie Z/E ; additions (H2, X2, HX règle de Markovnikov, H2O) ; oxydation ; polymérisation (polyéthylène). Alcynes (CnH2n-2) : triple liaison, additions, hydratation. Tests d\'insaturation (eau de brome, KMnO4). Formules chemfig, mécanismes, équations mhchem.' },
  ch04: { title: 'Les hydrocarbures aromatiques — le benzène', spec: 'Le benzène : structure (cycle, délocalisation, formule de Kekulé), aromaticité ; nomenclature des dérivés (toluène, phénol, etc.) ; propriétés : substitution électrophile aromatique (halogénation, nitration, sulfonation, alkylation de Friedel-Crafts) ; comparaison addition/substitution. Formules chemfig du cycle benzénique.' },
  ch05: { title: 'Les alcools et les phénols', spec: 'Alcools : groupe hydroxyle, classes (primaire/secondaire/tertiaire), nomenclature ; propriétés physiques (liaison hydrogène) ; réactions : déshydratation (intramoléculaire→alcène, intermoléculaire→éther), oxydation ménagée (selon la classe → aldéhyde/cétone/acide), action des acides (estérification), test à la liqueur de Fehling/DNPH des produits. Les phénols (acidité). Formules chemfig, équations.' },
  ch06: { title: 'Les composés carbonylés — aldéhydes et cétones', spec: 'Groupe carbonyle C=O ; aldéhydes vs cétones, nomenclature ; obtention (oxydation des alcools) ; propriétés : tests caractéristiques (2,4-DNPH, liqueur de Fehling, réactif de Tollens/miroir d\'argent, Schiff) ; réactions d\'addition nucléophile ; oxydation des aldéhydes. Distinction aldéhyde/cétone. Formules chemfig, équations mhchem.' },
  ch07: { title: 'Les acides carboxyliques et leurs dérivés', spec: 'Acides carboxyliques : groupe COOH, nomenclature, acidité (pKa) ; obtention (oxydation) ; réactions : avec les bases (sel), estérification (équilibre, catalyse, rendement) ; dérivés : esters (hydrolyse, saponification), anhydrides d\'acide, chlorures d\'acyle, amides ; synthèse d\'un ester par différentes voies (acide, anhydride, chlorure). Formules chemfig, équations.' },
  ch08: { title: 'Les amines', spec: 'Groupe amino, classes (primaire/secondaire/tertiaire), nomenclature ; propriétés physiques ; caractère basique (couple ammonium/amine, pKa), réaction avec les acides et avec l\'eau ; nucléophilie ; préparation. Comparaison avec l\'ammoniac. Formules chemfig, équations mhchem.' },
  ch09: { title: 'Les acides α-aminés et les protéines', spec: 'Acides α-aminés : structure générale, groupe amine + acide, caractère amphotère (zwitterion, pH isoélectrique) ; chiralité (carbone asymétrique, énantiomères) ; la liaison peptidique ; di/poly-peptides et protéines ; structure des protéines (intro). Formules chemfig, équilibres acido-basiques.' },
  ch10: { title: 'La cinétique chimique', spec: 'Vitesse de réaction (vitesse de formation/disparition, vitesse moyenne et instantanée, tangente) ; suivi cinétique (conductimétrie, pH-métrie, titrage) ; facteurs cinétiques (concentration, température, catalyseur) ; temps de demi-réaction ; catalyse (homogène, hétérogène, enzymatique). Courbes concentration-temps (pgfplots), tangentes.' },
  ch11: { title: 'Acides et bases — pH, couples acide/base, pKa', spec: 'Théorie de Brønsted (acide/base, couple, réaction acido-basique) ; autoprotolyse de l\'eau (Ke) ; définition et mesure du pH ; acides/bases forts et faibles ; constante d\'acidité Ka, pKa ; diagramme de prédominance ; calcul du pH (acide fort, base forte, acide faible). Équations mhchem (\\ce{H3O+}, \\ce{HO-}), calculs siunitx.' },
  ch12: { title: 'Réactions acido-basiques : dosages et solutions tampons', spec: 'Réaction acido-basique (avancement, constante d\'équilibre) ; dosage (titrage) acido-basique : équivalence, suivi pH-métrique, courbe de dosage et points remarquables, choix de l\'indicateur coloré ; dosage acide fort/base forte, acide faible/base forte ; solutions tampons (définition, pH=pKa, pouvoir tampon, préparation). Courbes de dosage (pgfplots).' },
  ch13: { title: 'Les réactions d\'oxydoréduction — piles et électrolyse', spec: 'Oxydant/réducteur, couple redox, demi-équations, équilibrage en milieu acide/basique ; classification qualitative (pouvoir oxydant) ; les piles électrochimiques (Daniell : électrodes, anode/cathode, pont salin, f.é.m., polarité, fonctionnement et équation-bilan) ; l\'électrolyse (principe, électrodes, réactions, applications : galvanoplastie, affinage). Schémas TikZ/circuitikz pile et électrolyseur.' },
};

const ORDER = ['ch01','ch02','ch03','ch04','ch05','ch06','ch07','ch08','ch09','ch10','ch11','ch12','ch13'];

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
  const sys = `Tu es un professeur agrégé de chimie camerounais et un expert LaTeX (chemfig, mhchem, siunitx). Tu produis du LaTeX pur, compilable avec tectonic/XeLaTeX, conforme au guide fourni. ${guide}`;
  const user = `Rédige LE COURS du chapitre suivant du fascicule de Chimie Terminales C/D/E/TI.\n\nNuméro de chapitre attendu : ${id.replace('ch','')} (commence par \\chapter{${ch.title}}).\nTITRE : ${ch.title}\nCONTENU À COUVRIR : ${ch.spec}\n\nRespecte SCRUPULEUSEMENT la structure : cours développé (sections, définitions, lois, propriétés, expériences, exemples, figures chemfig/mhchem) → section « L'essentiel à retenir » (synthese) → section « Méthodes \\& savoir-faire ». ⚠️ N'écris NI exercices, NI sujets, NI corrigés : STOP après les méthodes. Renvoie UNIQUEMENT le LaTeX du chapitre, sans préambule ni \\begin{document}.`;
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
