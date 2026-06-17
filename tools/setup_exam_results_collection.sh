#!/usr/bin/env bash
# Crée la collection `exam_results` (+ attributs + index de recherche) sur
# Appwrite via l'API REST. Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_exam_results_collection.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="exam_results"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

api() { # method path json
  curl -sS -X "$1" "$ENDPOINT$2" \
    -H "X-Appwrite-Project: $PROJECT" \
    -H "X-Appwrite-Key: $KEY" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'
}

echo "── Collection '$COLLECTION' ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Exam results\",\"permissions\":[\"read(\\\"any\\\")\"],\"documentSecurity\":false}"

str() { # key size required
  echo "• $1"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
    "{\"key\":\"$1\",\"size\":$2,\"required\":$3}"
}
bool() { # key required
  echo "• $1 (bool)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" \
    "{\"key\":\"$1\",\"required\":$2}"
}

echo "── Attributs ──"
str examType      60   true
str serie         10   false
str year          10   false
str tableNumber   40   true
str candidateName 160  true
str center        160  false
str city          80   false
bool admitted          true
str mention       40   false
str average       20   false
str threshold     20   false

echo "── Attente que examType + tableNumber soient 'available' ──"
for i in $(seq 1 30); do
  st=$(curl -sS "$ENDPOINT/databases/$DB/collections/$COLLECTION/attributes" \
        -H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" \
       | python3 -c "import sys,json
a={x['key']:x['status'] for x in json.load(sys.stdin)['attributes']}
print('ok' if a.get('examType')=='available' and a.get('tableNumber')=='available' else 'wait')" 2>/dev/null || echo wait)
  [ "$st" = "ok" ] && { echo "  prêts."; break; }
  echo "  …"; sleep 2
done

echo "── Index de recherche (examType + tableNumber) ──"
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_lookup\",\"type\":\"key\",\"attributes\":[\"examType\",\"tableNumber\"],\"orders\":[\"ASC\",\"ASC\"]}"

echo "── Terminé. ──"
