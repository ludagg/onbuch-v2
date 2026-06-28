<script lang="ts">
  import { onMount } from 'svelte';
  import { databases, Query } from '$lib/appwrite';
  import { APPWRITE_DATABASE } from '$lib/config';
  import { RESOURCES } from '$lib/schema';

  const DB = APPWRITE_DATABASE;

  // Compte le total d'une collection (option. filtré). Renvoie null tant que
  // ça charge, -1 si erreur/absent. N'utilise que `total` (pas d'index requis,
  // sauf filtres système $createdAt qui sont interrogeables).
  async function count(col: string, queries: any[] = []): Promise<number> {
    const res = await databases.listDocuments(DB, col, [...queries, Query.limit(1)]);
    return res.total;
  }

  function daysAgoIso(d: number): string {
    return new Date(Date.now() - d * 86400000).toISOString();
  }

  type Metric = { key: string; label: string; caption?: string; icon: string; value: number | null };
  type Group = { title: string; icon: string; metrics: Metric[] };

  // Définition des métriques (chaque entrée = un compteur à charger).
  let groups: Group[] = [
    { title: 'Usage', icon: '📈', metrics: [
      { key: 'users', label: 'Élèves inscrits', icon: '👥', value: null },
      { key: 'new7', label: 'Nouveaux (7 j)', caption: 'inscriptions cette semaine', icon: '✨', value: null },
      { key: 'new30', label: 'Nouveaux (30 j)', caption: 'inscriptions ce mois', icon: '📅', value: null },
      { key: 'gamif', label: 'Profils de jeu', caption: 'élèves avec XP/série', icon: '🔥', value: null },
    ]},
    { title: 'Apprentissage', icon: '🎓', metrics: [
      { key: 'quiz', label: 'Quiz tentés', icon: '❓', value: null },
      { key: 'tutor', label: 'Demandes Tuteur IA', icon: '🤖', value: null },
      { key: 'subjects', label: 'Matières (cours)', icon: '📘', value: null },
      { key: 'chapters', label: 'Chapitres', icon: '📑', value: null },
      { key: 'sheets', label: 'Fiches d\'exercices', icon: '🧪', value: null },
      { key: 'annales', label: 'Annales / docs', icon: '🗂️', value: null },
    ]},
    { title: 'Monétisation', icon: '💰', metrics: [
      { key: 'purchases', label: 'Achats de packs', icon: '🧾', value: null },
      { key: 'purch30', label: 'Achats (30 j)', caption: 'ce mois', icon: '🛒', value: null },
      { key: 'pay', label: 'Demandes de paiement', icon: '💳', value: null },
      { key: 'refTotal', label: 'Parrainages', icon: '🎁', value: null },
      { key: 'refRewarded', label: 'Parrainages validés', caption: 'palier atteint', icon: '✅', value: null },
    ]},
  ];

  // Chargeurs par clé.
  const loaders: Record<string, () => Promise<number>> = {
    users: () => count('users'),
    new7: () => count('users', [Query.greaterThanEqual('$createdAt', daysAgoIso(7))]),
    new30: () => count('users', [Query.greaterThanEqual('$createdAt', daysAgoIso(30))]),
    gamif: () => count('gamification'),
    quiz: () => count('quiz_attempts'),
    tutor: () => count('tutor_jobs'),
    subjects: () => count('subjects'),
    chapters: () => count('chapters'),
    sheets: () => count('exercise_sheets'),
    annales: () => count('annales'),
    purchases: () => count('pack_purchases'),
    purch30: () => count('pack_purchases', [Query.greaterThanEqual('$createdAt', daysAgoIso(30))]),
    pay: () => count('payment_requests'),
    refTotal: () => count('referrals'),
    refRewarded: () => count('referrals', [Query.equal('status', ['rewarded'])]),
  };

  let collCounts: Record<string, number | null> = {};

  onMount(async () => {
    // Métriques (en parallèle, chacune tolérante à l'erreur → -1).
    await Promise.all(
      groups.flatMap((g) =>
        g.metrics.map(async (m) => {
          try { m.value = await loaders[m.key](); }
          catch { m.value = -1; }
          groups = [...groups];
        })
      )
    );
    // Compteurs des collections (navigation rapide) — hors pages masquées.
    const visible = RESOURCES.filter((r) => !r.hidden);
    for (const r of visible) collCounts[r.id] = null;
    collCounts = { ...collCounts };
    await Promise.all(
      visible.map(async (r) => {
        try { collCounts[r.id] = await count(r.collectionId); }
        catch { collCounts[r.id] = -1; }
        collCounts = { ...collCounts };
      })
    );
  });

  function fmt(v: number | null): string {
    if (v === null) return '…';
    if (v === -1) return '—';
    return v.toLocaleString('fr-FR');
  }
  $: visibleResources = RESOURCES.filter((r) => !r.hidden);
</script>

<header class="head">
  <h1>Tableau de bord</h1>
  <p class="muted">Vue d'ensemble de l'activité OnBuch — usage, apprentissage, monétisation.</p>
</header>

{#each groups as g}
  <section class="block">
    <h2>{g.icon} {g.title}</h2>
    <div class="mgrid">
      {#each g.metrics as m}
        <div class="metric card">
          <div class="m-ico">{m.icon}</div>
          <div class="m-val" class:dim={m.value === null || m.value === -1}>{fmt(m.value)}</div>
          <div class="m-lbl">{m.label}</div>
          {#if m.caption}<div class="m-cap">{m.caption}</div>{/if}
        </div>
      {/each}
    </div>
  </section>
{/each}

<section class="block">
  <h2>🗃️ Collections</h2>
  <div class="grid">
    {#each visibleResources as r}
      <a class="tile card" href={'/c/' + r.id}>
        <div class="ico">{r.icon}</div>
        <div class="meta">
          <div class="count" class:dim={collCounts[r.id] === null || collCounts[r.id] === -1}>{fmt(collCounts[r.id] ?? null)}</div>
          <div class="label">{r.label}</div>
        </div>
      </a>
    {/each}
  </div>
</section>

<style>
  .head { margin-bottom: 20px; }
  .head h1 { font-size: 26px; }
  .head p { margin: 6px 0 0; font-size: 14px; }
  .block { margin-bottom: 26px; }
  .block h2 { font-size: 15px; margin: 0 0 12px; color: var(--ink2); }
  .mgrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
  .metric { padding: 14px 15px; }
  .m-ico { font-size: 18px; }
  .m-val { font-size: 28px; font-weight: 800; letter-spacing: -0.02em; margin-top: 6px; }
  .m-val.dim { color: var(--muted); }
  .m-lbl { font-size: 12.5px; font-weight: 700; color: var(--ink2); margin-top: 2px; }
  .m-cap { font-size: 10.5px; color: var(--muted); margin-top: 2px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(210px, 1fr)); gap: 14px; }
  .tile { display: flex; align-items: center; gap: 14px; transition: border-color 0.15s, transform 0.1s; }
  .tile:hover { border-color: var(--o500); transform: translateY(-2px); }
  .ico { width: 48px; height: 48px; border-radius: 13px; background: var(--o50); display: flex; align-items: center; justify-content: center; font-size: 23px; }
  .count { font-size: 24px; font-weight: 800; letter-spacing: -0.02em; }
  .count.dim { color: var(--muted); }
  .label { font-size: 13px; color: var(--ink2); font-weight: 600; }
</style>
