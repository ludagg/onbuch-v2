# Achats intégrés — crédits Tuteur (Google Play Billing)

Les **crédits Tuteur** sont des biens numériques : le Play Store impose son
système de facturation. L'achat est **vérifié côté serveur** (fonction Appwrite
`verify-purchase`) avant que les crédits ne soient ajoutés — l'app ne crédite
jamais elle-même.

> ⚠️ Les **frais de dossier concours** ne passent **pas** par Play Billing
> (service réel → Google l'interdit + montant variable). Ils restent en Mobile
> Money. Voir le parcours d'inscription concours.

> ⚠️ Fonctionnalité **native** (`in_app_purchase`) → demande une **nouvelle
> release** Shorebird (pas un patch), et un test depuis une build installée via
> le Play Store.

## ✅ Déjà fait (code)
- `BillingService` (`lib/services/billing_service.dart`) : produits, achat
  consommable, écoute du flux, vérification serveur, consommation.
- Paywall (`lib/widgets/paywall_sheet.dart`) branché sur Play Billing.
- Fonction `functions/verify-purchase/` (vérif Google + crédit).
- Collection `purchase_receipts` (idempotence, serveur uniquement) — créée.

## À faire de ton côté

### 1. Play Console — produits in-app (consommables)
Play Console → ton app → **Monetize → Products → In-app products** → crée 3
produits **consommables** avec ces **IDs exacts** :

| Product ID | Crédits |
|---|---|
| `ob_credits_5` | 5 |
| `ob_credits_15` | 15 |
| `ob_credits_40` | 40 |

(Pour changer la liste : `BillingService.creditProducts` **et** `CREDIT_PRODUCTS`
dans la fonction doivent rester synchronisés.)

### 2. Compte de service Google (vérification serveur)
1. Google Play Console → **Setup → API access** → lie un projet Google Cloud.
2. Crée un **compte de service** avec le rôle permettant de lire les achats
   (Android Publisher), accorde-lui l'accès à l'app, télécharge la **clé JSON**.

### 3. Déployer la fonction `verify-purchase`
Appwrite Console → **Functions → Create function** (runtime Node 22), dépôt
`functions/verify-purchase/`, commande de build `npm install`.
Variables d'environnement :
- `GOOGLE_SERVICE_ACCOUNT` = contenu JSON du compte de service (une ligne)
- `APPWRITE_API_KEY` = clé API serveur (scope `databases.write`)
- (`DATABASE_ID` est optionnel, défaut = base OnBuch)

Active l'option **« exécuter en tant qu'utilisateur connecté »** (l'en-tête
`x-appwrite-user-id` doit être transmis). Scopes/permissions d'exécution : users.

### 4. Tester
Build **release** signée → **Internal testing** sur Play Console → installe via le
Play Store avec un **compte testeur de licence** → achète un pack → vérifie que
le solde augmente (la fonction logge « Credited user … »).

## Dépannage
- **« Achats indisponibles »** dans le paywall : normal hors Play Store
  (sideload) ou si les produits ne sont pas encore actifs côté Play.
- **« vérification échouée »** : vérifie `GOOGLE_SERVICE_ACCOUNT`, l'accès du
  compte de service à l'app, et que les IDs produits correspondent.
