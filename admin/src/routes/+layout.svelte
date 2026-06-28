<script lang="ts">
  import '../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { session, refreshSession, logout } from '$lib/auth';
  import { RESOURCES } from '$lib/schema';
  import { ADMIN_GATE_SHA256 } from '$lib/config';
  import { goto } from '$app/navigation';

  onMount(refreshSession);

  // ── 2ᵉ couche : code secret après connexion (déverrouillage de session) ──
  const GATE_KEY = 'admin_gate_v1';
  let gateOk = false;
  let gateInput = '';
  let gateError = '';
  let gateTries = 0;
  let gateBusy = false;

  onMount(() => {
    try { gateOk = sessionStorage.getItem(GATE_KEY) === 'ok'; } catch { /* */ }
  });

  async function sha256Hex(s: string): Promise<string> {
    const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s));
    return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, '0')).join('');
  }

  async function submitGate() {
    if (gateBusy || gateTries >= 5) return;
    gateBusy = true; gateError = '';
    try {
      const h = await sha256Hex(gateInput);
      if (h === ADMIN_GATE_SHA256) {
        gateOk = true;
        try { sessionStorage.setItem(GATE_KEY, 'ok'); } catch { /* */ }
      } else {
        gateTries += 1; gateInput = '';
        gateError = gateTries >= 5 ? 'Trop de tentatives. Recharge la page pour réessayer.' : 'Code incorrect.';
      }
    } finally { gateBusy = false; }
  }

  async function onLogout() {
    try { sessionStorage.removeItem(GATE_KEY); } catch { /* */ }
    gateOk = false;
    await logout();
    goto('/login');
  }

  $: path = $page.url.pathname;
  $: isLoginPage = path === '/login';

  // Redirige vers la connexion si non authentifié ou non-admin.
  $: if (!$session.loading && (!$session.user || !$session.isAdmin) && !isLoginPage) {
    goto('/login');
  }
</script>

