<script lang="ts">
  import { onMount } from 'svelte';
  import { databases, ID, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';

  const DB = APPWRITE_DATABASE;
  const SUB = 'subjects';   // matière = pack
  const CHA = 'chapters';   // chapitre
  const LES = 'lessons';    // leçon (1/chapitre, id = chapterId)
  const QUI = 'quizzes';    // quiz (1/chapitre, id = chapterId)

  // ── Arbre (exam_series) : Examen → Série → Matière, comme l'Atelier Exercices
  let series: any[] = [];
  let selExam = '';
  let selSerieName = '';
  let selMatiere = '';

  const LEVEL_BY_EXAM: Record<string, string> = {
    'Baccalauréat': 'Terminale', 'Probatoire': '1ère', 'BEPC': '3e',
    'GCE A Level': 'Upper Sixth', 'GCE O Level': 'Form 5',
  };
  $: exams = Array.from(new Set(series.map((s) => s.exam).filter(Boolean)));
  $: seriesForExam = series.filter((s) => s.exam === selExam);
  $: selSerieDoc = series.find((x) => x.exam === selExam && x.name === selSerieName);
  $: subjectsForSerie = (selSerieDoc?.subjects || '')
    .split(',').map((x: string) => x.trim()).filter(Boolean);
  // Champs dérivés (servent à créer le pack / les chapitres).
  $: exam = selExam;
  $: serieCode = selSerieDoc?.code || '';
  $: levels = LEVEL_BY_EXAM[selExam] || '';

  function norm(s: string): string {
    return (s || '').normalize('NFKD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
  }

  // ── Pack (matière) courant ────────────────────────────────────────────────
  let pack: any = null;          // doc subjects, ou null si pas encore créé
  let packForm: any = null;      // réglages éditables du pack
  let lookingUp = false;
  let savingPack = false;

  // Réglages par défaut d'un nouveau pack.
  function freshPackForm() {
    return { premium: false, priceCredits: 0, coef: 1, freeChapters: 2, track: '' };
  }

  async function onMatiereChange() {
    pack = null; packForm = null; chapters = []; expanded = {}; lessonBuf = {}; quizBuf = {};
    if (!selExam || !selMatiere) return;
    lookingUp = true;
    try {
      // Cherche un pack existant : même examen + même nom (normalisé).
      const r = await databases.listDocuments(DB, SUB, [Query.equal('exam', exam), Query.limit(100)]);
      const found = r.documents.find((d: any) => norm(d.name) === norm(selMatiere));
      if (found) {
        pack = found;
        packForm = {
          premium: !!found.premium, priceCredits: Number(found.priceCredits || 0),
          coef: Number(found.coef || 1), freeChapters: Number(found.freeChapters ?? 2),
          track: found.track || '',
        };
        await loadChapters();
      } else {
        packForm = freshPackForm();
      }
    } catch (e: any) {
      note('Erreur de recherche du pack : ' + (e?.message || e), true);
    } finally {
      lookingUp = false;
    }
  }

  function initials(name: string): string {
    const w = (name || '').trim().split(/\s+/);
    if (w.length >= 2) return (w[0][0] + w[1][0]).toUpperCase();
    return (name || '').trim().slice(0, 2).toUpperCase();
  }

  async function createPack() {
    if (!selMatiere || !exam) { note('Choisis Examen → Série → Matière.', true); return; }
    savingPack = true;
    try {
      const doc = await databases.createDocument(DB, SUB, ID.unique(), {
        name: selMatiere.trim(),
        code: initials(selMatiere),
        levels: levels || '',
        exam: exam.trim(),
        track: (packForm.track || '').trim(),
        premium: !!packForm.premium,
        priceCredits: packForm.premium ? Number(packForm.priceCredits || 0) : 0,
        coef: Number(packForm.coef || 1),
        freeChapters: Number(packForm.freeChapters ?? 2),
        order: 0,
      });
      pack = doc;
      await loadChapters();
      note('Pack « ' + selMatiere + ' » créé ✓');
    } catch (e: any) {
      note('Création du pack impossible : ' + (e?.message || e), true);
    } finally {
      savingPack = false;
    }
  }

  async function savePack() {
    if (!pack) return;
    savingPack = true;
    try {
      await databases.updateDocument(DB, SUB, pack.$id, {
        premium: !!packForm.premium,
        priceCredits: packForm.premium ? Number(packForm.priceCredits || 0) : 0,
        coef: Number(packForm.coef || 1),
        freeChapters: Number(packForm.freeChapters ?? 2),
        track: (packForm.track || '').trim(),
      });
      note('Réglages enregistrés ✓');
    } catch (e: any) {
      note('Enregistrement impossible : ' + (e?.message || e), true);
    } finally {
      savingPack = false;
    }
  }

  // ── Chapitres ─────────────────────────────────────────────────────────────
  let chapters: any[] = [];
  let newChapTitle = '';
  let newChapDesc = '';
  let newChapVideo = '';
  let addingChap = false;

  async function loadChapters() {
    if (!pack) { chapters = []; return; }
    try {
      const r = await databases.listDocuments(DB, CHA, [
        Query.equal('subjectId', pack.$id), Query.orderAsc('order'), Query.limit(200),
      ]);
      chapters = r.documents;
    } catch { chapters = []; }
  }

  async function addChapter() {
    if (!pack) { note('Crée d\'abord le pack.', true); return; }
    if (!newChapTitle.trim()) { note('Donne un titre au chapitre.', true); return; }
    addingChap = true;
    try {
      await databases.createDocument(DB, CHA, ID.unique(), {
        subjectId: pack.$id,
        title: newChapTitle.trim(),
        description: newChapDesc.trim() || null,
        level: levels || '',
        videoUrl: newChapVideo.trim() || null,
        order: chapters.length + 1,
      });
      newChapTitle = ''; newChapDesc = ''; newChapVideo = '';
      await loadChapters();
      note('Chapitre ajouté ✓');
    } catch (e: any) {
      note('Ajout impossible : ' + (e?.message || e), true);
    } finally {
      addingChap = false;
    }
  }

  async function deleteChapter(c: any) {
    if (!confirm('Supprimer ce chapitre, sa leçon et son quiz ?')) return;
    try {
      for (const col of [LES, QUI]) {
        try { await databases.deleteDocument(DB, col, c.$id); } catch { /* pas de doc */ }
      }
      await databases.deleteDocument(DB, CHA, c.$id);
      await loadChapters();
      note('Chapitre supprimé ✓');
    } catch (e: any) {
      note('Suppression impossible : ' + (e?.message || e), true);
    }
  }

  async function saveChapterMeta(c: any) {
    try {
      await databases.updateDocument(DB, CHA, c.$id, {
        title: (c.title || '').trim(),
        description: (c.description || '').trim() || null,
        videoUrl: (c.videoUrl || '').trim() || null,
      });
      note('Chapitre mis à jour ✓');
    } catch (e: any) {
      note('Erreur : ' + (e?.message || e), true);
    }
  }

  // ── Leçon + Quiz par chapitre (chargés à l'ouverture) ─────────────────────
  let expanded: Record<string, boolean> = {};
  let lessonBuf: Record<string, string> = {}; // contenu leçon (Markdown) par chapterId
  let quizBuf: Record<string, string> = {};   // contenu quiz (JSON) par chapterId
  let busy: Record<string, string> = {};       // état d'action par chapterId

  async function toggle(c: any) {
    const id = c.$id;
    expanded[id] = !expanded[id];
    expanded = { ...expanded };
    if (expanded[id] && lessonBuf[id] === undefined) {
      // Charge leçon + quiz (id = chapterId) — 404 = pas encore créé.
      try {
        const l = await databases.getDocument(DB, LES, id);
        lessonBuf[id] = l.content || '';
      } catch { lessonBuf[id] = ''; }
      try {
        const q = await databases.getDocument(DB, QUI, id);
        quizBuf[id] = q.content || '';
      } catch { quizBuf[id] = ''; }
      lessonBuf = { ...lessonBuf }; quizBuf = { ...quizBuf };
    }
  }

  async function upsert(col: string, id: string, data: any) {
    try {
      await databases.createDocument(DB, col, id, data);
    } catch (err: any) {
      if (err?.code === 409) await databases.updateDocument(DB, col, id, data);
      else throw err;
    }
  }

  async function saveLesson(c: any) {
    const id = c.$id;
    busy[id] = 'lesson'; busy = { ...busy };
    try {
      await upsert(LES, id, { chapterId: id, content: lessonBuf[id] || '' });
      note('Leçon enregistrée ✓');
    } catch (e: any) { note('Erreur leçon : ' + (e?.message || e), true); }
    finally { busy[id] = ''; busy = { ...busy }; }
  }

  function quizError(id: string): string {
    const raw = (quizBuf[id] || '').trim();
    if (!raw) return '';
    try {
      const o = JSON.parse(raw);
      if (!o || !Array.isArray(o.questions)) return 'Il manque un tableau « questions ».';
      for (const [i, q] of o.questions.entries()) {
        if (!q.q || !Array.isArray(q.options) || typeof q.answer !== 'number')
          return `Question ${i + 1} : il faut « q », « options » (liste) et « answer » (index).`;
      }
      return '';
    } catch (e: any) { return 'JSON invalide : ' + (e?.message || e); }
  }

  async function saveQuiz(c: any) {
    const id = c.$id;
    const err = quizError(id);
    if (err) { note('Quiz — ' + err, true); return; }
    busy[id] = 'quiz'; busy = { ...busy };
    try {
      await upsert(QUI, id, { chapterId: id, content: (quizBuf[id] || '').trim() });
      note('Quiz enregistré ✓');
    } catch (e: any) { note('Erreur quiz : ' + (e?.message || e), true); }
    finally { busy[id] = ''; busy = { ...busy }; }
  }

  const QUIZ_TEMPLATE = JSON.stringify({
    questions: [
      { q: 'Énoncé de la question ?', options: ['Réponse A', 'Réponse B', 'Réponse C', 'Réponse D'], answer: 0, explanation: 'Pourquoi A est correct.' },
    ],
  }, null, 2);

  function insertQuizTemplate(id: string) {
    if (!quizBuf[id] || confirm('Remplacer le contenu actuel du quiz par un modèle ?')) {
      quizBuf[id] = QUIZ_TEMPLATE; quizBuf = { ...quizBuf };
    }
  }

  function parsedQuiz(id: string): any[] {
    try {
      const o = JSON.parse((quizBuf[id] || '').trim());
      return Array.isArray(o?.questions) ? o.questions : [];
    } catch { return []; }
  }

  // ── IA (réutilise le proxy /api/nv, comme l'Atelier Exercices) ────────────
  let nvKey = '';
  let nvModel = 'nvidia/llama-3.1-nemotron-ultra-253b-v1';
  let libsReady = false;

  onMount(async () => {
    nvKey = localStorage.getItem('nv_key') || '';
    nvModel = localStorage.getItem('nv_model') || nvModel;
    try {
      await loadCss('https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css');
      await loadScript('https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js');
      await loadScript('https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js');
      await loadScript('https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js');
      libsReady = true;
    } catch { /* preview dégradée si hors-ligne */ }
    await loadSeries();
  });

  async function loadSeries() {
    try {
      const r = await databases.listDocuments(DB, 'exam_series', [Query.orderAsc('sortOrder'), Query.limit(500)]);
      series = r.documents;
    } catch { series = []; }
  }

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
  function tex(node: HTMLElement, _c: string) {
    renderTex(node);
    return { update() { renderTex(node); } };
  }

  async function callNvidia(messages: any[], maxTokens = 4000): Promise<string> {
    const res = await fetch('/api/nv', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: nvKey, model: nvModel, messages, max_tokens: maxTokens }),
    });
    if (!res.ok || !res.body) {
      throw new Error('NVIDIA ' + res.status + ' — ' + (await res.text().catch(() => '')).slice(0, 200));
    }
    const reader = res.body.getReader();
    const dec = new TextDecoder();
    let buf = '', full = '';
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buf += dec.decode(value, { stream: true });
      let nl: number;
      while ((nl = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line.startsWith('data:')) continue;
        const d = line.slice(5).trim();
        if (!d || d === '[DONE]') continue;
        try { full += JSON.parse(d)?.choices?.[0]?.delta?.content || ''; } catch { /* fragment */ }
      }
    }
    return full.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
  }

  function ctx(c: any): string {
    return `Matière : ${selMatiere}\nClasse / examen : ${[exam, serieCode, levels].filter(Boolean).join(' · ') || 'non précisé'}\nChapitre : ${c.title}`;
  }

  async function genLesson(c: any) {
    if (!nvKey.trim()) { note('Renseigne ta clé NVIDIA (Réglages IA).', true); return; }
    localStorage.setItem('nv_key', nvKey); localStorage.setItem('nv_model', nvModel);
    busy[c.$id] = 'gen-lesson'; busy = { ...busy };
    try {
      const sys = `Tu es un professeur camerounais expert du programme MINESEC. Tu rédiges des leçons de cours claires, structurées et rigoureuses, prêtes à être lues par un élève.
RÉPONDS UNIQUEMENT avec le contenu de la leçon en Markdown (titres ##, sous-titres ###, listes -, **gras**, tableaux si utile). Les formules mathématiques en LaTeX entre $ ... $ (en ligne) ou $$ ... $$ (bloc). PAS de bloc de code, PAS de texte d'introduction autour.`;
      const out = await callNvidia([
        { role: 'system', content: sys },
        { role: 'user', content: ctx(c) + '\n\nRédige la leçon complète de ce chapitre.' },
      ], 5000);
      lessonBuf[c.$id] = out.replace(/^```(?:markdown)?/i, '').replace(/```$/i, '').trim();
      lessonBuf = { ...lessonBuf };
      note('Leçon générée — vérifie puis enregistre.');
    } catch (e: any) { note('Génération leçon : ' + (e?.message || e), true); }
    finally { busy[c.$id] = ''; busy = { ...busy }; }
  }

  async function genQuiz(c: any) {
    if (!nvKey.trim()) { note('Renseigne ta clé NVIDIA (Réglages IA).', true); return; }
    localStorage.setItem('nv_key', nvKey); localStorage.setItem('nv_model', nvModel);
    busy[c.$id] = 'gen-quiz'; busy = { ...busy };
    try {
      const sys = `Tu es un professeur camerounais expert du programme MINESEC. Tu crées des quiz de révision.
RÉPONDS UNIQUEMENT avec un JSON STRICT, sans texte autour ni balise de code, au format EXACT :
{"questions":[{"q":"Énoncé ?","options":["A","B","C","D"],"answer":0,"explanation":"Pourquoi"}]}
- 5 questions à choix multiple, 4 options chacune.
- "answer" = index (0 = 1ʳᵉ option) de la bonne réponse.
- "explanation" : courte justification. Échappe correctement les antislashs.`;
      const out = await callNvidia([
        { role: 'system', content: sys },
        { role: 'user', content: ctx(c) + '\n\nGénère un quiz de 5 questions sur ce chapitre.' },
      ], 3000);
      let s = out.replace(/^```(?:json)?/i, '').replace(/```$/i, '').trim();
      const a = s.indexOf('{'); const b = s.lastIndexOf('}');
      if (a >= 0 && b > a) s = s.slice(a, b + 1);
      try { s = JSON.stringify(JSON.parse(s), null, 2); } catch { /* on laisse brut, l'admin corrige */ }
      quizBuf[c.$id] = s; quizBuf = { ...quizBuf };
      note('Quiz généré — vérifie puis enregistre.');
    } catch (e: any) { note('Génération quiz : ' + (e?.message || e), true); }
    finally { busy[c.$id] = ''; busy = { ...busy }; }
  }

  // ── Toast ─────────────────────────────────────────────────────────────────
  let toast = '';
  let toastBad = false;
  function note(m: string, bad = false) {
    toast = m; toastBad = bad;
    setTimeout(() => (toast = ''), 3000);
  }
