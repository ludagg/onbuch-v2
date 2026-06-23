#!/usr/bin/env bash
# Crée la collection `home_announcements` : annonces configurables affichées en
# tête du carrousel d'accueil (image/couleur, titre, texte, bouton d'action,
# fenêtre de programmation). Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_home_announcements.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="home_announcements"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $2\n" || true; }

echo "── Collection '$COLLECTION' (lecture publique, écriture admin) ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Home announcements\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

str() { # key size required
  echo "  • $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" "{\"key\":\"$1\",\"size\":$2,\"required\":$3}"
}
dt() {
  echo "  • $1 (datetime)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/datetime" "{\"key\":\"$1\",\"required\":false}"
}

echo "── Attributs ──"
str eyebrow 60 false
str title 160 true
str body 400 false
str imageUrl 1024 false
str ctaLabel 60 false
str ctaTarget 1024 false
str bgColor 16 false
str textColor 12 false
dt  startAt
dt  endAt
echo "  • active (bool)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" "{\"key\":\"active\",\"required\":false}"
echo "  • order (int)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":9999}"

# Index pour le tri par `order` (Query.orderAsc('order') côté app). Attendre que
# l'attribut soit prêt avant d'indexer.
sleep 2
echo "── Index ──"
echo "  • idx_order (key sur order ASC)"
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_order\",\"type\":\"key\",\"attributes\":[\"order\"],\"orders\":[\"ASC\"]}"

echo
echo "Terminé. Ajoute tes annonces depuis le back-office → « Annonces (Accueil) »."
