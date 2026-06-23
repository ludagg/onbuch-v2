<script lang="ts">
  import { page } from '$app/stores';
  import { databases, functions, ADMIN_FUNCTION_ID, ID, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';
  import { resourceById, type Resource, type Field } from '$lib/schema';

  let resource: Resource | undefined;
  let docs: any[] = [];
  let loading = true;
  let error = '';

  let editing: Record<string, any> | null = null; // formulaire ouvert
  let editingId: string | null = null; // null = création
  let saving = false;
  let toast = '';
  let toastBad = false;

  // Pagination + recherche (évite de tout charger → plus de plantage).
  const PAGE = 20;
  let pageIndex = 0;
  let total = 0;
  let search = '';
  let searchTerm = '';

  let loadedId = '';
  $: resource = resourceById($page.params.id);
  $: searchableFields = resource
    ? (resource.searchFields ?? [resource.titleField, resource.subtitleField].filter(Boolean) as string[])
    : [];
  $: canSearch = !!resource && !resource.tree && searchableFields.length > 0;
  $: pageCount = Math.max(1, Math.ceil(total / PAGE));
  $: if (resource && resource.id !== loadedId) {
    loadedId = resource.id;
    pageIndex = 0;
    search = '';
    searchTerm = '';
    load();
  }

  function flash(msg: string, bad = false) {
    toast = msg;
    toastBad = bad;
    setTimeout(() => (toast = ''), 2600);
  }

  function orderQ() {
    if (!resource?.orderBy) return null;
    return resource.orderBy.dir === 'desc'
      ? Query.orderDesc(resource.orderBy.field)
      : Query.orderAsc(resource.orderBy.field);
  }

  async function load() {
    if (!resource) return;
    loading = true;
    error = '';
    try {
      if (resource.tree) {
        // Arbre (séries/filières) : petite collection → on charge tout.
        const all: any[] = [];
        let offset = 0;
        while (true) {
          const q = [Query.limit(100), Query.offset(offset)];
          const o = orderQ();
          if (o) q.push(o);
          const res = await databases.listDocuments(APPWRITE_DATABASE, resource.collectionId, q);
          all.push(...res.documents);
          if (res.documents.length < 100 || offset > 5000) break;
          offset += 100;
        }
        docs = all;
        total = all.length;
      } else {
        // Liste plate : une page à la fois (+ recherche substring sans index).
        const q: any[] = [Query.limit(PAGE), Query.offset(pageIndex * PAGE)];
        const o = orderQ();
        if (o) q.push(o);
        if (searchTerm && searchableFields.length) {
          const conds = searchableFields.map((f) => Query.contains(f, searchTerm));
          q.push(conds.length > 1 ? Query.or(conds) : conds[0]);
        }
        const res = await databases.listDocuments(APPWRITE_DATABASE, resource.collectionId, q);
        docs = res.documents;
        total = res.total;
      }
    } catch (e: any) {
      error = e?.message ?? 'Chargement impossible.';
      docs = [];
    } finally {
      loading = false;
    }
  }

  function applySearch() {
    searchTerm = search.trim();
    pageIndex = 0;
    load();
  }
  function clearSearch() {
    search = '';
    searchTerm = '';
    pageIndex = 0;
    load();
  }
  function goPage(delta: number) {
    const ni = pageIndex + delta;
    if (ni >= 0 && ni * PAGE < total) {
      pageIndex = ni;
      load();
    }
  }

  function pad(n: number) {
    return String(n).padStart(2, '0');
  }
  function toLocalInput(iso?: string): string {
    if (!iso) return '';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '';
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  function openNew() {
    if (!resource) return;
    const f: Record<string, any> = {};
    for (const field of resource.fields) f[field.key] = field.type === 'boolean' ? false : '';
    editing = f;
    editingId = null;
  }

  function openEdit(doc: any) {
    if (!resource) return;
    const f: Record<string, any> = {};
    for (const field of resource.fields) {
      const v = doc[field.key];
      if (field.type === 'boolean') f[field.key] = !!v;
      else if (field.type === 'datetime') f[field.key] = toLocalInput(v);
      else f[field.key] = v ?? '';
    }
    editing = f;
    editingId = doc.$id;
  }

  function close() {
    editing = null;
    editingId = null;
  }

  function buildPayload(fields: Field[], form: Record<string, any>) {
    const data: Record<string, any> = {};
    for (const f of fields) {
      const v = form[f.key];
      if (f.type === 'number') {
        if (v !== '' && v != null) data[f.key] = Number(v);
      } else if (f.type === 'datetime') {
        if (v) data[f.key] = new Date(v).toISOString();
      } else if (f.type === 'boolean') {
        data[f.key] = !!v;
      } else {
        data[f.key] = v ?? '';
      }
    }
    return data;
  }

  async function save() {
    if (!resource || !editing) return;
    for (const f of resource.fields) {
      if (f.required && !String(editing[f.key] ?? '').trim()) {
        flash(`Le champ « ${f.label} » est requis.`, true);
        return;
      }
    }
    saving = true;
    try {
      const data = buildPayload(resource.fields, editing);
      if (editingId) {
        await databases.updateDocument(APPWRITE_DATABASE, resource.collectionId, editingId, data);
      } else if (resource.idField) {
        // ID métier (ex. chapterId) : crée le doc avec cet ID, ou remplace la
        // version existante (souvent générée par l'IA) si elle existe déjà.
        const docId = String(editing[resource.idField] ?? '').trim();
        if (!docId) { flash('L’ID du document est requis.', true); saving = false; return; }
        try {
          await databases.createDocument(APPWRITE_DATABASE, resource.collectionId, docId, data);
        } catch (err: any) {
          if (err?.code === 409) {
            await databases.updateDocument(APPWRITE_DATABASE, resource.collectionId, docId, data);
          } else {
            throw err;
          }
        }
      } else {
        await databases.createDocument(APPWRITE_DATABASE, resource.collectionId, ID.unique(), data);
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

  async function remove(doc: any) {
    if (!resource) return;
    if (!confirm('Supprimer définitivement cet élément ?')) return;
    try {
      await databases.deleteDocument(APPWRITE_DATABASE, resource.collectionId, doc.$id);
      await load();
      flash('Supprimé');
    } catch (e: any) {
      flash(e?.message ?? 'Suppression impossible.', true);
    }
  }

  let busyId = '';
  // Actions sur le COMPTE Auth (bloquer / débloquer / supprimer), via la
  // fonction serveur « ops » qui vérifie que l'appelant est admin.
  async function accountAction(action: 'block' | 'unblock' | 'delete', doc: any) {
    if (action === 'delete' && !confirm('Supprimer DÉFINITIVEMENT ce compte et son profil ? Action irréversible.')) return;
    if (action === 'block' && !confirm('Bloquer ce compte ? L’utilisateur ne pourra plus se connecter.')) return;
    busyId = doc.$id;
    try {
      const exec = await functions.createExecution(
        ADMIN_FUNCTION_ID,
        JSON.stringify({ action, userId: doc.$id }),
        false
      );
      let body: any = {};
      try { body = JSON.parse(exec.responseBody || '{}'); } catch { /* ignore */ }
      if (!body.ok) {
        flash(body.error ?? 'Action refusée.', true);
        return;
      }
      if (action === 'delete') {
        await load();
        flash('Compte supprimé ✓');
      } else {
        flash(action === 'block' ? 'Compte bloqué ✓' : 'Compte débloqué ✓');
      }
    } catch (e: any) {
      flash(e?.message ?? 'Action impossible.', true);
    } finally {
      busyId = '';
    }
  }

  // Crédits Tuteur : ajoute (ou retire) des crédits au solde de l'utilisateur,
  // via la même fonction serveur « ops » (seule habilitée à écrire tutor_quota).
  async function addCredits(doc: any) {
    const raw = prompt(`Crédits à ajouter à ${title(doc)} ?\n(nombre négatif pour en retirer)`, '10');
    if (raw === null) return;
    const amount = Math.trunc(Number(raw.trim().replace(',', '.')));
    if (!Number.isFinite(amount) || amount === 0) {
      flash('Montant invalide.', true);
      return;
    }
    busyId = doc.$id;
    try {
      const exec = await functions.createExecution(
        ADMIN_FUNCTION_ID,
        JSON.stringify({ action: 'addCredits', userId: doc.$id, amount }),
        false
      );
      let body: any = {};
      try { body = JSON.parse(exec.responseBody || '{}'); } catch { /* ignore */ }
      if (!body.ok) {
        flash(body.error ?? 'Crédit refusé.', true);
        return;
      }
      flash(`${amount > 0 ? '+' : ''}${amount} crédit${Math.abs(amount) > 1 ? 's' : ''} ✓ — solde : ${body.credits}`);
    } catch (e: any) {
      flash(e?.message ?? 'Crédit impossible.', true);
    } finally {
      busyId = '';
    }
  }

  // ── Arborescence (séries/filières) : examen → subdivision → filière → matières
  $: examTree = resource?.tree ? buildExamTree(docs) : null;

  function splitCsv(v: any): string[] {
    return String(v ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }

  function buildExamTree(list: any[]) {
    const exams = new Map<string, Map<string, any[]>>();
    for (const d of list) {
      const ex = (d.exam ?? '—').toString() || '—';
      if (!exams.has(ex)) exams.set(ex, new Map());
      const cats = exams.get(ex)!;
      const cat = (d.category ?? '').toString(); // '' = pas de subdivision
      if (!cats.has(cat)) cats.set(cat, []);
      cats.get(cat)!.push(d);
    }
    return [...exams.entries()].map(([exam, cats]) => ({
      exam,
      total: [...cats.values()].reduce((n, a) => n + a.length, 0),
      cats: [...cats.entries()].map(([cat, items]) => ({ cat, items }))
    }));
  }

  function title(doc: any) {
    return resource ? doc[resource.titleField] || '(sans titre)' : '';
  }
  function subtitle(doc: any) {
    if (!resource?.subtitleField) return '';
    const v = doc[resource.subtitleField];
    return v == null ? '' : String(v);
  }
</script>

{#if !resource}
  <p>Ressource inconnue.</p>
{:else}
  <header class="head">
    <div>
      <h1>{resource.icon} {resource.label}</h1>
      <p class="muted">
        {total} élément{total > 1 ? 's' : ''}{searchTerm ? ` · recherche « ${searchTerm} »` : ''}
      </p>
    </div>
    {#if !resource.readOnly}
      <button class="btn-primary" on:click={openNew}>+ Nouveau {resource.singular}</button>
    {/if}
  </header>

  {#if canSearch}
    <div class="searchbar">
      <input
        type="search"
        placeholder="Rechercher ({searchableFields.join(', ')})…"
        bind:value={search}
        on:keydown={(e) => e.key === 'Enter' && applySearch()}
      />
      <button class="btn-primary btn-sm" on:click={applySearch}>Rechercher</button>
      {#if searchTerm}<button class="btn-ghost btn-sm" on:click={clearSearch}>Effacer</button>{/if}
    </div>
  {/if}

  {#if loading}
    <div class="center"><div class="spinner"></div></div>
  {:else if error}
    <div class="card err">{error}</div>
  {:else if docs.length === 0}
    <div class="card empty">
      <div class="empty-ico">{searchTerm ? '🔍' : resource.icon}</div>
      {#if searchTerm}
        <p>Aucun résultat pour « {searchTerm} ».</p>
        <button class="btn-ghost" on:click={clearSearch}>Effacer la recherche</button>
      {:else}
        <p>Aucun élément pour le moment.</p>
        {#if !resource.readOnly}<button class="btn-primary" on:click={openNew}>Créer le premier</button>{/if}
      {/if}
    </div>
  {:else if resource.tree && examTree}
    <!-- Arborescence repliable : examen → subdivision → filière → matières -->
    <div class="tree">
      {#each examTree as g (g.exam)}
        <details class="t-exam">
          <summary><span class="t-name">{g.exam}</span><span class="t-count">{g.total}</span></summary>
          <div class="t-body">
            {#each g.cats as c (c.cat)}
              {#if c.cat}
                <details class="t-cat">
                  <summary><span class="t-name">{c.cat}</span><span class="t-count">{c.items.length}</span></summary>
                  <div class="t-body">
                    {#each c.items as doc (doc.$id)}
                      <details class="t-leaf">
                        <summary>
                          <span class="t-leaf-name">{doc.name}</span>
                          {#if doc.code}<span class="t-code">{doc.code}</span>{/if}
                          <span class="t-acts">
                            <button class="btn-ghost btn-sm" on:click|preventDefault|stopPropagation={() => openEdit(doc)}>Modifier</button>
                            <button class="btn-danger btn-sm" on:click|preventDefault|stopPropagation={() => remove(doc)}>Suppr.</button>
                          </span>
                        </summary>
                        <div class="chips">
                          {#each splitCsv(doc.subjects) as s}<span class="chip">{s}</span>{/each}
                          {#if splitCsv(doc.subjects).length === 0}<span class="muted">Aucune matière renseignée.</span>{/if}
                        </div>
                      </details>
                    {/each}
                  </div>
                </details>
              {:else}
                {#each c.items as doc (doc.$id)}
                  <details class="t-leaf">
                    <summary>
                      <span class="t-leaf-name">{doc.name}</span>
                      {#if doc.code}<span class="t-code">{doc.code}</span>{/if}
                      <span class="t-acts">
                        <button class="btn-ghost btn-sm" on:click|preventDefault|stopPropagation={() => openEdit(doc)}>Modifier</button>
                        <button class="btn-danger btn-sm" on:click|preventDefault|stopPropagation={() => remove(doc)}>Suppr.</button>
                      </span>
                    </summary>
                    <div class="chips">
                      {#each splitCsv(doc.subjects) as s}<span class="chip">{s}</span>{/each}
                      {#if splitCsv(doc.subjects).length === 0}<span class="muted">Aucune matière renseignée.</span>{/if}
                    </div>
                  </details>
                {/each}
              {/if}
            {/each}
          </div>
        </details>
      {/each}
    </div>
  {:else}
    <div class="list">
      {#each docs as doc (doc.$id)}
        <div class="row card">
          <div class="row-main">
            <div class="row-title">{title(doc)}</div>
            {#if subtitle(doc)}<div class="row-sub muted">{subtitle(doc)}</div>{/if}
          </div>
          <div class="row-actions">
            <button class="btn-ghost btn-sm" title="Copier l'ID du document" on:click={() => navigator.clipboard?.writeText(doc.$id)}>ID</button>
            <button class="btn-ghost btn-sm" on:click={() => openEdit(doc)}>{resource.readOnly ? 'Voir' : 'Modifier'}</button>
            {#if resource.id === 'users'}
              <button class="btn-ghost btn-sm" disabled={busyId === doc.$id} on:click={() => addCredits(doc)}>+ Crédits</button>
              <button class="btn-ghost btn-sm" disabled={busyId === doc.$id} on:click={() => accountAction('block', doc)}>Bloquer</button>
              <button class="btn-ghost btn-sm" disabled={busyId === doc.$id} on:click={() => accountAction('unblock', doc)}>Débloquer</button>
              <button class="btn-danger btn-sm" disabled={busyId === doc.$id} on:click={() => accountAction('delete', doc)}>Suppr. compte</button>
            {:else if !resource.readOnly}
              <button class="btn-danger btn-sm" on:click={() => remove(doc)}>Suppr.</button>
            {/if}
          </div>
        </div>
      {/each}
    </div>
    {#if !resource.tree && total > PAGE}
      <div class="pager">
        <button class="btn-ghost btn-sm" disabled={pageIndex === 0} on:click={() => goPage(-1)}>← Précédent</button>
        <span class="muted">Page {pageIndex + 1} / {pageCount}</span>
        <button class="btn-ghost btn-sm" disabled={(pageIndex + 1) * PAGE >= total} on:click={() => goPage(1)}>Suivant →</button>
      </div>
    {/if}
  {/if}
{/if}

<!-- Éditeur (panneau latéral) -->
{#if editing && resource}
  <div class="overlay" on:click={close} role="presentation"></div>
  <aside class="drawer">
    <div class="drawer-head">
      <h2>{resource.readOnly ? 'Détails' : editingId ? 'Modifier' : 'Nouveau'} · {resource.singular}</h2>
      <button class="btn-ghost btn-sm" on:click={close}>Fermer</button>
    </div>
    <div class="drawer-body">
      {#each resource.fields as f}
        <div class="field">
          <label for={'f-' + f.key}>
            {f.label}{#if f.required}<span class="req"> *</span>{/if}
          </label>
          {#if f.type === 'textarea'}
            <textarea id={'f-' + f.key} bind:value={editing[f.key]} readonly={resource.readOnly}></textarea>
          {:else if f.type === 'boolean'}
            <label class="switch">
              <input type="checkbox" bind:checked={editing[f.key]} disabled={resource.readOnly} />
              <span>{editing[f.key] ? 'Oui' : 'Non'}</span>
            </label>
          {:else if f.type === 'number'}
            <input id={'f-' + f.key} type="number" bind:value={editing[f.key]} readonly={resource.readOnly} />
          {:else if f.type === 'datetime'}
            <input id={'f-' + f.key} type="datetime-local" bind:value={editing[f.key]} readonly={resource.readOnly} />
          {:else if f.type === 'select'}
            <select id={'f-' + f.key} bind:value={editing[f.key]} disabled={resource.readOnly}>
              {#each f.options ?? [] as opt}
                {@const val = opt.split('|')[0]}
                {@const lbl = opt.split('|')[1] ?? opt}
                <option value={val}>{val === '' ? '(aucun)' : lbl}</option>
              {/each}
            </select>
          {:else}
            <input id={'f-' + f.key} type="text" bind:value={editing[f.key]} readonly={resource.readOnly} />
          {/if}
          {#if f.help}<div class="help muted">{f.help}</div>{/if}
        </div>
      {/each}
    </div>
    <div class="drawer-foot">
      {#if resource.readOnly}
        <button class="btn-primary" on:click={close}>Fermer</button>
      {:else}
        <button class="btn-ghost" on:click={close}>Annuler</button>
        <button class="btn-primary" on:click={save} disabled={saving}>
          {saving ? 'Enregistrement…' : 'Enregistrer'}
        </button>
      {/if}
    </div>
  </aside>
{/if}

{#if toast}
  <div class="toast" class:bad={toastBad}>{toast}</div>
{/if}

<style>
  .head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 22px; gap: 16px; }
  .head h1 { font-size: 24px; }
  .head p { margin: 5px 0 0; font-size: 13px; }
  .center { display: flex; justify-content: center; padding: 60px; }
  .err { color: var(--bad); background: var(--bad-bg); border: none; }
  .empty { text-align: center; padding: 44px; }
  .empty-ico { font-size: 38px; margin-bottom: 8px; }
  .empty p { color: var(--muted); margin: 0 0 16px; }
  .searchbar { display: flex; gap: 10px; align-items: center; margin-bottom: 16px; }
  .searchbar input { flex: 1; }
  .pager { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 18px; font-size: 13px; }
  .list { display: flex; flex-direction: column; gap: 10px; }
  .row { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 14px 16px; }
  .row-title { font-weight: 700; font-size: 14.5px; }
  .row-sub { font-size: 12.5px; margin-top: 2px; }
  .row-actions { display: flex; gap: 8px; flex-shrink: 0; }

  /* Arborescence séries/filières */
  .tree { display: flex; flex-direction: column; gap: 8px; }
  .tree details { border-radius: 12px; }
  .tree summary {
    list-style: none; cursor: pointer; display: flex; align-items: center; gap: 10px;
    padding: 11px 14px; user-select: none;
  }
  .tree summary::-webkit-details-marker { display: none; }
  .tree summary::before {
    content: '▸'; color: var(--muted); font-size: 12px; transition: transform 0.15s; flex-shrink: 0;
  }
  .tree details[open] > summary::before { transform: rotate(90deg); }
  .t-name { font-weight: 700; }
  .t-count {
    margin-left: auto; font-size: 11.5px; font-weight: 700; color: var(--muted);
    background: var(--panel); border-radius: 999px; padding: 2px 9px;
  }
  .t-exam { background: var(--paper); border: 1.5px solid var(--line); }
  .t-exam > summary { font-size: 15px; }
  .t-body { padding: 2px 10px 10px 22px; display: flex; flex-direction: column; gap: 6px; }
  .t-cat { background: var(--bg); border: 1px solid var(--line); }
  .t-cat > summary { font-size: 13.5px; color: var(--ink2); }
  .t-leaf { background: var(--paper); border: 1px solid var(--line); }
  .t-leaf > summary { font-size: 13px; padding: 9px 12px; }
  .t-leaf-name { font-weight: 600; }
  .t-code {
    font-size: 11px; font-weight: 800; color: var(--accent, #c2620f);
    background: var(--panel); border-radius: 6px; padding: 1px 7px;
  }
  .t-acts { margin-left: auto; display: flex; gap: 6px; flex-shrink: 0; }
  .chips { display: flex; flex-wrap: wrap; gap: 6px; padding: 4px 12px 12px 30px; }
  .chip {
    font-size: 12px; font-weight: 600; color: var(--ink2);
    background: var(--panel); border: 1px solid var(--line); border-radius: 999px; padding: 4px 11px;
  }

  .overlay { position: fixed; inset: 0; background: rgba(20, 15, 11, 0.4); z-index: 40; }
  .drawer {
    position: fixed; top: 0; right: 0; bottom: 0; width: 440px; max-width: 92vw;
    background: var(--bg); z-index: 50; display: flex; flex-direction: column;
    box-shadow: -16px 0 40px rgba(20, 15, 11, 0.18);
  }
  .drawer-head, .drawer-foot {
    padding: 16px 20px; display: flex; align-items: center; justify-content: space-between;
    background: var(--paper);
  }
  .drawer-head { border-bottom: 1.5px solid var(--line); }
  .drawer-head h2 { font-size: 16px; }
  .drawer-foot { border-top: 1.5px solid var(--line); gap: 10px; }
  .drawer-body { flex: 1; overflow-y: auto; padding: 20px; }
  .field { margin-bottom: 16px; }
  .req { color: var(--bad); }
  .help { font-size: 11.5px; margin-top: 5px; }
  .switch { display: flex; align-items: center; gap: 9px; font-weight: 600; color: var(--ink2); }
  .switch input { width: auto; }
</style>
