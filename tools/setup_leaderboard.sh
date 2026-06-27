#!/usr/bin/env bash
# Crée la collection `leaderboard` (classement / ligues façon Duolingo).
# Chaque élève publie son entrée (read public, écriture propriétaire) :
#   uid, name, level, xp, weeklyXp, league, weekId, updatedAt.
# Idempotent : les 409 (déjà existant) sont ignorés.
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_leaderboard.sh
set -u
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
EP="https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
PROJ="6a30463b00001375e229"
COL="leaderboard"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")

api() { curl -s -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  $1 $2 -> %{http_code}\n"; }

echo "→ Collection $COL (documentSecurity, create=users, read public au niveau doc)"
api POST "/collections" '{"collectionId":"'"$COL"'","name":"Leaderboard","documentSecurity":true,"permissions":["create(\"users\")","read(\"any\")"]}'

echo "→ Attributs"
api POST "/collections/$COL/attributes/string"  '{"key":"uid","size":64,"required":true}'
api POST "/collections/$COL/attributes/string"  '{"key":"name","size":128,"required":false,"default":"Élève"}'
api POST "/collections/$COL/attributes/integer" '{"key":"level","required":false,"default":1}'
api POST "/collections/$COL/attributes/integer" '{"key":"xp","required":false,"default":0}'
api POST "/collections/$COL/attributes/integer" '{"key":"weeklyXp","required":false,"default":0}'
api POST "/collections/$COL/attributes/string"  '{"key":"league","size":32,"required":false,"default":"Bronze"}'
api POST "/collections/$COL/attributes/string"  '{"key":"weekId","size":16,"required":false,"default":""}'
api POST "/collections/$COL/attributes/string"  '{"key":"updatedAt","size":40,"required":false,"default":""}'

echo "→ Attente disponibilité des attributs…"
sleep 6

echo "→ Index (filtre semaine+ligue, tri par weeklyXp)"
api POST "/collections/$COL/indexes" '{"key":"rank","type":"key","attributes":["weekId","league","weeklyXp"],"orders":["ASC","ASC","DESC"]}'
api POST "/collections/$COL/indexes" '{"key":"by_uid","type":"key","attributes":["uid"],"orders":["ASC"]}'

echo "Terminé."
