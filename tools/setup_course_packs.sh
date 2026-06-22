#!/usr/bin/env bash
# Packs de cours réels, liés aux classes/séries COMME LES ANNALES :
#  1) enrichit `subjects` (= un pack par matière) de :
#     - exam + track  → rattachement examen → série (comme les annales) ;
#     - premium, priceCredits (prix en crédits OnBuch), coef, freeChapters.
#  2) crée la collection `pack_purchases` (un doc par achat user×matière) ;
#  3) seed les matières de démo (exam=Baccalauréat, track="" = toutes séries).
#
# Achat = déduction des crédits OnBuch (tutor_quota.credits) via l'endpoint
# Vercel /api/buy-pack. Idempotent (409 = déjà là, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_course_packs.sh

set -euo pipefail
ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur databases.write)}"
H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── 1) Champs pack + rattachement classe sur 'subjects' ──"
api POST "/databases/$DB/collections/subjects/attributes/string"  '{"key":"exam","size":64,"required":false}'  >/dev/null || true
api POST "/databases/$DB/collections/subjects/attributes/string"  '{"key":"track","size":160,"required":false}' >/dev/null || true
api POST "/databases/$DB/collections/subjects/attributes/boolean" '{"key":"premium","required":false,"default":false}'       >/dev/null || true
api POST "/databases/$DB/collections/subjects/attributes/integer" '{"key":"priceCredits","required":false,"min":0,"max":100000,"default":0}' >/dev/null || true
api POST "/databases/$DB/collections/subjects/attributes/integer" '{"key":"coef","required":false,"min":0,"max":20,"default":0}'           >/dev/null || true
api POST "/databases/$DB/collections/subjects/attributes/integer" '{"key":"freeChapters","required":false,"min":0,"max":999,"default":2}'  >/dev/null || true

echo "── 2) Collection 'pack_purchases' (propriété par utilisateur) ──"
api POST "/databases/$DB/collections" \
  '{"collectionId":"pack_purchases","name":"Achats de packs","permissions":["create(\"users\")"],"documentSecurity":true}' >/dev/null || true
api POST "/databases/$DB/collections/pack_purchases/attributes/string"  '{"key":"uid","size":64,"required":false}'       >/dev/null || true
api POST "/databases/$DB/collections/pack_purchases/attributes/string"  '{"key":"subjectId","size":64,"required":false}' >/dev/null || true
api POST "/databases/$DB/collections/pack_purchases/attributes/integer" '{"key":"priceCredits","required":false,"min":0,"max":100000}' >/dev/null || true
api POST "/databases/$DB/collections/pack_purchases/attributes/string"  '{"key":"createdAt","size":32,"required":false}' >/dev/null || true
sleep 2
api POST "/databases/$DB/collections/pack_purchases/indexes" '{"key":"idx_uid","type":"key","attributes":["uid"]}'             >/dev/null || true
api POST "/databases/$DB/collections/pack_purchases/indexes" '{"key":"idx_us","type":"key","attributes":["uid","subjectId"]}' >/dev/null || true

echo "── 3) Seed démo : rattache les matières au Baccalauréat (toutes séries) ──"
sleep 2
# Pour la démo, track="" => le pack s'applique à toutes les séries du Bac
# (comme un document d'annales « général »). L'admin créera des packs par série.
ALL=$(curl -sS "${H[@]}" "$ENDPOINT/databases/$DB/collections/subjects/documents?queries%5B%5D=%7B%22method%22%3A%22limit%22%2C%22values%22%3A%5B100%5D%7D")
echo "$ALL" | python3 -c "import sys,json;[print(d['\$id']) for d in json.load(sys.stdin)['documents']]" | while read -r id; do
  api PATCH "/databases/$DB/collections/subjects/documents/$id" '{"data":{"exam":"Baccalauréat","track":""}}' >/dev/null && echo "  • $id → exam=Baccalauréat track=(toutes séries)"
done

echo
echo "Terminé. 'subjects' = packs rattachés examen→série ; 'pack_purchases' prête."
echo "Règle exam/track/prix/premium par matière depuis le back-office."
