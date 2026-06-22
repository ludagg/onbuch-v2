#!/usr/bin/env bash
# Crée la collection `annales` : les épreuves (sujets, corrigés, vidéos) que
# l'admin rattache à un examen → série/spécialité → matière → année.
# La taxonomie de navigation (examens/séries/matières) reste statique côté app
# (`lib/data/exam_taxonomy.dart`) ; cette collection porte les VRAIS documents.
# Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_annales_collection.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="annales"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── Collection '$COLLECTION' ──"
# Lecture publique (l'app affiche le catalogue), écriture réservée aux admins.
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Annales\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}" >/dev/null || true

str() { # key size required
  echo "• attr $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
    "{\"key\":\"$1\",\"size\":$2,\"required\":$3}" >/dev/null || true
}
echo "── Attributs ──"
str exam 64 true       # examen — EXACT : BEPC, CAP, Probatoire, Baccalauréat, BT, BTS, HND, GCE O Level, GCE A Level, Concours
str track 160 false    # série / spécialité (libellé de la feuille), ex. « D — Maths & Sc. de la vie », « Génie Civil », « Science »
str subject 96 true    # matière, ex. « Mathématiques »
str year 9 false       # année, ex. « 2024 »
str session 48 false   # session, ex. « Juin », « Session normale »
str type 16 false      # sujet | corrige | video
str title 200 true     # titre affiché, ex. « Bac D — Mathématiques 2024 »
str fileUrl 1024 false # lien du document (PDF/vidéo) — storage Appwrite ou externe
echo "• attr premium (bool)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" \
  "{\"key\":\"premium\",\"required\":false}" >/dev/null || true
echo "• attr order (int)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" \
  "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":99999}" >/dev/null || true

echo "── Index ──"
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_exam\",\"type\":\"key\",\"attributes\":[\"exam\"]}" >/dev/null || true
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_lookup\",\"type\":\"key\",\"attributes\":[\"exam\",\"subject\"]}" >/dev/null || true

echo
echo "Terminé. L'admin peut ajouter des épreuves depuis le back-office"
echo "(collection « Annales ») — examen + série/spécialité + matière + année + lien."
