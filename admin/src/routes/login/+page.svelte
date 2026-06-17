<script lang="ts">
  import { session, login } from '$lib/auth';
  import { goto } from '$app/navigation';

  let email = '';
  let password = '';
  let busy = false;
  let error = '';

  // Déjà connecté & admin → vers le tableau de bord.
  $: if ($session.user && $session.isAdmin) goto('/');

  async function submit() {
    error = '';
    busy = true;
    try {
      await login(email, password);
    } catch (e: any) {
      error = e?.message ?? 'Connexion impossible.';
    } finally {
      busy = false;
    }
  }
</script>

<div class="wrap">
  <div class="box card">
    <div class="logo">OB</div>
    <h1>Administration OnBuch</h1>
    <p class="muted sub">Connecte-toi avec ton compte administrateur.</p>

    {#if $session.user && !$session.isAdmin}
      <div class="banner bad">
        Ce compte n'est pas administrateur. Demande à être ajouté à l'équipe
        <strong>admins</strong> dans Appwrite.
      </div>
    {/if}

    <form on:submit|preventDefault={submit}>
      <div class="field">
        <label for="email">Email</label>
        <input id="email" type="email" bind:value={email} autocomplete="username" required />
      </div>
      <div class="field">
        <label for="pw">Mot de passe</label>
        <input id="pw" type="password" bind:value={password} autocomplete="current-password" required />
      </div>

      {#if error}<div class="banner bad">{error}</div>{/if}

      <button class="btn-primary full" type="submit" disabled={busy}>
        {busy ? 'Connexion…' : 'Se connecter'}
      </button>
    </form>
  </div>
</div>

<style>
  .wrap { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
  .box { width: 100%; max-width: 380px; border-radius: 22px; padding: 28px; }
  .logo {
    width: 46px; height: 46px; border-radius: 13px; background: var(--o500); color: #fff;
    display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 17px;
    margin-bottom: 16px;
  }
  h1 { font-size: 21px; }
  .sub { margin: 6px 0 20px; font-size: 13px; }
  .field { margin-bottom: 14px; }
  .full { width: 100%; padding: 13px; margin-top: 4px; }
  .banner { padding: 11px 13px; border-radius: 11px; font-size: 12.5px; font-weight: 600; margin-bottom: 14px; }
  .banner.bad { background: var(--bad-bg); color: var(--bad); }
</style>
