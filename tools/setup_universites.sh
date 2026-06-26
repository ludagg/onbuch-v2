#!/usr/bin/env bash
# Crée la collection `universities` : annuaire des universités camerounaises
# (page Orientation → « Université »). Géré par l'admin (back-office), lecture
# publique. L'app retombe sur une liste curée embarquée (lib/data/universities.dart)
# tant que la collection est vide. Idempotent (409 = déjà existant, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_universites.sh
# Clé API **serveur** (scope databases.write).

set -euo pipefail
EP="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJ="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COL="universities"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur, scope databases.write)}"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $2\n" || true; }

echo "── Collection '$COL' (lecture publique, écriture admin) ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COL\",\"name\":\"Universités\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

str() { echo "  • $1 (string $2)"; api POST "/databases/$DB/collections/$COL/attributes/string" "{\"key\":\"$1\",\"size\":$2,\"required\":false}"; }
int() { echo "  • $1 (int)"; api POST "/databases/$DB/collections/$COL/attributes/integer" "{\"key\":\"$1\",\"required\":false,\"min\":0,\"max\":999999}"; }
bool() { echo "  • $1 (bool)"; api POST "/databases/$DB/collections/$COL/attributes/boolean" "{\"key\":\"$1\",\"required\":false}"; }

echo "── Attributs ──"
str name 200        # « Université de Yaoundé I »
str acronym 20      # « UY1 »
str city 80         # « Yaoundé »
str type 20         # « Publique » | « Privée »
str fields 600      # domaines phares, séparés par des virgules
str website 500     # site officiel
str description 2000
int founded         # année de création
int rank            # classement national (1 = en tête ; 0 = non classé)
int order           # tri d'affichage
bool active         # cocher pour afficher

echo
echo "Terminé. Ajoute/édite les universités depuis le back-office (ressource"
echo "« Universités »). Tant que la collection est vide, l'app affiche la liste"
echo "curée embarquée."
