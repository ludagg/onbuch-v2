<script lang="ts">
  import { onMount } from 'svelte';
  import { databases, storage, RESULT_PDFS_BUCKET, ID, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';

  const COLLECTION = 'result_sources';

  let sources: any[] = [];
  let loading = true;
  let saving = false;
  let uploading = false;
  let toast = '';
  let toastBad = false;

  function flash(m: string, bad = false) {
    toast = m;
    toastBad = bad;
    setTimeout(() => (toast = ''), 3200);
  }

  // ── Formulaire (création / édition) ────────────────────────────────────────
  const blank = () => ({
    label: '',
    subtitle: '',
    icon: '🎓',
    sourceType: 'manual',
    examType: '',
    year: '',
    searchLabel: 'Numéro de table',
    searchHint: 'ex. 10428',
    searchMode: 'number',
    notFoundMessage: '',
    pdfUrl: '',
    pdfName: '',
    pdfFileId: '',
    apiUrl: '',
    order: 0,
    active: true
  });

  let form: ReturnType<typeof blank> = blank();
  let editingId: string | null = null;
  let drawer = false;

  async function fetchAll(): Promise<any[]> {
    const out: any[] = [];
    let offset = 0;
    while (true) {
      const res = await databases.listDocuments(APPWRITE_DATABASE, COLLECTION, [
        Query.limit(100),
        Query.offset(offset),
        Query.orderAsc('order')
      ]);
      out.push(...res.documents);
      if (res.documents.length < 100 || out.length >= 1000) break;
      offset += 100;
    }
    return out;
  }

  async function load() {
    loading = true;
    try {
      sources = await fetchAll();
    } catch (e: any) {
      flash(e?.message ?? 'Chargement impossible.', true);
      sources = [];
    } finally {
      loading = false;
    }
  }

  onMount(load);

  function openNew() {
    form = blank();
    editingId = null;
    drawer = true;
  }

  function openEdit(d: any) {
    form = {
      label: d.label ?? '',
      subtitle: d.subtitle ?? '',
      icon: d.icon || '🎓',
      sourceType: d.sourceType || 'manual',
      examType: d.examType ?? '',
      year: d.year ?? '',
      searchLabel: d.searchLabel || 'Numéro de table',
      searchHint: d.searchHint || 'ex. 10428',
      searchMode: d.searchMode || 'number',
      notFoundMessage: d.notFoundMessage ?? '',
      pdfUrl: d.pdfUrl ?? '',
      pdfName: d.pdfName ?? '',
      pdfFileId: d.pdfFileId ?? '',
      apiUrl: d.apiUrl ?? '',
      order: typeof d.order === 'number' ? d.order : Number(d.order) || 0,
      active: d.active !== false
    };
    editingId = d.$id;
    drawer = true;
  }

  function close() {
    drawer = false;
    editingId = null;
  }

  // Téléverse le PDF dans le bucket et renseigne l'URL de visualisation.
  async function onPdfPick(e: Event) {
    const input = e.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    uploading = true;
    try {
      const created = await storage.createFile(RESULT_PDFS_BUCKET, ID.unique(), file);
      // URL publique de visualisation (bucket en lecture publique).
      const url = storage.getFileView(RESULT_PDFS_BUCKET, created.$id).toString();
      // Remplace un éventuel ancien fichier.
      if (form.pdfFileId) {
        try { await storage.deleteFile(RESULT_PDFS_BUCKET, form.pdfFileId); } catch { /* ignore */ }
      }
      form.pdfUrl = url;
      form.pdfName = file.name;
      form.pdfFileId = created.$id;
      flash('PDF chargé ✓');
    } catch (err: any) {
      flash(err?.message ?? 'Échec du téléversement.', true);
    } finally {
      uploading = false;
      input.value = '';
    }
  }

  async function removePdf() {
    if (form.pdfFileId) {
      try { await storage.deleteFile(RESULT_PDFS_BUCKET, form.pdfFileId); } catch { /* ignore */ }
    }
    form.pdfUrl = '';
    form.pdfName = '';
    form.pdfFileId = '';
  }

  async function save() {
    if (!form.label.trim()) { flash('Le libellé est requis.', true); return; }
    if (form.sourceType === 'manual' && !form.examType.trim()) {
      flash('Le type « manuel » nécessite un type d’examen (clé exam_results).', true);
      return;
    }
    if (form.sourceType === 'pdf' && !form.pdfUrl.trim()) {
      flash('Charge un PDF pour ce type de source.', true);
      return;
    }
    if (form.sourceType === 'api' && !form.apiUrl.trim()) {
      flash('Renseigne l’URL de l’API.', true);
      return;
    }
    saving = true;
    const data = {
      label: form.label.trim(),
      subtitle: form.subtitle.trim(),
      icon: form.icon.trim() || '🎓',
      sourceType: form.sourceType,
      examType: form.examType.trim(),
      year: form.year.trim(),
      searchLabel: form.searchLabel.trim(),
      searchHint: form.searchHint.trim(),
      searchMode: form.searchMode,
      notFoundMessage: form.notFoundMessage.trim(),
      pdfUrl: form.pdfUrl.trim(),
      pdfName: form.pdfName.trim(),
      pdfFileId: form.pdfFileId.trim(),
      apiUrl: form.apiUrl.trim(),
      order: Number(form.order) || 0,
      active: !!form.active
    };
    try {
      if (editingId) {
        await databases.updateDocument(APPWRITE_DATABASE, COLLECTION, editingId, data);
      } else {
        await databases.createDocument(APPWRITE_DATABASE, COLLECTION, ID.unique(), data);
      }
      close();
      await load();
      flash('Enregistré ✓');
    } catch (e: any) {
      flash(e?.message ?? 'Échec de l’enregistrement.', true);
    } finally {
      saving = false;
    }
  }

  async function remove(d: any) {
    if (!confirm(`Supprimer « ${d.label} » ?`)) return;
    try {
      if (d.pdfFileId) {
        try { await storage.deleteFile(RESULT_PDFS_BUCKET, d.pdfFileId); } catch { /* ignore */ }
      }
      await databases.deleteDocument(APPWRITE_DATABASE, COLLECTION, d.$id);
      await load();
      flash('Supprimé');
    } catch (e: any) {
      flash(e?.message ?? 'Suppression impossible.', true);
    }
  }

  const typeLabel: Record<string, string> = { manual: 'Saisie manuelle', pdf: 'PDF', api: 'API externe' };
</script>

<header class="head">
  <div>
    <h1>🎓 Résultats — sources</h1>
    <p class="muted">{sources.length} source{sources.length > 1 ? 's' : ''} configurée{sources.length > 1 ? 's' : ''}</p>
  </div>
  <button class="btn-primary" on:click={openNew}>+ Nouvelle source</button>
</header>

<div class="card info">
  <p>Chaque source décrit comment les résultats d'un examen sont publiés. L'app affiche
    automatiquement les sources <strong>actives</strong>.</p>
  <ul>
    <li><strong>Saisie manuelle</strong> — les résultats sont saisis ligne par ligne (menu « Résultats d'examens »). Recherche instantanée par numéro.</li>
    <li><strong>PDF</strong> — tu charges le PDF officiel ; l'élève cherche son nom ou son numéro <em>dans</em> le document.</li>
    <li><strong>API externe</strong> — l'app interroge l'API que tu indiques (URL avec <code>{'{query}'}</code>).</li>
  </ul>
</div>

{#if loading}
  <div class="center"><div class="spinner"></div></div>
{:else if sources.length === 0}
  <div class="card empty">
    <div class="empty-ico">🎓</div>
    <p class="muted">Aucune source configurée. L'app utilise une liste par défaut tant que rien n'est créé.</p>
    <button class="btn-primary" on:click={openNew}>Créer la première</button>
  </div>
{:else}
  <div class="list">
    {#each sources as d (d.$id)}
      <div class="row card">
        <div class="row-ico">{d.icon || '🎓'}</div>
        <div class="row-main">
          <div class="row-title">
            {d.label || '(sans libellé)'}
            {#if d.active === false}<span class="badge off">masqué</span>{/if}
          </div>
          <div class="row-sub muted">
            <span class="badge type">{typeLabel[d.sourceType] ?? d.sourceType}</span>
            {#if d.subtitle}· {d.subtitle}{/if}
            {#if d.sourceType === 'pdf' && d.pdfName}· {d.pdfName}{/if}
            {#if d.sourceType === 'api' && d.apiUrl}· API{/if}
          </div>
        </div>
        <div class="row-actions">
          <button class="btn-ghost btn-sm" on:click={() => openEdit(d)}>Modifier</button>
          <button class="btn-danger btn-sm" on:click={() => remove(d)}>Suppr.</button>
        </div>
      </div>
    {/each}
  </div>
{/if}

{#if drawer}
  <div class="overlay" on:click={close} role="presentation"></div>
  <aside class="drawer">
    <div class="drawer-head">
      <h2>{editingId ? 'Modifier' : 'Nouvelle'} · source de résultats</h2>
      <button class="btn-ghost btn-sm" on:click={close}>Fermer</button>
    </div>
    <div class="drawer-body">
      <div class="field">
        <label for="f-label">Libellé affiché <span class="req">*</span></label>
        <input id="f-label" type="text" bind:value={form.label} placeholder="ex. Baccalauréat 2026" />
      </div>
      <div class="grid2">
        <div class="field">
          <label for="f-sub">Sous-titre</label>
          <input id="f-sub" type="text" bind:value={form.subtitle} placeholder="ex. Séries A–E · Session 2026" />
        </div>
        <div class="field">
          <label for="f-icon">Icône (emoji)</label>
          <input id="f-icon" type="text" bind:value={form.icon} placeholder="🎓" maxlength="4" />
        </div>
      </div>

      <div class="field">
        <label for="f-type">Mode de publication <span class="req">*</span></label>
        <select id="f-type" bind:value={form.sourceType}>
          <option value="manual">Saisie manuelle (exam_results)</option>
          <option value="pdf">PDF chargé (recherche dans le document)</option>
          <option value="api">API externe</option>
        </select>
      </div>

      {#if form.sourceType === 'manual'}
        <div class="field">
          <label for="f-exam">Type d'examen (clé) <span class="req">*</span></label>
          <input id="f-exam" type="text" bind:value={form.examType} placeholder="Baccalauréat, BEPC, GCE O Level…" />
          <div class="help muted">Doit correspondre EXACTEMENT au champ « Type d'examen » des lignes saisies dans « Résultats d'examens ».</div>
        </div>
      {/if}

      {#if form.sourceType === 'pdf'}
        <div class="field">
          <label>Document PDF des résultats <span class="req">*</span></label>
          {#if form.pdfUrl}
            <div class="pdf-row">
              <span class="pdf-name">📄 {form.pdfName || 'document.pdf'}</span>
              <a class="link-sm" href={form.pdfUrl} target="_blank" rel="noopener">Voir</a>
              <button type="button" class="btn-danger btn-sm" on:click={removePdf}>Retirer</button>
            </div>
          {/if}
          <label class="upload" class:busy={uploading}>
            <input type="file" accept="application/pdf" on:change={onPdfPick} hidden />
            {uploading ? 'Téléversement…' : (form.pdfUrl ? 'Remplacer le PDF' : 'Choisir un PDF')}
          </label>
          <div class="help muted">PDF texte (pas une image scannée). L'élève cherche son nom ou son numéro dedans.</div>
        </div>
      {/if}

      {#if form.sourceType === 'api'}
        <div class="field">
          <label for="f-api">URL de l'API <span class="req">*</span></label>
          <input id="f-api" type="text" bind:value={form.apiUrl} placeholder="https://api.exemple.cm/resultats?num={'{query}'}" />
          <div class="help muted">Utilise <code>{'{query}'}</code> à l'emplacement du numéro/nom saisi. Réponse JSON attendue (clés : candidateName/nom, admitted/admis, mention, average/moyenne…).</div>
        </div>
      {/if}

      <div class="sep">Champ de recherche</div>
      <div class="grid2">
        <div class="field">
          <label for="f-slabel">Libellé du champ</label>
          <input id="f-slabel" type="text" bind:value={form.searchLabel} placeholder="Numéro de table" />
        </div>
        <div class="field">
          <label for="f-smode">Recherche par</label>
          <select id="f-smode" bind:value={form.searchMode}>
            <option value="number">Numéro</option>
            <option value="name">Nom</option>
          </select>
        </div>
      </div>
      <div class="grid2">
        <div class="field">
          <label for="f-shint">Exemple (placeholder)</label>
          <input id="f-shint" type="text" bind:value={form.searchHint} placeholder="ex. 10428" />
        </div>
        <div class="field">
          <label for="f-year">Année</label>
          <input id="f-year" type="text" bind:value={form.year} placeholder="2026" />
        </div>
      </div>
      <div class="field">
        <label for="f-nf">Message « introuvable »</label>
        <input id="f-nf" type="text" bind:value={form.notFoundMessage} placeholder="Laisser vide pour le message par défaut" />
      </div>

      <div class="sep">Affichage</div>
      <div class="grid2">
        <div class="field">
          <label for="f-order">Ordre</label>
          <input id="f-order" type="number" bind:value={form.order} />
        </div>
        <div class="field">
          <label>Actif</label>
          <label class="switch"><input type="checkbox" bind:checked={form.active} /><span>{form.active ? 'Visible dans l’app' : 'Masqué'}</span></label>
        </div>
      </div>
    </div>
    <div class="drawer-foot">
      <button class="btn-ghost" on:click={close}>Annuler</button>
      <button class="btn-primary" on:click={save} disabled={saving || uploading}>{saving ? 'Enregistrement…' : 'Enregistrer'}</button>
    </div>
  </aside>
{/if}

{#if toast}<div class="toast" class:bad={toastBad}>{toast}</div>{/if}

<style>
  .head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; gap: 16px; }
  .head h1 { font-size: 24px; }
  .head p { margin: 5px 0 0; font-size: 13px; }
  .info { margin-bottom: 18px; font-size: 13px; }
  .info p { margin: 0 0 8px; }
  .info ul { margin: 0; padding-left: 18px; display: flex; flex-direction: column; gap: 4px; color: var(--ink2); }
  .info code { background: var(--panel); border-radius: 5px; padding: 1px 5px; font-size: 12px; }
  .center { display: flex; justify-content: center; padding: 60px; }
  .empty { text-align: center; padding: 40px; }
  .empty-ico { font-size: 38px; margin-bottom: 8px; }
  .empty p { margin: 0 0 16px; }
  .list { display: flex; flex-direction: column; gap: 10px; }
  .row { display: flex; align-items: center; gap: 14px; padding: 13px 16px; }
  .row-ico { width: 40px; height: 40px; border-radius: 11px; background: var(--o50); display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; }
  .row-main { flex: 1; min-width: 0; }
  .row-title { font-weight: 700; font-size: 14.5px; display: flex; align-items: center; gap: 8px; }
  .row-sub { font-size: 12.5px; margin-top: 3px; display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
  .row-actions { display: flex; gap: 8px; flex-shrink: 0; }
  .badge { font-size: 10.5px; font-weight: 800; border-radius: 6px; padding: 2px 7px; }
  .badge.type { color: var(--o700); background: var(--o50); }
  .badge.off { color: #9a5b3a; background: #fbefe4; }

  .overlay { position: fixed; inset: 0; background: rgba(20, 15, 11, 0.4); z-index: 40; }
  .drawer { position: fixed; top: 0; right: 0; bottom: 0; width: 460px; max-width: 94vw; background: var(--bg); z-index: 50; display: flex; flex-direction: column; box-shadow: -16px 0 40px rgba(20, 15, 11, 0.18); }
  .drawer-head, .drawer-foot { padding: 16px 20px; display: flex; align-items: center; justify-content: space-between; background: var(--paper); }
  .drawer-head { border-bottom: 1.5px solid var(--line); }
  .drawer-head h2 { font-size: 16px; }
  .drawer-foot { border-top: 1.5px solid var(--line); gap: 10px; }
  .drawer-body { flex: 1; overflow-y: auto; padding: 20px; }
  .field { margin-bottom: 15px; }
  .field > label { display: block; font-weight: 700; font-size: 13px; margin-bottom: 6px; }
  .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .req { color: var(--bad); }
  .help { font-size: 11.5px; margin-top: 5px; }
  .help code { background: var(--panel); border-radius: 5px; padding: 1px 5px; }
  .sep { font-size: 11px; font-weight: 800; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; margin: 20px 0 12px; border-top: 1.5px solid var(--line); padding-top: 14px; }
  .switch { display: flex; align-items: center; gap: 9px; font-weight: 600; color: var(--ink2); }
  .switch input { width: auto; }
  .upload { display: inline-flex; align-items: center; justify-content: center; padding: 9px 14px; border-radius: 11px; border: 1.5px dashed var(--o500); color: var(--o700); background: var(--o50); font-weight: 700; font-size: 13px; cursor: pointer; }
  .upload.busy { opacity: 0.6; pointer-events: none; }
  .pdf-row { display: flex; align-items: center; gap: 10px; margin-bottom: 9px; flex-wrap: wrap; }
  .pdf-name { font-weight: 600; font-size: 13px; }
  .link-sm { color: var(--o600); font-weight: 700; font-size: 12.5px; }
</style>
