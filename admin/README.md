# OnBuch — Administration (back-office)

Interface web (SvelteKit + TypeScript) pour gérer les contenus de l'app OnBuch
dans Appwrite : notifications, actualités, concours, centres de préparation,
ressources, résultats d'examens, examens de l'accueil…

C'est une **SPA 100 % navigateur** : pas de serveur, pas de clé secrète. L'admin
se connecte avec un compte Appwrite membre de l'équipe **`admins`** ; le SDK
écrit avec les permissions de cette session.

## Démarrer en local
```bash
cd admin
npm install
npm run dev
```
Ouvre http://localhost:5173.

## Build / déploiement
```bash
npm run build      # sortie statique dans admin/build
```
Hébergeable tel quel sur **Vercel**, **Netlify**, **Cloudflare Pages**, GitHub
Pages… (pointer la racine du projet sur `admin/`, commande `npm run build`,
dossier de sortie `build`).

## Accès admin (à faire une fois)
Le côté serveur est déjà configuré (équipe `admins` créée + droit d'écriture
`team:admins` accordé sur les collections, via `tools/setup_admin_team.sh`).
Il reste à **ajouter ton compte à l'équipe** :

1. Appwrite Console → **Auth → Teams → `admins`** (ou **Teams**).
2. **Create membership** → saisis l'email du compte qui administrera.
3. Ce compte peut maintenant se connecter au back-office et écrire.

> Tout compte Appwrite **non** membre de `admins` peut se connecter mais verra
> « ce compte n'est pas administrateur » et n'aura aucun accès.

## Ajouter une collection à gérer
Tout est piloté par `src/lib/schema.ts` : ajoute une entrée `Resource`
(collection, libellé, champs) et l'écran de liste + le formulaire sont générés
automatiquement. Pense à accorder le droit d'écriture `team:admins` sur la
nouvelle collection (voir `tools/setup_admin_team.sh`).

## Structure
- `src/lib/config.ts` — endpoint / project / database / équipe admin.
- `src/lib/appwrite.ts` — client Appwrite (Account, Databases, Teams).
- `src/lib/auth.ts` — session + contrôle d'appartenance à `admins`.
- `src/lib/schema.ts` — **définition des collections gérées** (le cœur).
- `src/routes/+layout.svelte` — coque + garde d'authentification.
- `src/routes/login/` — connexion.
- `src/routes/+page.svelte` — tableau de bord (compteurs).
- `src/routes/c/[id]/` — liste + éditeur générique (CRUD).
