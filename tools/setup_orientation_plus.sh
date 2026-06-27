#!/usr/bin/env bash
# Enrichit l'orientation :
#  - ajoute les champs « fiche école » à la collection `universities` ;
#  - crée la collection `metiers` (fiches métiers, gérées par l'admin).
# Idempotent (409 ignorés).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_orientation_plus.sh
set -u
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
EP="https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
PROJ="6a30463b00001375e229"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -s -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  $1 ${2##*/collections/} -> %{http_code}\n"; }

echo "→ Champs fiche école sur universities"
for f in \
  '{"key":"tuition","size":256,"required":false}' \
  '{"key":"admission","size":2000,"required":false}' \
  '{"key":"registrationDates","size":512,"required":false}' \
  '{"key":"documents","size":1500,"required":false}' \
  '{"key":"places","size":128,"required":false}' \
  '{"key":"successRate","size":64,"required":false}' \
  '{"key":"accreditation","size":512,"required":false}' \
  '{"key":"campuses","size":16384,"required":false}' \
  '{"key":"residences","size":16384,"required":false}'
do api POST "/collections/universities/attributes/string" "$f"; done

echo "→ Collection metiers (read public, écriture team:admins)"
api POST "/collections" '{"collectionId":"metiers","name":"Métiers","permissions":["read(\"any\")","create(\"team:admins\")","update(\"team:admins\")","delete(\"team:admins\")"],"documentSecurity":false}'
echo "→ Attributs metiers"
for f in \
  '{"key":"name","size":160,"required":true}' \
  '{"key":"sector","size":128,"required":false}' \
  '{"key":"description","size":2000,"required":false}' \
  '{"key":"skills","size":1200,"required":false}' \
  '{"key":"educationLevel","size":256,"required":false}' \
  '{"key":"prospects","size":1200,"required":false}' \
  '{"key":"careerPath","size":1200,"required":false}' \
  '{"key":"relatedFilieres","size":600,"required":false}' \
  '{"key":"salary","size":256,"required":false}' \
  '{"key":"testimonials","size":3000,"required":false}' \
  '{"key":"icon","size":48,"required":false}'
do api POST "/collections/metiers/attributes/string" "$f"; done
api POST "/collections/metiers/attributes/integer" '{"key":"order","required":false,"default":0}'
api POST "/collections/metiers/attributes/boolean" '{"key":"active","required":false,"default":true}'
echo "Terminé."