{#if $session.loading}
  <div class="center">
    <div class="spinner"></div>
  </div>
{:else if !$session.user || !$session.isAdmin}
  {#if isLoginPage}
    <slot />
  {:else}
    <div class="center"><div class="spinner"></div></div>
  {/if}
{:else if !gateOk}
  <div class="center">
    <div class="gate card">
      <div class="gate-ico">🔒</div>
      <h1>Accès administrateur</h1>
      <p>Saisis le code secret pour déverrouiller l'espace d'administration.</p>
      <form on:submit|preventDefault={submitGate}>
        <input
          type="password"
          autocomplete="off"
          placeholder="Code secret"
          bind:value={gateInput}
          disabled={gateTries >= 5}
        />
        {#if gateError}<div class="gate-err">{gateError}</div>{/if}
        <button class="btn-primary" type="submit" disabled={gateBusy || gateTries >= 5 || !gateInput}>
          {gateBusy ? 'Vérification…' : 'Déverrouiller'}
        </button>
      </form>
      <button class="btn-ghost btn-sm" on:click={onLogout}>Se déconnecter</button>
    </div>
  </div>
{:else}
  <div class="shell">
    <aside class="sidebar">
      <div class="brand">
        <div class="logo">OB</div>
        <div>
          <div class="brand-name">OnBuch</div>
          <div class="brand-sub">Administration</div>
        </div>
      </div>

      <nav>
        <a class="nav-item" class:active={path === '/'} href="/">
          <span class="nav-ico">📊</span> Tableau de bord
        </a>
        <div class="nav-sep">Contenus</div>
        <a class="nav-item" class:active={path.startsWith('/results')} href="/results">
          <span class="nav-ico">🎓</span> Résultats — sources
        </a>
        <a class="nav-item" class:active={path.startsWith('/annales')} href="/annales">
          <span class="nav-ico">🗂️</span> Annales & documents
        </a>
        <a class="nav-item" class:active={path.startsWith('/exercices')} href="/exercices">
          <span class="nav-ico">🧪</span> Atelier Exercices
        </a>
        <a class="nav-item" class:active={path.startsWith('/cours')} href="/cours">
          <span class="nav-ico">📘</span> Atelier Cours
        </a>
        {#each RESOURCES.filter((r) => !r.hidden) as r}
          <a class="nav-item" class:active={path.startsWith('/c/' + r.id)} href={'/c/' + r.id}>
            <span class="nav-ico">{r.icon}</span> {r.label}
          </a>
        {/each}
      </nav>

      <div class="sidebar-foot">
        <div class="who">
          <div class="who-name">{$session.user.name || $session.user.email}</div>
          <div class="who-mail">{$session.user.email}</div>
        </div>
        <button class="btn-ghost btn-sm" on:click={onLogout}>Déconnexion</button>
      </div>
    </aside>

    <main class="content">
      <slot />
    </main>
  </div>
{/if}

<style>
  .center {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .gate {
    width: 360px; max-width: 92vw; padding: 28px 26px; text-align: center;
    display: flex; flex-direction: column; gap: 6px;
  }
  .gate-ico { font-size: 34px; }
  .gate h1 { font-size: 19px; margin: 6px 0 0; }
  .gate p { color: var(--muted); font-size: 13px; margin: 0 0 14px; line-height: 1.45; }
  .gate form { display: flex; flex-direction: column; gap: 10px; }
  .gate input {
    width: 100%; padding: 11px 13px; border: 1.5px solid var(--line2); border-radius: 11px;
    background: var(--paper); font: inherit; text-align: center; letter-spacing: 1px;
  }
  .gate input:focus { outline: none; border-color: var(--o500); }
  .gate-err { color: var(--bad); font-size: 12.5px; font-weight: 600; }
  .gate .btn-ghost { margin-top: 10px; }
  .shell {
    display: grid;
    grid-template-columns: 252px 1fr;
    min-height: 100vh;
  }
  .sidebar {
    background: var(--paper);
    border-right: 1.5px solid var(--line);
    padding: 20px 14px;
    display: flex;
    flex-direction: column;
    gap: 6px;
    position: sticky;
    top: 0;
    height: 100vh;
  }
  .brand { display: flex; align-items: center; gap: 11px; padding: 4px 8px 16px; }
  .logo {
    width: 38px; height: 38px; border-radius: 10px;
    background: var(--o500); color: #fff;
    display: flex; align-items: center; justify-content: center;
    font-weight: 800; font-size: 15px;
  }
  .brand-name { font-weight: 800; font-size: 16px; }
  .brand-sub { font-size: 11px; color: var(--muted); font-weight: 600; }
  nav { display: flex; flex-direction: column; gap: 2px; flex: 1; overflow-y: auto; }
  .nav-item {
    display: flex; align-items: center; gap: 10px;
    padding: 10px 12px; border-radius: 11px;
    font-weight: 600; font-size: 13.5px; color: var(--ink2);
  }
  .nav-item:hover { background: var(--panel); }
  .nav-item.active { background: var(--o50); color: var(--o700); }
  .nav-ico { font-size: 15px; }
  .nav-sep {
    font-size: 10.5px; font-weight: 800; color: var(--muted);
    text-transform: uppercase; letter-spacing: 0.05em;
    padding: 14px 12px 6px;
  }
  .sidebar-foot {
    border-top: 1.5px solid var(--line);
    padding-top: 14px; margin-top: 6px;
    display: flex; flex-direction: column; gap: 10px;
  }
  .who-name { font-weight: 700; font-size: 13px; }
  .who-mail { font-size: 11px; color: var(--muted); }
  .content { padding: 30px 34px; max-width: 920px; }
  @media (max-width: 720px) {
    .shell { grid-template-columns: 1fr; }
    .sidebar { position: static; height: auto; }
    .content { padding: 20px; }
  }
</style>
