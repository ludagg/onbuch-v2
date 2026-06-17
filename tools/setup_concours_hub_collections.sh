#!/usr/bin/env bash
# Crée les collections `prep_centers` et `concours_resources` (hub Concours)
# sur Appwrite via l'API REST. Idempotent (409 = déjà existant, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_concours_hub_collections.sh

set -euo pipefail
ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur, scope databases.write)}"

api() { curl -sS -X "$1" "$ENDPOINT$2" \
  -H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" \
  -H "Content-Type: application/json" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

mkcol() { echo "── Collection $1 ──"; api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$1\",\"name\":\"$2\",\"permissions\":[\"read(\\\"any\\\")\"],\"documentSecurity\":false}"; }
str() { api POST "/databases/$DB/collections/$1/attributes/string" "{\"key\":\"$2\",\"size\":$3,\"required\":$4}"; echo "  • $2"; }
dt()  { api POST "/databases/$DB/collections/$1/attributes/datetime" "{\"key\":\"$2\",\"required\":false}"; echo "  • $2 (datetime)"; }
intg(){ api POST "/databases/$DB/collections/$1/attributes/integer" "{\"key\":\"$2\",\"required\":false}"; echo "  • $2 (int)"; }

mkcol prep_centers "Prep centers"
str prep_centers name 120 true
str prep_centers city 80 true
str prep_centers description 600 false
str prep_centers specialties 200 false
str prep_centers imageUrl 500 false
str prep_centers phone 30 false
str prep_centers link 300 false
str prep_centers address 200 false
str prep_centers eventTitle 160 false
dt  prep_centers eventDate
intg prep_centers order

mkcol concours_resources "Concours resources"
str concours_resources title 160 true
str concours_resources type 20 false
str concours_resources description 400 false
str concours_resources url 500 false
str concours_resources concours 60 false
intg concours_resources order

echo "── Terminé. ──"
