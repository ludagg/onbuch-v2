#!/usr/bin/env bash
# Parrainage : collection `referrals` (1 doc par filleul → un seul parrainage
# possible) + champ `referralCode` sur `users` (+ index pour la recherche par
# code). La récompense (crédits) est accordée côté serveur par `api/referral.js`.
# Idempotent : les 409 (déjà existant) sont ignorés.
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_referrals.sh
set -u
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
EP="https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
PROJ="6a30463b00001375e229"
COL="referrals"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")

api() { curl -s -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  $1 $2 -> %{http_code}\n"; }

echo "→ Champ referralCode sur users (+ index de recherche)"
api POST "/collections/users/attributes/string" '{"key":"referralCode","size":16,"required":false,"default":""}'
api POST "/collections/users/attributes/string" '{"key":"referredBy","size":64,"required":false,"default":""}'
sleep 4
api POST "/collections/users/indexes" '{"key":"by_referral_code","type":"key","attributes":["referralCode"],"orders":["ASC"]}'

echo "→ Collection $COL (documentSecurity ; écriture serveur, lecture propriétaire au niveau doc)"
api POST "/collections" '{"collectionId":"'"$COL"'","name":"Referrals","documentSecurity":true,"permissions":[]}'

echo "→ Attributs"
api POST "/collections/$COL/attributes/string"  '{"key":"referrerUid","size":64,"required":true}'
api POST "/collections/$COL/attributes/string"  '{"key":"refereeUid","size":64,"required":true}'
api POST "/collections/$COL/attributes/string"  '{"key":"code","size":16,"required":false,"default":""}'
api POST "/collections/$COL/attributes/string"  '{"key":"status","size":16,"required":false,"default":"pending"}'
api POST "/collections/$COL/attributes/integer" '{"key":"refereeBonus","required":false,"default":0}'
api POST "/collections/$COL/attributes/integer" '{"key":"referrerBonus","required":false,"default":0}'
api POST "/collections/$COL/attributes/string"  '{"key":"createdAt","size":40,"required":false,"default":""}'
api POST "/collections/$COL/attributes/string"  '{"key":"rewardedAt","size":40,"required":false,"default":""}'

echo "→ Attente disponibilité des attributs…"
sleep 6

echo "→ Index (stats parrain : filleuls par referrerUid)"
api POST "/collections/$COL/indexes" '{"key":"by_referrer","type":"key","attributes":["referrerUid"],"orders":["ASC"]}'

echo "Terminé."
