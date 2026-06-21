#!/usr/bin/env bash
# Crée la collection `social_links` : les liens des réseaux sociaux OnBuch,
# configurés par l'admin et affichés dans l'app (écran Communauté + accueil).
# Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_social_links_collection.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="social_links"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── Collection '$COLLECTION' ──"
# Lecture publique (l'app lit les liens), écriture réservée à l'équipe admins.
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Social links\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}" >/dev/null || true

str() { # key size required
  echo "• attr $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
    "{\"key\":\"$1\",\"size\":$2,\"required\":$3}" >/dev/null || true
}
echo "── Attributs ──"
str platform 24 false     # whatsapp/telegram/tiktok/facebook/youtube/instagram/other
str label 64 true         # nom affiché, ex. « WhatsApp »
str description 160 false # ex. « Groupe d'entraide · 12k membres »
str url 512 true          # lien (https://, wa.me/…, t.me/…)
echo "• attr order (int)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" \
  "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":9999}" >/dev/null || true
echo "• attr active (bool)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" \
  "{\"key\":\"active\",\"required\":false}" >/dev/null || true

echo
echo "Terminé. Ajoute tes liens depuis le back-office (collection '$COLLECTION') :"
echo "  platform=whatsapp · label=WhatsApp · url=https://chat.whatsapp.com/... · active=coché"
