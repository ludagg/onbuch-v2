# Administration OnBuch — Gestion via la console Appwrite

L'administration se fait **directement dans la console Appwrite** (pas d'interface admin dans l'app pour l'instant).

- Console : https://cloud.appwrite.io → projet **onbuch** (`6a30463b00001375e229`)
- Base de données : **onbuchprimary** (`6a3047f8001d11d1b3c1`)
- Endpoint : `https://nyc.cloud.appwrite.io/v1`

## Rôles & autorisation

L'autorisation est imposée **côté serveur** par les **Teams** Appwrite (pas par le champ `users.role`, qui n'est qu'une métadonnée) :

| Team | Droits sur le contenu |
|---|---|
| `admins` | créer / modifier / supprimer |
| `editors` | créer / modifier |

> La **console** (et la clé API) a tous les droits quoi qu'il arrive — ces Teams servent à autoriser des utilisateurs de l'app à écrire, le jour où une interface admin in-app sera ajoutée.

**Désigner un admin** : Console → Auth → Teams → `Admins` → *Add membership* (par e-mail de l'utilisateur).

## Publier un article (fil OnBuch)

Console → Databases → onbuchprimary → collection **`articles`** → *Create document*.

| Champ | Obligatoire | Détail |
|---|---|---|
| `title` | ✅ | Titre de l'article |
| `category` | — | `Examens`, `Bourses`, `Conseil`, `Concours`, `Alerte` (couleur auto) |
| `source` | — | défaut `OnBuch` |
| `imageUrl` | — | URL d'une image (sinon icône par défaut) |
| `body` | — | Contenu (optionnel pour l'instant) |
| `featured` | — | `true` = grande carte vedette en haut du fil |
| `publishedAt` | — | date/heure ; sinon la date de création est utilisée |

Permissions : la collection est en `read("any")` → tout article créé est **public** automatiquement, rien à configurer par document. Les articles s'affichent du plus récent au plus ancien ; mettre **un seul** `featured = true`.

## Gérer les examens (carrousel d'accueil)

Console → Databases → onbuchprimary → collection **`exams`**.

| Champ | Détail |
|---|---|
| `label` | ex. `Baccalauréat 2026` |
| `examDate` | date/heure de début des épreuves |
| `resultsDate` | date prévue des résultats (optionnel) |
| `status` | `auto` (par défaut), ou forcer : `upcoming`, `awaiting`, `published` |
| `order` | ordre d'affichage (1, 2, 3…) |

**États (calculés automatiquement quand `status = auto`)** :
- avant `examDate` → **À venir** : compte à rebours vers l'examen.
- après `examDate`, avant `resultsDate` → **En attente** : compte à rebours vers les résultats (ou message « publication imminente » si `resultsDate` est vide).
- après `resultsDate` → **Résultats disponibles**.

Pour publier les résultats manuellement (sans attendre la date), mettre `status = published`. Pour figer un état, utiliser `upcoming` / `awaiting`.

## À venir (même principe)

Quand on ajoutera d'autres contenus pilotés serveur (examens & dates, événements/partenaires, annales PDF…), ils suivront le même modèle : collection avec `read("any")` + écriture réservée à `team:admins` / `team:editors`, gérés depuis la console.
