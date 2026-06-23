#!/usr/bin/env bash
# Crée la collection `course_docs` : documents de cours (PDF) collectés depuis
# `annales` par tools/collect_course_docs.py --write, affichés dans la section
# « Cours PDF » de la page Cours. Idempotent (409 = déjà existant, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_course_docs.sh
# Clé API **serveur** (scope databases.write).

set -euo pipefail
EP="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJ="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COL="course_docs"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur, scope databases.write)}"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $2\n" || true; }

echo "── Collection '$COL' (lecture publique, écriture admin) ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COL\",\"name\":\"Course docs\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

str() { echo "  • $1 (string $2)"; api POST "/databases/$DB/collections/$COL/attributes/string" "{\"key\":\"$1\",\"size\":$2,\"required\":false}"; }
echo "── Attributs (miroir des champs annale + traçabilité) ──"
str title 400
str subject 80
str exam 60
str track 60
str category 40
str year 12
str session 60
str fileUrl 1024
str corrigeUrl 1024
str videoUrl 1024
str sourceId 64    # $id du document annale d'origine
str detect 40      # raison de classement : categorie | titre:<mot>
echo "  • premium (bool)"
api POST "/databases/$DB/collections/$COL/attributes/boolean" "{\"key\":\"premium\",\"required\":false}"
echo "  • order (int)"
api POST "/databases/$DB/collections/$COL/attributes/integer" "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":999999}"

echo
echo "Terminé. Remplis-la ensuite avec :"
echo "  APPWRITE_API_KEY=… python3 tools/collect_course_docs.py --write"
