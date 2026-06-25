#!/usr/bin/env bash
# Crée la collection `fascicules` : bibliothèque des fascicules (livres PDF)
# OnBuch — affichée dans l'onglet Cours (« Nos fascicules ») et en carte sur
# l'Accueil. Chaque fascicule = un PDF (bucket `annales_files`) + une couverture.
# Géré par l'admin (back-office). Idempotent (409 = déjà existant, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_fascicules.sh
# Clé API **serveur** (scope databases.write).

set -euo pipefail
EP="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJ="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COL="fascicules"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur, scope databases.write)}"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $2\n" || true; }

echo "── Collection '$COL' (lecture publique, écriture admin) ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COL\",\"name\":\"Fascicules\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

str() { echo "  • $1 (string $2)"; api POST "/databases/$DB/collections/$COL/attributes/string" "{\"key\":\"$1\",\"size\":$2,\"required\":false}"; }
echo "── Attributs ──"
str title 300       # titre, ex. « Mathématiques — Terminale C »
str subject 80      # matière, ex. « Mathématiques »
str level 80        # classe, ex. « Terminale C »
str exam 60         # cursus, ex. « Baccalauréat » — vide = tous
str track 80        # séries concernées, ex. « C,D,E,TI » — vide = toutes
str description 2000
str coverUrl 1024   # URL de la couverture (image, bucket annales_files)
str pdfUrl 1024     # URL du PDF (bucket annales_files)
str author 200      # ex. « L'équipe OnBuch, dirigée par Ludovic Aggaï N. »
echo "  • pages (int)"
api POST "/databases/$DB/collections/$COL/attributes/integer" "{\"key\":\"pages\",\"required\":false,\"min\":0,\"max\":100000}"
echo "  • premium (bool)"
api POST "/databases/$DB/collections/$COL/attributes/boolean" "{\"key\":\"premium\",\"required\":false}"
echo "  • order (int)"
api POST "/databases/$DB/collections/$COL/attributes/integer" "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":999999}"
echo "  • active (bool)"
api POST "/databases/$DB/collections/$COL/attributes/boolean" "{\"key\":\"active\",\"required\":false}"

echo
echo "Terminé. Publie un fascicule depuis le back-office (ressource « Fascicules »)"
echo "ou via tools/upload_fascicule.py."
