<script lang="ts">
  import '../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { session, refreshSession, logout } from '$lib/auth';
  import { RESOURCES } from '$lib/schema';
  import { goto } from '$app/navigation';

  onMount(refreshSession);

  async function onLogout() {
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
        {#each RESOURCES as r}
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
