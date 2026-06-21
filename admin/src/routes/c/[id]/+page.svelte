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

  let loadedId = '';
  $: resource = resourceById($page.params.id);
  $: if (resource && resource.id !== loadedId) {
    loadedId = resource.id;
    load();
  }

  function flash(msg: string, bad = false) {
    toast = msg;
    toastBad = bad;
    setTimeout(() => (toast = ''), 2600);
  }

  async function load() {
    if (!resource) return;
    loading = true;
    error = '';
    try {
      const queries = [Query.limit(100)];
      if (resource.orderBy) {
        queries.push(
          resource.orderBy.dir === 'desc'
            ? Query.orderDesc(resource.orderBy.field)
            : Query.orderAsc(resource.orderBy.field)
        );
      }
      const res = await databases.listDocuments(APPWRITE_DATABASE, resource.collectionId, queries);
      docs = res.documents;
    } catch (e: any) {
      error = e?.message ?? 'Chargement impossible.';
      docs = [];
    } finally {
      loading = false;
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
      <p class="muted">{docs.length} élément{docs.length > 1 ? 's' : ''}</p>
    </div>
    <button class="btn-primary" on:click={openNew}>+ Nouveau {resource.singular}</button>
  </header>

  {#if loading}
    <div class="center"><div class="spinner"></div></div>
  {:else if error}
    <div class="card err">{error}</div>
  {:else if docs.length === 0}
    <div class="card empty">
      <div class="empty-ico">{resource.icon}</div>
      <p>Aucun élément pour le moment.</p>
      <button class="btn-primary" on:click={openNew}>Créer le premier</button>
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
            <button class="btn-ghost btn-sm" on:click={() => openEdit(doc)}>Modifier</button>
            {#if resource.id === 'users'}
              <button class="btn-ghost btn-sm" disabled={busyId === doc.$id} on:click={() => accountAction('block', doc)}>Bloquer</button>
              <button class="btn-ghost btn-sm" disabled={busyId === doc.$id} on:click={() => accountAction('unblock', doc)}>Débloquer</button>
              <button class="btn-danger btn-sm" disabled={busyId === doc.$id} on:click={() => accountAction('delete', doc)}>Suppr. compte</button>
            {:else}
              <button class="btn-danger btn-sm" on:click={() => remove(doc)}>Suppr.</button>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  {/if}
{/if}

<!-- Éditeur (panneau latéral) -->
{#if editing && resource}
  <div class="overlay" on:click={close} role="presentation"></div>
  <aside class="drawer">
    <div class="drawer-head">
      <h2>{editingId ? 'Modifier' : 'Nouveau'} · {resource.singular}</h2>
      <button class="btn-ghost btn-sm" on:click={close}>Fermer</button>
    </div>
    <div class="drawer-body">
      {#each resource.fields as f}
        <div class="field">
          <label for={'f-' + f.key}>
            {f.label}{#if f.required}<span class="req"> *</span>{/if}
          </label>
          {#if f.type === 'textarea'}
            <textarea id={'f-' + f.key} bind:value={editing[f.key]}></textarea>
          {:else if f.type === 'boolean'}
            <label class="switch">
              <input type="checkbox" bind:checked={editing[f.key]} />
              <span>{editing[f.key] ? 'Oui' : 'Non'}</span>
            </label>
          {:else if f.type === 'number'}
            <input id={'f-' + f.key} type="number" bind:value={editing[f.key]} />
          {:else if f.type === 'datetime'}
            <input id={'f-' + f.key} type="datetime-local" bind:value={editing[f.key]} />
          {:else if f.type === 'select'}
            <select id={'f-' + f.key} bind:value={editing[f.key]}>
              {#each f.options ?? [] as opt}
                <option value={opt}>{opt === '' ? '(aucun)' : opt}</option>
              {/each}
            </select>
          {:else}
            <input id={'f-' + f.key} type="text" bind:value={editing[f.key]} />
          {/if}
          {#if f.help}<div class="help muted">{f.help}</div>{/if}
        </div>
      {/each}
    </div>
    <div class="drawer-foot">
      <button class="btn-ghost" on:click={close}>Annuler</button>
      <button class="btn-primary" on:click={save} disabled={saving}>
        {saving ? 'Enregistrement…' : 'Enregistrer'}
      </button>
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
  .list { display: flex; flex-direction: column; gap: 10px; }
  .row { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 14px 16px; }
  .row-title { font-weight: 700; font-size: 14.5px; }
  .row-sub { font-size: 12.5px; margin-top: 2px; }
  .row-actions { display: flex; gap: 8px; flex-shrink: 0; }

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
