import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    // SPA : aucune génération côté serveur, hébergeable partout (Vercel,
    // Netlify, GitHub Pages…). Le SDK Appwrite tourne dans le navigateur.
    adapter: adapter({ fallback: 'index.html' })
  }
};

export default config;
