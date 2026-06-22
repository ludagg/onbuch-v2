#!/usr/bin/env bash
# Crée la collection `payment_requests` : les demandes d'achat de crédits via
# mobile money (Orange / MTN), gérées par le bot Telegram @OnBuchCreditsBot.
#
# Flux : l'utilisateur dépose sur un numéro Orange/MTN, colle le SMS au bot →
# une demande `pending` est créée → l'admin valide (✅/❌ dans le groupe admin) →
# le bot génère un CODE à usage unique → l'utilisateur saisit ce code dans l'app
# (fonction `redeem-code`) qui crédite `tutor_quota`.
#
# Collection VERROUILLÉE serveur (aucune permission publique) : les codes ne sont
# jamais énumérables côté client. Seuls la clé serveur (bot) et la fonction
# `redeem-code` y accèdent.
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_payments_collection.sh
# Clé serveur avec scope databases.write. Idempotent (409 = déjà là, ignoré).

set -euo pipefail
ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="payment_requests"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur databases.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── Collection '$COLLECTION' (lecture admins, écriture serveur) ──"
# Lecture/écriture réservées aux admins (back-office) + clé serveur (bot/redeem).
# Les utilisateurs normaux n'y ont AUCUN accès → codes non énumérables.
PERMS='["read(\"team:admins\")","update(\"team:admins\")"]'
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Paiements (crédits)\",\"permissions\":$PERMS,\"documentSecurity\":false}" >/dev/null || true
# Idempotent : remet les permissions à jour si la collection existait déjà.
api PUT "/databases/$DB/collections/$COLLECTION" \
  "{\"name\":\"Paiements (crédits)\",\"permissions\":$PERMS,\"documentSecurity\":false}" >/dev/null || true

str() { echo "• attr $1 (string $2)"; api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
  "{\"key\":\"$1\",\"size\":$2,\"required\":$3}" >/dev/null || true; }
int() { echo "• attr $1 (int)"; api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" \
  "{\"key\":\"$1\",\"required\":false,\"min\":0,\"max\":100000000}" >/dev/null || true; }

echo "── Attributs ──"
str telegramUserId 32 false   # ID Telegram de l'acheteur
str telegramUsername 64 false # @handle (si dispo)
str telegramChatId 32 false   # chat où renvoyer le code
str operator 16 false         # MTN | Orange
int amount                    # montant déposé (FCFA)
int credits                   # crédits accordés (via convertisseur)
str rawMessage 2000 false     # SMS collé (preuve)
str txnId 64 false            # ID de transaction parsé
str senderNumber 32 false     # numéro émetteur parsé
str status 16 false           # pending | approved | rejected | redeemed | expired
str code 16 false             # code à usage unique (généré à l'approbation)
str reviewedBy 64 false       # admin ayant validé/rejeté
str reviewedAt 32 false       # ISO
str redeemedByUid 64 false    # UID OnBuch ayant racheté le code
str redeemedAt 32 false       # ISO
str createdAt 32 false        # ISO
str expiresAt 32 false        # ISO (code valable 24 h)

echo "── Index ──"
sleep 2 # laisse les attributs se créer avant d'indexer
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_code\",\"type\":\"key\",\"attributes\":[\"code\"]}" >/dev/null || true
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_status\",\"type\":\"key\",\"attributes\":[\"status\"]}" >/dev/null || true
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_tg\",\"type\":\"key\",\"attributes\":[\"telegramUserId\"]}" >/dev/null || true

echo
echo "Terminé. Collection '$COLLECTION' prête (serveur uniquement)."
