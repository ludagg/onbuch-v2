# Audit application OnBuch - 2026-06-23

Branche audit: `audit/application-20260623`

Base auditee: `origin/main` au commit `e60b635` (`Fix ecran noir recherche + administration complete + credits Tuteur (#122)`).

## Synthese

L'application est structuree autour d'une app Flutter, d'un back-office Svelte, de fonctions Appwrite et d'API Vercel pour les credits/packs. Les changements recents autour de la recherche d'annales semblent coherents cote routage, mais plusieurs flux serveur critiques manipulent des credits ou des achats avec des lectures/ecritures non atomiques. C'est le principal risque applicatif.

Les controles executables localement ont ete limites par l'environnement: Flutter/Dart n'est pas installe. Le back-office admin a pu etre verifie avec `npm run check`.

## Controles executes

- `git fetch origin main`
- `git worktree add -b audit/application-20260623 /tmp/onbuch-audit origin/main`
- `git push -u origin audit/application-20260623`
- `npm ci` dans `admin/`
- `npm run check` dans `admin/`
- `npm audit --audit-level=low` dans `admin/`
- Revue statique des services Flutter, fonctions Appwrite, API Vercel, routage et admin.

## Resultats automatiques

### Admin Svelte

`npm run check` echoue:

- Erreur TypeScript dans `admin/src/routes/c/[id]/+page.svelte:26`: `$page.params.id` peut etre `undefined`, mais `resourceById` attend une `string`.
- 6 avertissements a11y: labels non associes a des controles dans `admin/src/routes/annales/+page.svelte` et `admin/src/routes/results/+page.svelte`.

### Dependances admin

`npm audit --audit-level=low` remonte 10 vulnerabilites:

- 1 high via `cookie <0.7.0`, tire par `@sveltejs/kit`.
- 6 moderate via `svelte <=5.55.6`.
- 3 low/moderate via `esbuild <=0.24.2` et la chaine `vite`.

`npm audit fix --force` propose des upgrades cassants. Il faut planifier une mise a jour controlee de SvelteKit/Vite/Svelte plutot qu'un force fix direct.

### Flutter

Non execute: `flutter` et `dart` ne sont pas disponibles dans l'environnement courant. A faire dans un environnement Flutter:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- au minimum un build Android de validation.

## Constats prioritaires

### P0 - Achats de packs: debit sans garantie de propriete

Fichier: `telegram-bot/api/buy-pack.js`

Le flux debite les credits avant de creer les documents `pack_purchases`. Si une creation echoue apres le debit, l'utilisateur perd des credits sans recevoir tous les packs. La reponse renvoie quand meme `ok: true`, avec seulement les packs effectivement ajoutes dans `owned`.

Zone concernee:

- Lecture du solde: lignes 75-78
- Debit: ligne 82
- Creation des proprietes: lignes 85-95
- Reponse succes: ligne 97

Recommandation:

- Rendre l'operation atomique cote serveur, ou introduire une transaction logique robuste: creer un ordre d'achat, reserver/debiter, creer toutes les proprietes, puis confirmer.
- En cas d'echec partiel, rollback du debit ou statut `pending_repair` traite par une tache serveur.
- Ne jamais retourner `ok: true` si `owned.length !== toBuy.length`.

### P0 - Credits/quota: mises a jour non atomiques et risques de course

Fichiers:

- `telegram-bot/api/redeem.js`
- `telegram-bot/api/buy-pack.js`
- `functions/verify-purchase/src/main.js`
- `functions/tutor-ai/src/main.js`

Plusieurs flux font `GET current balance/quota` puis `PATCH current +/- amount`. Deux requetes concurrentes peuvent lire le meme solde et ecraser la mise a jour de l'autre. Cela peut produire double depense, perte de credits, double rachat ou quota gratuit consomme de facon incorrecte.

Zones concernees:

- `redeem.js`: lignes 65-79
- `buy-pack.js`: lignes 75-82
- `verify-purchase/src/main.js`: lignes 103-113
- `tutor-ai/src/main.js`: lignes 445-463 et 226-235

Recommandation:

- Eviter les soldes modifiables par lecture/ecriture simple.
- Utiliser un ledger append-only (`credit_transactions`) puis calculer/projeter le solde.
- A defaut, utiliser une operation serveur unique avec verrou par utilisateur, idempotency key et controle de version.

### P1 - Verification Google Play: idempotence degradee si la collection de recus manque

Fichier: `functions/verify-purchase/src/main.js`

Si `purchase_receipts` n'existe pas ou si l'ecriture du recu echoue pour une raison autre que 409, la fonction continue quand meme et credite l'utilisateur. Le commentaire dit explicitement "idempotence degradee". Cela ouvre la porte a des recreditations si le meme recu est rejoue.

Zone concernee:

- Ecriture recu: lignes 85-101
- Credit: lignes 103-113

