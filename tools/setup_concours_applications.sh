#!/usr/bin/env bash
# Collection `concours_applications` : candidatures aux concours, privées par
# utilisateur (document security). Idempotent.
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_concours_applications.sh
set -euo pipefail
EP="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJ="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
COL=concours_applications
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")

echo "── Collection $COL (document security) ──"
curl -sS -X POST "$EP/databases/$DB/collections" "${H[@]}" \
  -d "{\"collectionId\":\"$COL\",\"name\":\"Concours applications\",\"permissions\":[\"create(\\\"users\\\")\"],\"documentSecurity\":true}" \
  -w $'\n[HTTP %{http_code}]\n' || true

str(){ curl -sS -X POST "$EP/databases/$DB/collections/$COL/attributes/string" "${H[@]}" -d "{\"key\":\"$1\",\"size\":$2,\"required\":$3}" -o /dev/null -w "  • $1 [%{http_code}]\n"; }
dt(){ curl -sS -X POST "$EP/databases/$DB/collections/$COL/attributes/datetime" "${H[@]}" -d "{\"key\":\"$1\",\"required\":false}" -o /dev/null -w "  • $1 [%{http_code}]\n"; }

str userId 50 true
str concoursId 60 false
str concoursName 160 true
str status 20 false
str examLabel 60 false
str receiptNo 40 false
dt  createdAt
echo "── Terminé. ──"
