<script lang="ts">
  import { onMount } from 'svelte';
  import { databases, storage, RESULT_PDFS_BUCKET, ID, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';

  const DB = APPWRITE_DATABASE;
  const CH = 'exercise_chapters';
  const SH = 'exercise_sheets';
  const NV_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

  // ── Paramètres du chapitre ──────────────────────────────────────────────
  let subject = '';
  let exam = '';
  let track = '';
  let levels = '';
  let chapterMode: 'new' | 'existing' = 'new';
  let chapters: any[] = [];
  let selectedChapterId = '';
  let newChapterTitle = '';
  let newChapterDesc = '';
  let difficulty = 'moyen';
  let count = 5;
  let extra = '';

  // ── Réglages NVIDIA (clé stockée dans le navigateur, jamais dans le code) ──
  let nvKey = '';
  let nvModel = 'nvidia/llama-3.1-nemotron-ultra-253b-v1';

  // ── État ───────────────────────────────────────────────────────────────
  let libsReady = false;
  let generating = false;
  let publishing = false;
  let log = '';
  let sheets: { title: string; statement: string; correction: string; published?: boolean }[] = [];

  function note(m: string) { log = m; }

  onMount(async () => {
    nvKey = localStorage.getItem('nv_key') || '';
    nvModel = localStorage.getItem('nv_model') || nvModel;
    try {
      await loadCss('https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css');
      await loadScript('https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js');
      await loadScript('https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js');
      await loadScript('https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js');
      await loadScript('https://cdn.jsdelivr.net/npm/html2pdf.js@0.10.1/dist/html2pdf.bundle.min.js');
      libsReady = true;
    } catch (e) {
      note('Impossible de charger les librairies de rendu (vérifie ta connexion).');
    }
    await loadChapters();
  });

  function loadScript(src: string): Promise<void> {
    return new Promise((res, rej) => {
      const s = document.createElement('script');
      s.src = src; s.onload = () => res(); s.onerror = () => rej(new Error(src));
      document.head.appendChild(s);
    });
  }
  function loadCss(href: string): Promise<void> {
    return new Promise((res) => {
      const l = document.createElement('link');
      l.rel = 'stylesheet'; l.href = href; l.onload = () => res(); l.onerror = () => res();
      document.head.appendChild(l);
    });
  }

  async function loadChapters() {
    try {
      const r = await databases.listDocuments(DB, CH, [Query.orderAsc('order'), Query.limit(300)]);
      chapters = r.documents;
    } catch { chapters = []; }
  }

  $: filteredChapters = chapters.filter(
    (c) => !subject || (c.subject || '').toLowerCase() === subject.trim().toLowerCase()
  );

  // ── Rendu Markdown + LaTeX (preview & PDF) ───────────────────────────────
  function mdToHtml(md: string): string {
    const w = window as any;
    try { return w.marked ? w.marked.parse(md || '') : (md || ''); } catch { return md || ''; }
  }
  function renderTex(node: HTMLElement) {
    const w = window as any;
    if (w.renderMathInElement) {
      try {
        w.renderMathInElement(node, {
          delimiters: [
            { left: '$$', right: '$$', display: true },
            { left: '$', right: '$', display: false },
            { left: '\\(', right: '\\)', display: false },
            { left: '\\[', right: '\\]', display: true },
          ],
          throwOnError: false,
        });
      } catch { /* ignore */ }
    }
  }
  // Action Svelte : (re)rend les maths quand le contenu change.
  function tex(node: HTMLElement, _content: string) {
    renderTex(node);
    return { update() { renderTex(node); } };
  }

  // ── Génération (appel direct NVIDIA, une fiche à la fois) ────────────────
  async function generate() {
    if (!nvKey.trim()) { note('Renseigne ta clé NVIDIA.'); return; }
    if (!subject.trim()) { note('Renseigne la matière.'); return; }
    const chapTitle = chapterMode === 'new'
      ? newChapterTitle.trim()
      : (chapters.find((c) => c.$id === selectedChapterId)?.title || '');
    if (!chapTitle) { note('Choisis ou nomme un chapitre.'); return; }
    localStorage.setItem('nv_key', nvKey);
    localStorage.setItem('nv_model', nvModel);

    generating = true; sheets = [];
    try {
      for (let i = 1; i <= count; i++) {
        note(`Génération de la fiche ${i}/${count}…`);
        const sys = `Tu es un professeur camerounais expert du programme MINESEC. Tu rédiges des fiches d'exercices de très haute qualité, claires et rigoureuses.
RÉPONDS UNIQUEMENT avec un JSON STRICT, sans texte autour ni balise de code, au format EXACT :
{"title":"...","statement":"...","correction":"..."}
- "title" : titre court de la fiche.
- "statement" : l'énoncé en Markdown. Les maths en LaTeX entre $ ... $ (en ligne) ou $$ ... $$ (bloc). Plusieurs exercices possibles, numérotés.
- "correction" : la correction détaillée, étape par étape, en Markdown + LaTeX (mêmes délimiteurs).
N'utilise PAS de bloc de code, PAS de \\boxed sans contenu, échappe correctement les antislashs dans le JSON.`;
        const usr = `Matière : ${subject}
Classe / examen : ${[exam, track, levels].filter(Boolean).join(' · ') || 'non précisé'}
Chapitre : ${chapTitle}
Difficulté : ${difficulty}
Fiche numéro ${i} sur ${count} (rends-la DIFFÉRENTE des autres).
${extra ? 'Consignes supplémentaires : ' + extra : ''}`;
        const content = await callNvidia([
          { role: 'system', content: sys },
          { role: 'user', content: usr },
        ]);
        const parsed = parseSheet(content, `${chapTitle} — Fiche ${i}`);
        sheets = [...sheets, parsed];
      }
      note(`✅ ${sheets.length} fiche(s) générée(s). Vérifie, édite si besoin, puis publie.`);
    } catch (e: any) {
      note('Erreur de génération : ' + (e?.message || e));
    } finally {
      generating = false;
    }
  }

  async function callNvidia(messages: any[]): Promise<string> {
    const res = await fetch(NV_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${nvKey}`, 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ model: nvModel, messages, temperature: 0.4, top_p: 0.9, max_tokens: 4000 }),
    });
    if (!res.ok) throw new Error('NVIDIA ' + res.status + ' — ' + (await res.text()).slice(0, 180));
    const data = await res.json();
    let c = data?.choices?.[0]?.message?.content || '';
    c = c.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
    return c;
  }

  function parseSheet(raw: string, fallbackTitle: string) {
    let s = raw.trim().replace(/^```(?:json)?/i, '').replace(/```$/i, '').trim();
    const a = s.indexOf('{'); const b = s.lastIndexOf('}');
    if (a >= 0 && b > a) s = s.slice(a, b + 1);
    try {
      const o = JSON.parse(s);
      return {
        title: (o.title || fallbackTitle).toString(),
        statement: (o.statement || '').toString(),
        correction: (o.correction || '').toString(),
      };
    } catch {
      return { title: fallbackTitle, statement: raw, correction: '' };
    }
  }

  // ── Publication : HTML (template) → PDF → Storage → exercise_sheets ───────
  let stage: HTMLDivElement;

  function docHtml(title: string, kind: string, bodyMd: string): string {
    const accent = kind === 'Correction' ? '#1E9E63' : '#F2620E';
    return `<div class="pdfdoc">
      <div class="pdfhead" style="border-color:${accent}">
        <div class="pdfbrand">On<span>Buch</span></div>
        <div class="pdfkind" style="color:${accent}">${kind}</div>
      </div>
      <h1 class="pdftitle">${escapeHtml(title)}</h1>
      <div class="pdfmeta">${escapeHtml([subject, difficulty].filter(Boolean).join(' · '))}</div>
      <div class="pdfbody">${mdToHtml(bodyMd)}</div>
      <div class="pdffoot">Généré par Léo · OnBuch</div>
    </div>`;
  }
  function escapeHtml(s: string) {
    return (s || '').replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' } as any)[c]);
  }

  async function renderPdfBlob(title: string, kind: string, bodyMd: string): Promise<Blob> {
    const w = window as any;
    stage.innerHTML = docHtml(title, kind, bodyMd);
    renderTex(stage);
    await new Promise((r) => setTimeout(r, 60)); // laisse KaTeX peindre
    const opt = {
      margin: [10, 10, 12, 10],
      filename: 'doc.pdf',
      image: { type: 'jpeg', quality: 0.96 },
      html2canvas: { scale: 2, useCORS: true },
      jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
      pagebreak: { mode: ['css', 'legacy'] },
    };
    const blob = await w.html2pdf().set(opt).from(stage.firstElementChild).outputPdf('blob');
    return blob as Blob;
  }

  async function uploadPdf(blob: Blob, name: string): Promise<string> {
    const file = new File([blob], name, { type: 'application/pdf' });
    const created = await storage.createFile(RESULT_PDFS_BUCKET, ID.unique(), file);
    return storage.getFileView(RESULT_PDFS_BUCKET, created.$id).toString();
  }

  async function publishAll() {
    if (!sheets.length) { note('Rien à publier.'); return; }
    if (!libsReady) { note('Les librairies de rendu ne sont pas prêtes.'); return; }
    publishing = true;
    try {
      // 1) chapitre
      let chapterId = selectedChapterId;
      if (chapterMode === 'new') {
        note('Création du chapitre…');
        const c = await databases.createDocument(DB, CH, ID.unique(), {
          subject: subject.trim(),
          title: newChapterTitle.trim(),
          exam: exam.trim(),
          track: track.trim(),
          levels: levels.trim(),
          description: newChapterDesc.trim() || null,
          order: chapters.length + 1,
        });
        chapterId = c.$id;
        await loadChapters();
        chapterMode = 'existing';
        selectedChapterId = chapterId;
      }
      // 2) fiches
      for (let i = 0; i < sheets.length; i++) {
        const f = sheets[i];
        if (f.published) continue;
        note(`Publication de « ${f.title} » (${i + 1}/${sheets.length})…`);
        const stmtUrl = await uploadPdf(await renderPdfBlob(f.title, 'Énoncé', f.statement), `enonce_${i + 1}.pdf`);
        let corrUrl: string | null = null;
        if (f.correction.trim()) {
          corrUrl = await uploadPdf(await renderPdfBlob(f.title, 'Correction', f.correction), `correction_${i + 1}.pdf`);
        }
        await databases.createDocument(DB, SH, ID.unique(), {
          chapterId,
          subject: subject.trim(),
          title: f.title,
          difficulty,
          statementPdfUrl: stmtUrl,
          correctionPdfUrl: corrUrl,
          order: i + 1,
        });
        sheets[i] = { ...f, published: true };
        sheets = [...sheets];
      }
      note('✅ Publication terminée. Les fiches sont visibles dans l\'app.');
    } catch (e: any) {
      note('Erreur de publication : ' + (e?.message || e));
    } finally {
      publishing = false;
    }
  }
</script>

<svelte:head><title>Atelier Exercices — OnBuch</title></svelte:head>

<div class="wrap">
  <h1>🧪 Atelier Exercices</h1>
  <p class="sub">Génère des fiches d'exercices (énoncé + correction) avec l'IA, prévisualise le rendu LaTeX, puis publie en PDF.</p>

  <div class="card">
    <h2>1. Chapitre</h2>
    <div class="grid">
      <label>Matière<input bind:value={subject} placeholder="Mathématiques" /></label>
      <label>Examen<input bind:value={exam} placeholder="Baccalauréat (vide = tous)" /></label>
      <label>Série<input bind:value={track} placeholder="C (vide = toutes)" /></label>
      <label>Classes<input bind:value={levels} placeholder="Terminale,1ère (vide = toutes)" /></label>
    </div>
    <div class="row">
      <label class="radio"><input type="radio" bind:group={chapterMode} value="new" /> Nouveau chapitre</label>
      <label class="radio"><input type="radio" bind:group={chapterMode} value="existing" /> Chapitre existant</label>
    </div>
    {#if chapterMode === 'new'}
      <div class="grid">
        <label>Titre du chapitre<input bind:value={newChapterTitle} placeholder="Dérivation" /></label>
        <label>Description (option)<input bind:value={newChapterDesc} placeholder="" /></label>
      </div>
    {:else}
      <label>Chapitre
        <select bind:value={selectedChapterId}>
          <option value="">— choisir —</option>
          {#each filteredChapters as c}<option value={c.$id}>{c.title} ({c.subject})</option>{/each}
        </select>
      </label>
    {/if}
  </div>

  <div class="card">
    <h2>2. Génération</h2>
    <div class="grid">
      <label>Difficulté
        <select bind:value={difficulty}>
          <option value="facile">facile</option>
          <option value="moyen">moyen</option>
          <option value="difficile">difficile</option>
        </select>
      </label>
      <label>Nombre de fiches<input type="number" min="1" max="10" bind:value={count} /></label>
    </div>
    <label>Consignes supplémentaires (option)<input bind:value={extra} placeholder="Ex. inclure un exercice type Bac" /></label>
    <details class="nv">
      <summary>Réglages IA (clé NVIDIA)</summary>
      <label>Clé API NVIDIA<input type="password" bind:value={nvKey} placeholder="nvapi-…" /></label>
      <label>Modèle<input bind:value={nvModel} /></label>
      <p class="hint">La clé est stockée uniquement dans ce navigateur. L'admin appelle l'API directement.</p>
    </details>
    <button class="primary" on:click={generate} disabled={generating || publishing}>
      {generating ? 'Génération…' : 'Générer les fiches'}
    </button>
  </div>

  {#if log}<div class="log">{log}</div>{/if}

  {#if sheets.length}
    <div class="card">
      <h2>3. Prévisualisation & édition</h2>
      {#each sheets as f, i}
        <div class="sheet" class:done={f.published}>
          <input class="title" bind:value={f.title} />
          <div class="cols">
            <div class="col">
              <div class="coltag" style="color:#F2620E">Énoncé</div>
              <textarea bind:value={f.statement}></textarea>
              <div class="preview" use:tex={f.statement}>{@html mdToHtml(f.statement)}</div>
            </div>
            <div class="col">
              <div class="coltag" style="color:#1E9E63">Correction</div>
              <textarea bind:value={f.correction}></textarea>
              <div class="preview" use:tex={f.correction}>{@html mdToHtml(f.correction)}</div>
            </div>
          </div>
          {#if f.published}<div class="badge">✅ Publiée</div>{/if}
        </div>
      {/each}
      <button class="primary green" on:click={publishAll} disabled={publishing || generating}>
        {publishing ? 'Publication…' : 'Publier en PDF dans l\'app'}
      </button>
    </div>
  {/if}

  <!-- Scène cachée pour le rendu PDF -->
  <div bind:this={stage} class="pdfstage"></div>
</div>

<style>
  .wrap { max-width: 1000px; margin: 0 auto; padding: 8px 4px 60px; }
  h1 { font-size: 24px; margin: 0 0 4px; }
  .sub { color: #6b6256; margin: 0 0 18px; }
  .card { background: #fff; border: 1.5px solid #ece4d8; border-radius: 16px; padding: 18px; margin-bottom: 16px; }
  .card h2 { font-size: 15px; margin: 0 0 14px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  label { display: flex; flex-direction: column; font-size: 12.5px; font-weight: 600; color: #5a5145; gap: 5px; margin-bottom: 10px; }
  input, select, textarea { font: inherit; padding: 9px 11px; border: 1.5px solid #e3dccf; border-radius: 10px; background: #fffdfa; }
  .row { display: flex; gap: 18px; margin: 4px 0 10px; }
  .radio { flex-direction: row; align-items: center; gap: 6px; }
  details.nv { margin: 8px 0 14px; }
  details.nv summary { cursor: pointer; font-weight: 700; font-size: 13px; color: #b45a0c; }
  .hint { font-size: 11.5px; color: #8a8073; margin: 4px 0 0; }
  button.primary { background: #F2620E; color: #fff; border: none; border-radius: 12px; padding: 12px 18px; font-weight: 800; cursor: pointer; }
  button.primary.green { background: #1E9E63; }
  button.primary:disabled { opacity: .5; cursor: default; }
  .log { background: #241B12; color: #ffd9b8; border-radius: 10px; padding: 10px 14px; font-size: 13px; margin-bottom: 16px; }
  .sheet { border: 1.5px solid #ece4d8; border-radius: 12px; padding: 12px; margin-bottom: 14px; }
  .sheet.done { border-color: #1E9E63; }
  .sheet .title { width: 100%; font-weight: 800; margin-bottom: 10px; }
  .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .coltag { font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: .08em; margin-bottom: 6px; }
  textarea { width: 100%; min-height: 120px; resize: vertical; font-family: 'JetBrains Mono', monospace; font-size: 12px; }
  .preview { margin-top: 8px; padding: 12px; background: #FFF8F1; border: 1px dashed #f0c9a6; border-radius: 10px; font-size: 13.5px; line-height: 1.5; overflow-x: auto; }
  .badge { margin-top: 8px; color: #1E9E63; font-weight: 700; font-size: 12.5px; }
  .pdfstage { position: fixed; left: -9999px; top: 0; width: 794px; }
  /* style du document PDF (cohérent avec le template OnBuch) */
  :global(.pdfdoc) { width: 794px; padding: 40px 44px; font-family: 'Plus Jakarta Sans', system-ui, sans-serif; color: #241B12; background: #fff; }
  :global(.pdfhead) { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #F2620E; padding-bottom: 12px; margin-bottom: 18px; }
  :global(.pdfbrand) { font-family: 'Space Grotesk', sans-serif; font-weight: 800; font-size: 22px; color: #241B12; }
  :global(.pdfbrand span) { color: #F2620E; }
  :global(.pdfkind) { font-weight: 800; text-transform: uppercase; letter-spacing: .1em; font-size: 13px; }
  :global(.pdftitle) { font-family: 'Space Grotesk', sans-serif; font-size: 24px; margin: 0 0 4px; }
  :global(.pdfmeta) { color: #8a8073; font-size: 13px; margin-bottom: 18px; }
  :global(.pdfbody) { font-size: 15px; line-height: 1.6; }
  :global(.pdfbody h1,.pdfbody h2,.pdfbody h3) { font-family: 'Space Grotesk', sans-serif; }
  :global(.pdffoot) { margin-top: 28px; border-top: 1px solid #eee; padding-top: 10px; color: #b0a596; font-size: 11px; text-align: center; }
  @media (max-width: 760px) { .grid, .cols { grid-template-columns: 1fr; } }
</style>
