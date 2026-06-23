<script lang="ts">
  import { onMount } from 'svelte';
  import { databases, ID, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';

  type Fil = { name: string; subjects: string[] };

  let series: any[] = [];
  let annales: any[] = [];
  let loading = true;
  let saving = false;
  let toast = '';
  let toastBad = false;

  // ── Formulaire ──────────────────────────────────────────────────────────
  let exam = '';
  let lastExam = '';
  let selFil: string[] = [];
  let selSubj: string[] = [];
  let category = 'Épreuve';
  let title = '';
  let year = '';
  let session = '';
  let fileUrl = '';
  let corrigeUrl = '';
  let videoUrl = '';
  let premium = false;

  function flash(m: string, bad = false) {
    toast = m;
    toastBad = bad;
    setTimeout(() => (toast = ''), 3000);
  }

  function splitCsv(v: any): string[] {
    return String(v ?? '').split(',').map((s) => s.trim()).filter(Boolean);
  }

  async function fetchAll(col: string, baseQ: any[] = []): Promise<any[]> {
    const out: any[] = [];
    let offset = 0;
    while (true) {
      const res = await databases.listDocuments(APPWRITE_DATABASE, col, [...baseQ, Query.limit(100), Query.offset(offset)]);
      out.push(...res.documents);
      if (res.documents.length < 100 || out.length >= 2000) break;
      offset += 100;
    }
    return out;
  }

  // Pagination + recherche (12k+ documents → on ne charge jamais tout).
  const PAGE = 20;
  let pageIndex = 0;
  let total = 0;
  let search = '';
  let searchTerm = '';
  const SEARCH_FIELDS = ['title', 'subject', 'track', 'year'];
  $: pageCount = Math.max(1, Math.ceil(total / PAGE));

  async function loadAnnales() {
    loading = true;
    try {
      const q: any[] = [Query.orderDesc('$createdAt'), Query.limit(PAGE), Query.offset(pageIndex * PAGE)];
      if (searchTerm) q.push(Query.or(SEARCH_FIELDS.map((f) => Query.contains(f, searchTerm))));
      const res = await databases.listDocuments(APPWRITE_DATABASE, 'annales', q);
      annales = res.documents;
      total = res.total;
    } catch (e: any) {
      flash(e?.message ?? 'Chargement impossible.', true);
    } finally {
      loading = false;
    }
  }

  function applySearch() { searchTerm = search.trim(); pageIndex = 0; loadAnnales(); }
  function clearSearch() { search = ''; searchTerm = ''; pageIndex = 0; loadAnnales(); }
  function goPage(d: number) { const ni = pageIndex + d; if (ni >= 0 && ni * PAGE < total) { pageIndex = ni; loadAnnales(); } }

  onMount(async () => {
    try {
      series = await fetchAll('exam_series', [Query.orderAsc('sortOrder')]);
    } catch (e: any) {
      flash(e?.message ?? 'Chargement des séries impossible.', true);
    }
    await loadAnnales();
  });

  // Arbre : examen -> subdivision -> [filières {name, subjects}]
  $: byExam = (() => {
    const m: Record<string, Record<string, Fil[]>> = {};
    for (const d of series) {
      const ex = (d.exam ?? '').toString();
      if (!ex) continue;
      (m[ex] ??= {});
      const sub = (d.category ?? '').toString();
      (m[ex][sub] ??= []).push({ name: (d.name ?? '').toString(), subjects: splitCsv(d.subjects) });
    }
    return m;
  })();
  $: exams = Object.keys(byExam);

  // Reset des sélections quand l'examen change.
  $: if (exam !== lastExam) {
    lastExam = exam;
    selFil = [];
    selSubj = [];
  }

  // Toutes les filières de l'examen courant (à plat).
  $: filObjs = (() => {
    const all: Fil[] = [];
    for (const sub of Object.values(byExam[exam] ?? {})) all.push(...sub);
    return all;
  })();

  // Matières disponibles = union des matières des filières sélectionnées.
  $: availSubjects = (() => {
    const set = new Set<string>();
    for (const f of filObjs) if (selFil.includes(f.name)) f.subjects.forEach((s) => set.add(s));
    return [...set];
  })();

  function toggle(arr: string[], v: string): string[] {
    return arr.includes(v) ? arr.filter((x) => x !== v) : [...arr, v];
  }

  function toggleAllFil(fils: Fil[]) {
    const names = fils.map((f) => f.name);
    const allOn = names.every((n) => selFil.includes(n));
    selFil = allOn ? selFil.filter((n) => !names.includes(n)) : [...new Set([...selFil, ...names])];
  }

  // Aperçu : combien de documents seront créés (filière × matière compatibles).
  $: previewCount = (() => {
    let c = 0;
    for (const f of filObjs) {
      if (!selFil.includes(f.name)) continue;
      for (const s of selSubj) if (f.subjects.includes(s)) c++;
    }
    return c;
  })();

  async function save() {
    if (!exam || selFil.length === 0 || selSubj.length === 0 || !title.trim()) {
      flash('Examen, filière(s), matière(s) et titre sont requis.', true);
      return;
    }
    if (!fileUrl.trim() && !corrigeUrl.trim() && !videoUrl.trim()) {
      flash('Ajoute au moins un lien : PDF, corrigé ou vidéo.', true);
      return;
    }
    saving = true;
    let created = 0;
    try {
      for (const f of filObjs) {
        if (!selFil.includes(f.name)) continue;
        for (const subj of selSubj) {
          if (!f.subjects.includes(subj)) continue; // n'attache qu'aux filières qui ont la matière
          await databases.createDocument(APPWRITE_DATABASE, 'annales', ID.unique(), {
            exam,
            track: f.name,
            subject: subj,
            category,
            year: year.trim(),
            session: session.trim(),
            title: title.trim(),
            fileUrl: fileUrl.trim(),
            corrigeUrl: corrigeUrl.trim(),
            videoUrl: videoUrl.trim(),
            premium,
            order: 0
          });
          created++;
        }
      }
      flash(`${created} document${created > 1 ? 's' : ''} publié${created > 1 ? 's' : ''} ✓`);
      // Réinitialise le contenu (garde l'examen + sélections pour enchaîner).
      title = '';
      year = '';
      session = '';
      fileUrl = '';
      corrigeUrl = '';
      videoUrl = '';
      premium = false;
      await loadAnnales();
    } catch (e: any) {
      flash(e?.message ?? 'Échec de la publication.', true);
    } finally {
      saving = false;
    }
  }

  // ── Édition d'un document existant ────────────────────────────────────────
  let editDoc: any = null;
  let ed = { exam: '', track: '', subject: '', category: 'Épreuve', year: '', session: '', title: '', fileUrl: '', corrigeUrl: '', videoUrl: '', premium: false };

  function openEdit(d: any) {
    editDoc = d;
    ed = {
      exam: (d.exam ?? '').toString(),
      track: (d.track ?? '').toString(),
      subject: (d.subject ?? '').toString(),
      category: (d.category ?? 'Épreuve').toString(),
      year: (d.year ?? '').toString(),
      session: (d.session ?? '').toString(),
      title: (d.title ?? '').toString(),
      fileUrl: (d.fileUrl ?? '').toString(),
      corrigeUrl: (d.corrigeUrl ?? '').toString(),
      videoUrl: (d.videoUrl ?? '').toString(),
      premium: !!d.premium
    };
  }
  function closeEdit() { editDoc = null; }

  async function saveEdit() {
    if (!ed.subject.trim() || !ed.title.trim()) { flash('Matière et titre requis.', true); return; }
    saving = true;
    try {
      await databases.updateDocument(APPWRITE_DATABASE, 'annales', editDoc.$id, {
        exam: ed.exam,
        track: ed.track.trim(),
        subject: ed.subject.trim(),
        category: ed.category,
        year: ed.year.trim(),
        session: ed.session.trim(),
        title: ed.title.trim(),
        fileUrl: ed.fileUrl.trim(),
        corrigeUrl: ed.corrigeUrl.trim(),
        videoUrl: ed.videoUrl.trim(),
        premium: ed.premium
      });
      closeEdit();
      await loadAnnales();
      flash('Document modifié ✓');
    } catch (e: any) {
      flash(e?.message ?? 'Échec de la modification.', true);
    } finally {
      saving = false;
    }
  }

  async function del(d: any) {
    if (!confirm('Supprimer ce document ?')) return;
    try {
      await databases.deleteDocument(APPWRITE_DATABASE, 'annales', d.$id);
      await loadAnnales();
      flash('Supprimé');
    } catch (e: any) {
      flash(e?.message ?? 'Suppression impossible.', true);
    }
  }

  // Suggestions pour l'édition (filières/matières de l'examen du document édité).
  $: edFilOptions = (() => {
    const s = new Set<string>();
    for (const sub of Object.values(byExam[ed.exam] ?? {})) for (const f of sub) s.add(f.name);
    return [...s];
  })();
  $: edSubjOptions = (() => {
    const s = new Set<string>();
    for (const sub of Object.values(byExam[ed.exam] ?? {})) for (const f of sub) f.subjects.forEach((x) => s.add(x));
    return [...s];
  })();

  function formats(d: any): string[] {
    return [
      ...(String(d.fileUrl ?? '').trim() ? ['PDF'] : []),
      ...(String(d.corrigeUrl ?? '').trim() ? ['Corrigé'] : []),
      ...(String(d.videoUrl ?? '').trim() ? ['Vidéo'] : [])
    ];
  }
</script>

<header class="head">
  <div>
    <h1>🗂️ Annales & documents</h1>
    <p class="muted">
      {total} document{total > 1 ? 's' : ''} publié{total > 1 ? 's' : ''}{searchTerm ? ` · recherche « ${searchTerm} »` : ''}
    </p>
  </div>
</header>

{#if loading}
  <div class="center"><div class="spinner"></div></div>
{:else}
  <!-- Formulaire d'ajout -->
  <div class="card form">
    <h2>Publier un document</h2>
    <p class="muted small">Choisis l'examen, une ou plusieurs filières, puis les matières — le document est publié pour toutes les combinaisons d'un coup.</p>

    <div class="field">
      <label for="exam">Examen</label>
      <select id="exam" bind:value={exam}>
        <option value="">— Choisir un examen —</option>
        {#each exams as ex}<option value={ex}>{ex}</option>{/each}
      </select>
    </div>

    {#if exam}
      <div class="field">
        <label>Filière(s) / série(s)</label>
        {#each Object.entries(byExam[exam] ?? {}) as [sub, fils]}
          <div class="grp-row">
            {#if sub}<span class="grp">{sub}</span>{/if}
            <button type="button" class="link-sm" on:click={() => toggleAllFil(fils)}>tout</button>
          </div>
          <div class="picks">
            {#each fils as f}
              <button type="button" class="pick" class:on={selFil.includes(f.name)} on:click={() => (selFil = toggle(selFil, f.name))}>
                {f.name}
              </button>
            {/each}
          </div>
        {/each}
      </div>

      <div class="field">
        <label>Matière(s)</label>
        {#if availSubjects.length}
          <div class="picks">
            <button type="button" class="pick alt" on:click={() => (selSubj = selSubj.length === availSubjects.length ? [] : [...availSubjects])}>
              {selSubj.length === availSubjects.length ? 'Aucune' : 'Toutes'}
            </button>
            {#each availSubjects as s}
              <button type="button" class="pick" class:on={selSubj.includes(s)} on:click={() => (selSubj = toggle(selSubj, s))}>{s}</button>
            {/each}
          </div>
        {:else}
          <p class="muted small">Sélectionne d'abord une ou plusieurs filières.</p>
        {/if}
      </div>
    {/if}

    <div class="grid2">
      <div class="field">
        <label for="cat">Type de document</label>
        <select id="cat" bind:value={category}>
          {#each ['Épreuve', 'Cours', 'Fiche de révision', 'TD', 'Autre'] as c}<option value={c}>{c}</option>{/each}
        </select>
      </div>
      <div class="field">
        <label for="year">Année</label>
        <input id="year" type="text" bind:value={year} placeholder="ex. 2024" />
      </div>
    </div>

    <div class="grid2">
      <div class="field">
        <label for="title">Titre</label>
        <input id="title" type="text" bind:value={title} placeholder="ex. Bac D — Mathématiques 2024" />
      </div>
      <div class="field">
        <label for="session">Session</label>
        <input id="session" type="text" bind:value={session} placeholder="ex. Session normale" />
      </div>
    </div>

    <div class="field">
      <label for="pdf">Document principal (PDF)</label>
      <input id="pdf" type="text" bind:value={fileUrl} placeholder="Lien PDF (sujet / cours / fiche)" />
    </div>
    <div class="grid2">
      <div class="field">
        <label for="cor">Corrigé (PDF) — facultatif</label>
        <input id="cor" type="text" bind:value={corrigeUrl} placeholder="Lien du corrigé" />
      </div>
      <div class="field">
        <label for="vid">Vidéo corrigée — facultatif</label>
        <input id="vid" type="text" bind:value={videoUrl} placeholder="Lien YouTube / MP4" />
      </div>
    </div>

    <label class="switch">
      <input type="checkbox" bind:checked={premium} />
      <span>{premium ? 'Premium (payant)' : 'Gratuit'}</span>
    </label>

    <div class="form-foot">
      <span class="muted small">
        {#if previewCount > 0}{previewCount} document{previewCount > 1 ? 's' : ''} seront créés{:else}Sélectionne filières + matières{/if}
      </span>
      <button class="btn-primary" on:click={save} disabled={saving || previewCount === 0}>
        {saving ? 'Publication…' : 'Publier'}
      </button>
    </div>
  </div>

  <!-- Documents existants : recherche + liste paginée -->
  <div class="searchbar">
    <input
      type="search"
      placeholder="Rechercher (titre, matière, série, année)…"
      bind:value={search}
      on:keydown={(e) => e.key === 'Enter' && applySearch()}
    />
    <button class="btn-primary btn-sm" on:click={applySearch}>Rechercher</button>
    {#if searchTerm}<button class="btn-ghost btn-sm" on:click={clearSearch}>Effacer</button>{/if}
  </div>

  {#if annales.length === 0}
    <div class="card empty">
      <p class="muted">{searchTerm ? `Aucun résultat pour « ${searchTerm} ».` : 'Aucun document publié pour le moment.'}</p>
    </div>
  {:else}
    <div class="rows">
      {#each annales as d (d.$id)}
        <div class="doc">
          <div class="doc-main">
            <div class="doc-title">{d.title || '(sans titre)'}</div>
            <div class="doc-sub muted">
              {d.exam}{d.track ? ' · ' + d.track : ''} · {d.subject}{d.year ? ' · ' + d.year : ''}{d.category ? ' · ' + d.category : ''}
            </div>
            <div class="badges">
              {#each formats(d) as f}<span class="badge">{f}</span>{/each}
              {#if d.premium}<span class="badge prem">PREMIUM</span>{/if}
            </div>
          </div>
          <div class="doc-acts">
            <button class="btn-ghost btn-sm" on:click={() => openEdit(d)}>Modifier</button>
            <button class="btn-danger btn-sm" on:click={() => del(d)}>Suppr.</button>
          </div>
        </div>
      {/each}
    </div>
    {#if total > PAGE}
      <div class="pager">
        <button class="btn-ghost btn-sm" disabled={pageIndex === 0} on:click={() => goPage(-1)}>← Précédent</button>
        <span class="muted">Page {pageIndex + 1} / {pageCount}</span>
        <button class="btn-ghost btn-sm" disabled={(pageIndex + 1) * PAGE >= total} on:click={() => goPage(1)}>Suivant →</button>
      </div>
    {/if}
  {/if}
{/if}

<!-- Tiroir d'édition d'un document -->
{#if editDoc}
  <div class="overlay" on:click={closeEdit} role="presentation"></div>
  <aside class="drawer">
    <div class="drawer-head">
      <h2>Modifier le document</h2>
      <button class="btn-ghost btn-sm" on:click={closeEdit}>Fermer</button>
    </div>
    <div class="drawer-body">
      <div class="field">
        <label for="e-exam">Examen</label>
        <select id="e-exam" bind:value={ed.exam}>
          {#each exams as ex}<option value={ex}>{ex}</option>{/each}
        </select>
      </div>
      <div class="field">
        <label for="e-track">Série / filière</label>
        <input id="e-track" type="text" list="ed-fils" bind:value={ed.track} placeholder="ex. D — ou vide = toutes séries" />
        <datalist id="ed-fils">{#each edFilOptions as f}<option value={f}></option>{/each}</datalist>
      </div>
      <div class="field">
        <label for="e-subject">Matière</label>
        <input id="e-subject" type="text" list="ed-subjs" bind:value={ed.subject} />
        <datalist id="ed-subjs">{#each edSubjOptions as s}<option value={s}></option>{/each}</datalist>
      </div>
      <div class="field">
        <label for="e-cat">Type de document</label>
        <select id="e-cat" bind:value={ed.category}>
          {#each ['Épreuve', 'Cours', 'Fiche de révision', 'TD', 'Autre'] as c}<option value={c}>{c}</option>{/each}
        </select>
      </div>
      <div class="grid2">
        <div class="field"><label for="e-year">Année</label><input id="e-year" type="text" bind:value={ed.year} /></div>
        <div class="field"><label for="e-session">Session</label><input id="e-session" type="text" bind:value={ed.session} /></div>
      </div>
      <div class="field"><label for="e-title">Titre</label><input id="e-title" type="text" bind:value={ed.title} /></div>
      <div class="field"><label for="e-pdf">Document principal (PDF)</label><input id="e-pdf" type="text" bind:value={ed.fileUrl} /></div>
      <div class="field"><label for="e-cor">Corrigé (PDF)</label><input id="e-cor" type="text" bind:value={ed.corrigeUrl} /></div>
      <div class="field"><label for="e-vid">Vidéo corrigée</label><input id="e-vid" type="text" bind:value={ed.videoUrl} /></div>
      <label class="switch"><input type="checkbox" bind:checked={ed.premium} /><span>{ed.premium ? 'Premium' : 'Gratuit'}</span></label>
    </div>
    <div class="drawer-foot">
      <button class="btn-ghost" on:click={closeEdit}>Annuler</button>
      <button class="btn-primary" on:click={saveEdit} disabled={saving}>{saving ? 'Enregistrement…' : 'Enregistrer'}</button>
    </div>
  </aside>
{/if}

{#if toast}<div class="toast" class:bad={toastBad}>{toast}</div>{/if}

<style>
  .head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 22px; }
  .head h1 { font-size: 24px; }
  .head p { margin: 5px 0 0; font-size: 13px; }
  .center { display: flex; justify-content: center; padding: 60px; }
  .small { font-size: 12px; }
  .form { margin-bottom: 22px; }
  .form h2 { font-size: 16px; margin-bottom: 4px; }
  .field { margin: 14px 0; }
  .field > label { display: block; font-weight: 700; font-size: 13px; margin-bottom: 7px; }
  .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .grp-row { display: flex; align-items: center; gap: 8px; margin: 10px 0 6px; }
  .grp { font-size: 11.5px; font-weight: 800; color: var(--muted); text-transform: uppercase; letter-spacing: 0.03em; }
  .link-sm { background: none; border: none; color: var(--o600); font-weight: 700; font-size: 11.5px; cursor: pointer; padding: 0; }
  .picks { display: flex; flex-wrap: wrap; gap: 8px; }
  .pick {
    padding: 7px 13px; border-radius: 999px; cursor: pointer;
    background: var(--paper); border: 1.5px solid var(--line2); color: var(--ink2);
    font-weight: 700; font-size: 12.5px;
  }
  .pick:hover { border-color: var(--o500); }
  .pick.on { background: var(--o50); border-color: var(--o500); color: var(--o700); }
  .pick.alt { background: var(--panel); }
  .switch { display: flex; align-items: center; gap: 9px; font-weight: 600; color: var(--ink2); margin-top: 12px; }
  .switch input { width: auto; }
  .form-foot { display: flex; align-items: center; justify-content: space-between; gap: 14px; margin-top: 18px; border-top: 1.5px solid var(--line); padding-top: 14px; }

  .searchbar { display: flex; gap: 10px; align-items: center; margin-bottom: 14px; }
  .searchbar input { flex: 1; }
  .pager { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 16px; font-size: 13px; }
  .rows { padding: 0; display: flex; flex-direction: column; gap: 8px; }
  .empty { text-align: center; padding: 30px; }
  .doc { display: flex; align-items: center; gap: 12px; padding: 11px 12px; background: var(--bg); border: 1px solid var(--line); border-radius: 11px; }
  .doc-main { flex: 1; min-width: 0; }
  .doc-acts { display: flex; gap: 8px; flex-shrink: 0; }
  .doc-title { font-weight: 700; font-size: 13.5px; }
  .doc-sub { font-size: 12px; margin-top: 2px; }
  .badges { display: flex; flex-wrap: wrap; gap: 5px; margin-top: 6px; }
  .badge { font-size: 10px; font-weight: 800; color: var(--ink2); background: var(--panel); border-radius: 6px; padding: 2px 7px; }
  .badge.prem { color: #a6701a; background: #fbf0dd; }

  .overlay { position: fixed; inset: 0; background: rgba(20, 15, 11, 0.4); z-index: 40; }
  .drawer { position: fixed; top: 0; right: 0; bottom: 0; width: 440px; max-width: 92vw; background: var(--bg); z-index: 50; display: flex; flex-direction: column; box-shadow: -16px 0 40px rgba(20, 15, 11, 0.18); }
  .drawer-head, .drawer-foot { padding: 16px 20px; display: flex; align-items: center; justify-content: space-between; background: var(--paper); }
  .drawer-head { border-bottom: 1.5px solid var(--line); }
  .drawer-head h2 { font-size: 16px; }
  .drawer-foot { border-top: 1.5px solid var(--line); gap: 10px; }
  .drawer-body { flex: 1; overflow-y: auto; padding: 20px; }
</style>
