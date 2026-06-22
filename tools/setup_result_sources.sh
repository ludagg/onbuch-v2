#!/usr/bin/env bash
# Crée la collection `result_sources` (sources de résultats configurables par
# l'admin : manuel / PDF / API) + le bucket Storage `result_pdfs` (PDF chargés).
# Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_result_sources.sh
#
# Clé API **serveur** avec scopes `databases.write` et `buckets.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="result_sources"
BUCKET="result_pdfs"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── Collection '$COLLECTION' ──"
# Lecture publique (l'app affiche les sources), écriture réservée aux admins.
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Result sources\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}" >/dev/null || true

str() { # key size required
  echo "• attr $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
    "{\"key\":\"$1\",\"size\":$2,\"required\":$3}" >/dev/null || true
}

echo "── Attributs ──"
str label           160  true
str subtitle        200  false
str icon            8    false
str sourceType      16   false   # manual | pdf | api
str examType        80   false
str year            12   false
str searchLabel     80   false
str searchHint      80   false
str searchMode      16   false   # number | name
str notFoundMessage 240  false
str pdfUrl          2048 false
str pdfName         200  false
str pdfFileId       64   false
str apiUrl          2048 false

echo "• attr order (int)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" \
  "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":99999}" >/dev/null || true
echo "• attr active (bool)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" \
  "{\"key\":\"active\",\"required\":false}" >/dev/null || true

echo "── Attente que 'order' soit 'available' ──"
for i in $(seq 1 30); do
  st=$(curl -sS "$ENDPOINT/databases/$DB/collections/$COLLECTION/attributes" \
        -H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" \
       | python3 -c "import sys,json
a={x['key']:x['status'] for x in json.load(sys.stdin)['attributes']}
print('ok' if a.get('order')=='available' else 'wait')" 2>/dev/null || echo wait)
  [ "$st" = "ok" ] && { echo "  prêt."; break; }
  echo "  …"; sleep 2
done

echo "── Index (tri par ordre) ──"
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_order\",\"type\":\"key\",\"attributes\":[\"order\"],\"orders\":[\"ASC\"]}" >/dev/null || true

echo "── Bucket Storage '$BUCKET' (PDF de résultats) ──"
# Lecture publique (la fonction result-lookup et l'app y accèdent), écriture admins.
# 30 Mo max, PDF uniquement.
api POST "/storage/buckets" \
  "{\"bucketId\":\"$BUCKET\",\"name\":\"Result PDFs\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"fileSecurity\":false,\"enabled\":true,\"maximumFileSize\":31457280,\"allowedFileExtensions\":[\"pdf\"]}" >/dev/null || true

echo
echo "Terminé. Déploie ensuite la fonction 'result-lookup' (functions/result-lookup)"
echo "avec la variable APPWRITE_API_KEY (scope databases.read), puis configure les"
echo "sources depuis le back-office (« Résultats — sources »)."