Recommandation:

- Traiter tout echec d'ecriture de recu comme un echec bloquant, sauf 409.
- Deployer/verifier la collection `purchase_receipts` avant activation des achats.
- Stocker aussi `purchaseToken`, `orderId`, `productId`, `userId`, `purchaseTime` et le statut Google.

### P1 - Billing client: achat consomme meme si verification echoue

Fichier: `lib/services/billing_service.dart`

Sur `PurchaseStatus.purchased/restored`, l'app appelle `_verify(p)`, puis `completePurchase(p)` meme quand `ok == false`. Si la verification serveur echoue temporairement, le produit peut etre considere termine cote Play alors que l'utilisateur n'a pas ete credite.

Zone concernee:

- Verification: ligne 79
- Completion inconditionnelle: ligne 82
- Message d'erreur: ligne 87

Recommandation:

- Ne finaliser/consommer l'achat qu'apres confirmation serveur fiable.
- Si Play exige completion rapide, persister localement un achat "verification_pending" et retenter serveur avec idempotence forte.
- Ajouter un endpoint support/reconciliation pour rejouer une verification a partir du purchase token.

### P1 - Result lookup: URLs admin telechargees cote serveur sans garde-fous

Fichier: `api/result-lookup.js`

Les champs admin `pdfUrl` et `apiUrl` sont telecharges par le serveur avec `fetch`, sans allowlist, sans limite de taille, sans timeout explicite et avec CORS public. Comme seuls les admins configurent ces URLs, le risque depend du niveau de confiance admin, mais une erreur de configuration ou un compte admin compromis peut transformer l'endpoint en SSRF/proxy et consommer beaucoup de memoire sur des PDF volumineux.

Zones concernees:

- Fetch PDF: lignes 50-58
- Fetch API externe: lignes 132-143
- CORS `*`: lignes 214-218

Recommandation:

- Restreindre les schemas a `https`.
- Bloquer IP privees/link-local/localhost apres resolution DNS.
- Ajouter timeout, limite de taille telechargee et validation `Content-Type`.
- Restreindre CORS aux domaines OnBuch si l'endpoint n'est pas volontairement public.

### P1 - Tuteur IA: `examUrl` fourni par l'app est telecharge cote serveur

Fichier: `functions/tutor-ai/src/main.js`

`examUrl` est lu depuis le payload et telecharge directement par la fonction. Si un utilisateur peut appeler la fonction avec une URL arbitraire, c'est un risque SSRF et de consommation memoire/temps.

Zone concernee:

- `fetch(examUrl)`: lignes 534-540

Recommandation:

- N'accepter que des URLs Appwrite Storage ou domaines explicitement autorises.
- Ajouter timeout, limite de taille et validation PDF.
- Refuser IP internes et redirections vers IP internes.

### P1 - Secret Appwrite deja signale comme expose

Fichier: `CLAUDE.md`

Le document indique que la cle API Appwrite serveur a ete "Exposee en chat - A REGENERER".

Zone concernee:

- `CLAUDE.md:181`

Recommandation:

- Regenerer la cle Appwrite serveur.
- Mettre a jour les variables d'environnement Appwrite/Vercel.
- Verifier les logs d'usage et reduire les scopes au strict minimum.

### P2 - Admin: erreur TypeScript bloquante

Fichier: `admin/src/routes/c/[id]/+page.svelte`

`resourceById($page.params.id)` recoit potentiellement `undefined`.

Zone concernee:

- ligne 26

Correction probable:

```ts
$: resource = resourceById($page.params.id ?? '');
```

ou faire evoluer `resourceById` pour accepter `string | undefined`.

### P2 - Admin: dette accessibilite

Fichiers:

- `admin/src/routes/annales/+page.svelte`
- `admin/src/routes/results/+page.svelte`

Plusieurs `<label>` servent de titres de groupes sans controle associe. Remplacer par `div`/`p` avec classe de label visuel, ou associer correctement via `for`/`id` quand il y a un controle.

## Points positifs

- Les secrets principaux ne sont pas embarques cote app mobile; les cles serveur sont lues depuis l'environnement.
- Le rachat de code verifie le JWT Appwrite cote serveur avant de crediter.
- Les documents utilisateur sensibles sont globalement crees avec permissions `read/update/delete` par utilisateur.
- Le correctif de routage annales utilise un `rootNavigatorKey`, ce qui est coherent avec le symptome d'ecran noir depuis une route hors Shell.

## Suite recommandee

1. Corriger les flux credits/achats avant tout volume important de paiements.
2. Corriger `npm run check` admin et planifier la mise a jour SvelteKit/Vite/Svelte.
3. Ajouter garde-fous reseau sur `result-lookup` et `tutor-ai`.
4. Regenerer la cle Appwrite signalee exposee.
5. Lancer `flutter analyze/test/build` dans un environnement Flutter.
