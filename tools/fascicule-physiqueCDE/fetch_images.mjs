#!/usr/bin/env node
// OnBuch — Remplit les placeholders d'images du fascicule de Physique.
// 1) scanne tous les chXX.tex pour les \imgph{cle}{description}
// 2) cherche une image LIBRE sur Wikimedia Commons (description = requête)
// 3) télécharge images/<cle>.<ext>, enregistre licence + attribution (manifest.json)
// 4) remplace \imgph{cle}{desc} par \imgreal{cle}{légende} dans les .tex
//
// Usage :
//   node fetch_images.mjs --dry-run          # liste les images attendues + candidats, NE télécharge rien
//   node fetch_images.mjs                     # télécharge + remplace
//   node fetch_images.mjs --only ch09         # un seul chapitre
// Note proxy : si l'environnement route via un proxy, exporter
//   HTTPS_PROXY ; ce script lit aussi COMMONS_LANG (défaut: requête telle quelle).

import { readFile, writeFile, readdir } from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const IMG_DIR = join(HERE, 'images');
const DRY = process.argv.includes('--dry-run');
const onlyIx = process.argv.indexOf('--only');
const ONLY = onlyIx >= 0 ? process.argv[onlyIx + 1] : null;
const API = 'https://commons.wikimedia.org/w/api.php';

// \imgph{cle}{description} — la description ne doit pas contenir d'accolades (cf. AGENT_GUIDE).
const IMGPH_RE = /\\imgph\{([^{}]+)\}\{([^{}]*)\}/g;

async function listTexFiles() {
  const files = (await readdir(HERE)).filter((f) => /^ch\d+\.tex$/.test(f));
  return ONLY ? files.filter((f) => f.startsWith(ONLY)) : files;
}

async function searchCommons(query) {
  const u = new URL(API);
  u.search = new URLSearchParams({
    action: 'query', format: 'json', generator: 'search',
    gsrsearch: query, gsrnamespace: '6', gsrlimit: '6',
    prop: 'imageinfo', iiprop: 'url|extmetadata|mime', iiurlwidth: '1200',
  }).toString();
  const r = await fetch(u, { headers: { 'User-Agent': 'OnBuch-Fascicule/1.0 (educational)' } });
  if (!r.ok) throw new Error(`Commons HTTP ${r.status}`);
  const data = await r.json();
  const pages = Object.values(data?.query?.pages || {});
  // Garde les images raster exploitables (thumburl rendu), priorité PNG/JPG/SVG-rendu.
  return pages.map((p) => {
    const ii = p.imageinfo?.[0];
    if (!ii) return null;
    const meta = ii.extmetadata || {};
    return {
      title: p.title,
      url: ii.thumburl || ii.url,
      mime: ii.mime,
      license: meta.LicenseShortName?.value || meta.License?.value || 'inconnue',
      artist: (meta.Artist?.value || '').replace(/<[^>]+>/g, '').trim(),
      descUrl: ii.descriptionshorturl || ii.descriptionurl,
    };
  }).filter(Boolean);
}

function extFromUrl(url, mime) {
  const m = url.match(/\.(png|jpe?g|gif)(?:$|\?)/i);
  if (m) return m[1].toLowerCase().replace('jpeg', 'jpg');
  if (/png/.test(mime)) return 'png';
  return 'jpg';
}

async function download(url, dest) {
  const r = await fetch(url, { headers: { 'User-Agent': 'OnBuch-Fascicule/1.0 (educational)' } });
  if (!r.ok) throw new Error(`download HTTP ${r.status}`);
  await pipeline(Readable.fromWeb(r.body), createWriteStream(dest));
}

function caption(desc) {
  let c = desc.trim().replace(/\s+/g, ' ');
  if (c.length > 90) c = c.slice(0, 87) + '…';
  return `Figure — ${c}`;
}

async function run() {
  const files = await listTexFiles();
  const manifest = [];
  let total = 0, done = 0;

  for (const file of files) {
    const path = join(HERE, file);
    let content = await readFile(path, 'utf8');
    const matches = [...content.matchAll(IMGPH_RE)];
    if (!matches.length) continue;

    for (const m of matches) {
      const [full, key, desc] = m;
      total++;
      console.log(`\n[${file}] ${key}\n   « ${desc} »`);
      let candidates = [];
      try { candidates = await searchCommons(desc); }
      catch (e) { console.log(`   ⚠️ recherche échouée: ${e.message}`); }
      if (!candidates.length) { console.log('   ❌ aucun candidat Commons — placeholder conservé'); continue; }

      candidates.slice(0, 4).forEach((c, i) =>
        console.log(`   ${i === 0 ? '➜' : ' '} ${c.title}  [${c.license}]`));

      const pick = candidates[0];
      const entry = { key, file, description: desc, picked: pick.title, license: pick.license,
        artist: pick.artist, source: pick.descUrl };
      manifest.push(entry);

      if (DRY) continue;
      const ext = extFromUrl(pick.url, pick.mime);
      const fname = `${key}.${ext}`;
      try {
        await download(pick.url, join(IMG_DIR, fname));
        content = content.replace(full, `\\imgreal{${fname}}{${caption(desc)}}`);
        entry.saved = fname;
        done++;
        console.log(`   ✅ ${fname}  (${pick.license})`);
      } catch (e) { console.log(`   ❌ téléchargement: ${e.message}`); }
    }
    if (!DRY) await writeFile(path, content);
  }

  await writeFile(join(IMG_DIR, 'manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(`\n=== ${DRY ? 'DRY-RUN' : 'FAIT'} : ${done}/${total} image(s) traitée(s). Manifest → images/manifest.json ===`);
  if (!DRY) console.log('⚠️ Vérifie manifest.json (licences/attribution) et la pertinence des images avant publication.');
}
run();
