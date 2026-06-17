<script lang="ts">
  import { onMount } from 'svelte';
  import { databases, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';
  import { RESOURCES } from '$lib/schema';

  let counts: Record<string, number | null> = {};

  onMount(async () => {
    for (const r of RESOURCES) counts[r.id] = null;
    counts = { ...counts };
    await Promise.all(
      RESOURCES.map(async (r) => {
        try {
          const res = await databases.listDocuments(APPWRITE_DATABASE, r.collectionId, [Query.limit(1)]);
          counts[r.id] = res.total;
        } catch {
          counts[r.id] = -1; // erreur / collection absente
        }
        counts = { ...counts };
      })
    );
  });
</script>

<header class="head">
  <h1>Tableau de bord</h1>
  <p class="muted">Gère les contenus de l'application OnBuch.</p>
</header>

<div class="grid">
  {#each RESOURCES as r}
    <a class="tile card" href={'/c/' + r.id}>
      <div class="ico">{r.icon}</div>
      <div class="meta">
        <div class="count">
          {#if counts[r.id] === null}
            <span class="dim">…</span>
          {:else if counts[r.id] === -1}
            <span class="dim">—</span>
          {:else}
            {counts[r.id]}
          {/if}
        </div>
        <div class="label">{r.label}</div>
      </div>
    </a>
  {/each}
</div>

<style>
  .head { margin-bottom: 22px; }
  .head h1 { font-size: 26px; }
  .head p { margin: 6px 0 0; font-size: 14px; }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
    gap: 14px;
  }
  .tile { display: flex; align-items: center; gap: 14px; transition: border-color 0.15s, transform 0.1s; }
  .tile:hover { border-color: var(--o500); transform: translateY(-2px); }
  .ico {
    width: 48px; height: 48px; border-radius: 13px; background: var(--o50);
    display: flex; align-items: center; justify-content: center; font-size: 23px;
  }
  .count { font-size: 24px; font-weight: 800; letter-spacing: -0.02em; }
  .count .dim { color: var(--muted); }
  .label { font-size: 13px; color: var(--ink2); font-weight: 600; }
</style>