</script>

<svelte:head><title>Atelier Cours — OnBuch</title></svelte:head>

<div class="wrap">
  <h1>📘 Atelier Cours</h1>
  <p class="sub">Crée un cours complet d'un seul endroit : choisis la matière, ajoute les chapitres,
    rédige (ou génère) la leçon et le quiz. Tout est relié automatiquement — aucun ID à copier.</p>

  <!-- 1. Matière -->
  <div class="card">
    <h2>1. Choisis la matière</h2>
    <div class="grid">
      <label>Examen
        <select bind:value={selExam} on:change={() => { selSerieName = ''; selMatiere = ''; onMatiereChange(); }}>
          <option value="">— choisir —</option>
          {#each exams as e}<option value={e}>{e}</option>{/each}
        </select>
      </label>
      <label>Série / filière
        <select bind:value={selSerieName} on:change={() => { selMatiere = ''; onMatiereChange(); }} disabled={!selExam}>
          <option value="">— choisir —</option>
          {#each seriesForExam as s}<option value={s.name}>{s.name}</option>{/each}
        </select>
      </label>
      <label>Matière
        <select bind:value={selMatiere} on:change={onMatiereChange} disabled={!selSerieName}>
          <option value="">— choisir —</option>
          {#each subjectsForSerie as m}<option value={m}>{m}</option>{/each}
        </select>
      </label>
      <label>Classe (auto)<input value={levels} readonly placeholder="déduit de l'examen" /></label>
    </div>
    <p class="hint">Les matières proposées sont celles de la série, gérées dans « Séries / filières » —
      exactement la même liste que les Ressources.</p>
  </div>

  <!-- 2. Pack -->
  {#if selMatiere}
    <div class="card">
      <h2>2. Le pack « {selMatiere} »</h2>
      {#if lookingUp}
        <p class="hint">Recherche du pack…</p>
      {:else if !pack}
        <p class="hint">Aucun pack n'existe encore pour cette matière. Règle puis crée-le :</p>
        <div class="grid">
          <label class="radio"><input type="checkbox" bind:checked={packForm.premium} /> Pack premium (payant)</label>
          {#if packForm.premium}
            <label>Prix (crédits)<input type="number" min="0" bind:value={packForm.priceCredits} /></label>
          {/if}
          <label>Coefficient<input type="number" min="0" bind:value={packForm.coef} /></label>
          <label>Chapitres en aperçu gratuit<input type="number" min="0" bind:value={packForm.freeChapters} /></label>
          <label>Série (track) — vide = toutes<input bind:value={packForm.track} placeholder="vide = toutes les séries" /></label>
        </div>
        <button class="primary" on:click={createPack} disabled={savingPack}>
          {savingPack ? 'Création…' : 'Créer le pack'}
        </button>
      {:else}
        <div class="packbar">
          <span class="ok">✓ Pack existant</span>
          <span class="muted">{chapters.length} chapitre{chapters.length > 1 ? 's' : ''}</span>
        </div>
        <div class="grid">
          <label class="radio"><input type="checkbox" bind:checked={packForm.premium} /> Pack premium (payant)</label>
          {#if packForm.premium}
            <label>Prix (crédits)<input type="number" min="0" bind:value={packForm.priceCredits} /></label>
          {/if}
          <label>Coefficient<input type="number" min="0" bind:value={packForm.coef} /></label>
          <label>Chapitres en aperçu gratuit<input type="number" min="0" bind:value={packForm.freeChapters} /></label>
          <label>Série (track) — vide = toutes<input bind:value={packForm.track} placeholder="vide = toutes les séries" /></label>
        </div>
        <button class="ghost" on:click={savePack} disabled={savingPack}>
          {savingPack ? 'Enregistrement…' : 'Enregistrer les réglages'}
        </button>
      {/if}
    </div>
  {/if}

  <!-- 3. Chapitres -->
  {#if pack}
    <div class="card">
      <h2>3. Chapitres, leçons & quiz</h2>

      <div class="addchap">
        <div class="grid">
          <label>Titre du chapitre<input bind:value={newChapTitle} placeholder="ex. La Guerre froide (1947-1991)" /></label>
          <label>Description (option)<input bind:value={newChapDesc} placeholder="" /></label>
          <label>Lien vidéo (option)<input bind:value={newChapVideo} placeholder="https://youtu.be/…" /></label>
        </div>
        <button class="primary" on:click={addChapter} disabled={addingChap}>
          {addingChap ? 'Ajout…' : '+ Ajouter le chapitre'}
        </button>
      </div>

      {#if chapters.length === 0}
        <p class="hint">Aucun chapitre pour l'instant — ajoute le premier ci-dessus.</p>
      {:else}
        {#each chapters as c (c.$id)}
          <div class="chap">
            <div class="chap-head">
              <button class="link" on:click={() => toggle(c)}>
                {expanded[c.$id] ? '▾' : '▸'} <span class="chap-no">{c.order}.</span> {c.title}
              </button>
              <button class="del" on:click={() => deleteChapter(c)}>Supprimer</button>
            </div>

            {#if expanded[c.$id]}
              <div class="chap-body">
                <!-- Méta chapitre -->
                <div class="grid">
                  <label>Titre<input bind:value={c.title} /></label>
                  <label>Lien vidéo<input bind:value={c.videoUrl} placeholder="https://…" /></label>
                </div>
                <label>Description<input bind:value={c.description} /></label>
                <button class="ghost sm" on:click={() => saveChapterMeta(c)}>Enregistrer le chapitre</button>

                <!-- Leçon -->
                <div class="block">
                  <div class="block-head">
                    <span class="tag" style="color:#1E9E63">📖 Leçon (Markdown)</span>
                    <span class="spacer"></span>
                    <button class="ai" on:click={() => genLesson(c)} disabled={busy[c.$id] === 'gen-lesson'}>
                      {busy[c.$id] === 'gen-lesson' ? '✨ Génération…' : '✨ Générer'}
                    </button>
                    <button class="save" on:click={() => saveLesson(c)} disabled={busy[c.$id] === 'lesson'}>💾 Enregistrer</button>
                  </div>
                  <div class="cols">
                    <textarea bind:value={lessonBuf[c.$id]} placeholder="## Introduction…"></textarea>
                    <div class="preview" use:tex={lessonBuf[c.$id] || ''}>{@html mdToHtml(lessonBuf[c.$id] || '*Aperçu de la leçon…*')}</div>
                  </div>
                </div>

                <!-- Quiz -->
                <div class="block">
                  <div class="block-head">
                    <span class="tag" style="color:#2D6CDF">❓ Quiz (JSON)</span>
                    <span class="spacer"></span>
                    <button class="ai" on:click={() => genQuiz(c)} disabled={busy[c.$id] === 'gen-quiz'}>
                      {busy[c.$id] === 'gen-quiz' ? '✨ Génération…' : '✨ Générer'}
                    </button>
                    <button class="ghost sm" on:click={() => insertQuizTemplate(c.$id)}>Modèle</button>
                    <button class="save" on:click={() => saveQuiz(c)} disabled={busy[c.$id] === 'quiz'}>💾 Enregistrer</button>
                  </div>
                  <div class="cols">
                    <textarea class="mono" bind:value={quizBuf[c.$id]} placeholder={QUIZ_TEMPLATE}></textarea>
                    <div class="preview">
                      {#if quizError(c.$id)}
                        <div class="qerr">⚠️ {quizError(c.$id)}</div>
                      {:else if parsedQuiz(c.$id).length === 0}
                        <span class="muted">Aperçu du quiz…</span>
                      {:else}
                        {#each parsedQuiz(c.$id) as q, qi}
                          <div class="qcard">
                            <div class="qq">{qi + 1}. {q.q}</div>
                            {#each q.options as opt, oi}
                              <div class="qopt" class:good={oi === q.answer}>
                                {oi === q.answer ? '✓' : '•'} {opt}
                              </div>
                            {/each}
                          </div>
                        {/each}
                      {/if}
                    </div>
                  </div>
                </div>
              </div>
            {/if}
          </div>
        {/each}
      {/if}
    </div>

    <!-- Réglages IA -->
    <div class="card">
      <details>
        <summary>⚙️ Réglages IA (clé NVIDIA)</summary>
        <div class="grid" style="margin-top:12px">
          <label>Clé API NVIDIA<input type="password" bind:value={nvKey} placeholder="nvapi-…" /></label>
          <label>Modèle<input bind:value={nvModel} /></label>
        </div>
        <p class="hint">La clé reste uniquement dans ce navigateur. La génération est optionnelle — tu peux tout rédiger à la main.</p>
      </details>
    </div>
  {/if}
</div>

{#if toast}<div class="toast" class:bad={toastBad}>{toast}</div>{/if}

<style>
  .wrap { max-width: 1000px; margin: 0 auto; padding: 4px 2px 60px; }
  h1 { font-size: 24px; margin: 0 0 4px; }
  .sub { color: #6b6256; margin: 0 0 18px; font-size: 13.5px; line-height: 1.5; }
  .card { background: var(--paper, #fff); border: 1.5px solid var(--line, #ece4d8); border-radius: 16px; padding: 18px; margin-bottom: 16px; }
  .card h2 { font-size: 15px; margin: 0 0 14px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  label { display: flex; flex-direction: column; font-size: 12.5px; font-weight: 600; color: #5a5145; gap: 5px; margin-bottom: 10px; }
  input, select, textarea { font: inherit; padding: 9px 11px; border: 1.5px solid #e3dccf; border-radius: 10px; background: #fffdfa; color: #241b12; }
  .radio { flex-direction: row; align-items: center; gap: 8px; }
  .radio input { width: auto; }
  .hint { font-size: 11.5px; color: #8a8073; margin: 6px 0 0; line-height: 1.45; }
  button { cursor: pointer; font: inherit; }
  button.primary { background: #F2620E; color: #fff; border: none; border-radius: 12px; padding: 11px 18px; font-weight: 800; }
  button.ghost { background: #fff; color: #b45a0c; border: 1.5px solid #f0d6bd; border-radius: 11px; padding: 9px 15px; font-weight: 700; }
  button.ghost.sm, button.save, button.ai { padding: 6px 11px; font-size: 12px; border-radius: 9px; }
  button.save { background: #eaf6ef; color: #1E9E63; border: none; font-weight: 700; }
  button.ai { background: #efe9fb; color: #6b4bd6; border: none; font-weight: 700; }
  button:disabled { opacity: .5; cursor: default; }
  .packbar { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
  .ok { color: #1E9E63; font-weight: 800; font-size: 13px; }
  .muted { color: #8a8073; font-weight: 500; font-size: 12.5px; }
  .addchap { border: 1.5px dashed #e6cdb2; border-radius: 12px; padding: 13px; margin-bottom: 16px; background: #fffaf4; }
  .chap { border: 1.5px solid #ece4d8; border-radius: 12px; margin-bottom: 12px; overflow: hidden; }
  .chap-head { display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 11px 13px; background: #fffdfa; }
  .link { background: none; border: none; font-weight: 700; color: #241b12; text-align: left; flex: 1; }
  .chap-no { color: #b45a0c; }
  .del { background: #fdecea; color: #c0392b; border: none; border-radius: 8px; padding: 6px 10px; font-weight: 700; font-size: 12px; }
  .chap-body { padding: 14px 13px; border-top: 1px solid #f0e9de; }
  .block { margin-top: 14px; border-top: 1px dashed #ece4d8; padding-top: 12px; }
  .block-head { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
  .block-head .spacer { flex: 1; }
  .tag { font-size: 12.5px; font-weight: 800; }
  .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
  textarea { width: 100%; min-height: 150px; resize: vertical; font-size: 13px; line-height: 1.45; }
  textarea.mono { font-family: 'JetBrains Mono', ui-monospace, monospace; font-size: 12px; }
  .preview { padding: 12px; background: #FFF8F1; border: 1px dashed #f0c9a6; border-radius: 10px; font-size: 13.5px; line-height: 1.55; overflow-x: auto; }
  .qerr { color: #c0392b; font-size: 12.5px; font-weight: 600; }
  .qcard { margin-bottom: 10px; }
  .qq { font-weight: 700; font-size: 13px; margin-bottom: 4px; }
  .qopt { font-size: 12.5px; padding: 2px 0 2px 4px; color: #5a5145; }
  .qopt.good { color: #1E9E63; font-weight: 700; }
  details summary { cursor: pointer; font-weight: 700; font-size: 13px; color: #b45a0c; }
  .toast { position: fixed; left: 50%; bottom: 26px; transform: translateX(-50%); background: #241B12; color: #ffe9d4; padding: 11px 20px; border-radius: 12px; font-size: 13.5px; font-weight: 600; box-shadow: 0 10px 30px rgba(0,0,0,.25); z-index: 80; }
  .toast.bad { background: #7a1f17; color: #ffd9d2; }
  @media (max-width: 760px) { .grid, .cols { grid-template-columns: 1fr; } }
</style>
