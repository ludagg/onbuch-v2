#!/usr/bin/env bash
# Crée la collection `notifications` (+ ses attributs) sur Appwrite via l'API REST.
# Idempotent : relançable sans risque (les conflits 409 sont ignorés).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_notifications_collection.sh
#
# La clé doit être une clé API **serveur** avec le scope `databases.write`
# (Appwrite Console → Overview → Integrations → API Keys).

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="notifications"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

api() { # method path json
  curl -sS -X "$1" "$ENDPOINT$2" \
    -H "X-Appwrite-Project: $PROJECT" \
    -H "X-Appwrite-Key: $KEY" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'
}

echo "── Création de la collection '$COLLECTION' ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Notifications\",\"permissions\":[\"read(\\\"any\\\")\"],\"documentSecurity\":false}"

echo "── Attributs ──"
# string: key,size,required,default
str() { # key size required default
  local body="{\"key\":\"$1\",\"size\":$2,\"required\":$3"
  [ -n "${4:-}" ] && body="$body,\"default\":\"$4\""
  body="$body}"
  echo "• $1"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" "$body"
}

str title    200  true
str body      1000 false
str type      30   false info
str route     200  false
str imageUrl  500  false

echo "• publishedAt (datetime)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/datetime" \
  "{\"key\":\"publishedAt\",\"required\":false}"

echo "── Terminé. (409 = déjà existant, sans gravité) ──"
