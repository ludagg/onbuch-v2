#!/usr/bin/env bash
# Collection `order_settings` : numéro WhatsApp dédié aux PRÉCOMMANDES
# (fascicules…), géré par l'admin, séparé des réseaux sociaux. L'app lit
# l'entrée active. Idempotent (409 ignorés).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_order_settings.sh
set -u
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
EP="https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
PROJ="6a30463b00001375e229"
COL="order_settings"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -s -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  $1 $2 -> %{http_code}\n"; }

echo "→ Collection $COL (read public, écriture team:admins)"
api POST "/collections" "{\"collectionId\":\"$COL\",\"name\":\"Réglages commandes\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

echo "→ Attributs"
api POST "/collections/$COL/attributes/string"  '{"key":"whatsapp","size":64,"required":true}'
api POST "/collections/$COL/attributes/string"  '{"key":"label","size":128,"required":false,"default":"Précommandes"}'
api POST "/collections/$COL/attributes/string"  '{"key":"note","size":512,"required":false}'
api POST "/collections/$COL/attributes/boolean" '{"key":"active","required":false,"default":true}'
api POST "/collections/$COL/attributes/integer" '{"key":"order","required":false,"default":0}'
echo "Terminé."
