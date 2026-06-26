#!/usr/bin/env bash
# Crée la collection `bourses` : bourses d'études (page Orientation → « Bourses »).
# Gérée par l'admin (back-office), lecture publique. L'app retombe sur une liste
# curée embarquée (lib/data/bourses.dart) tant que la collection est vide.
# Idempotent (409 = déjà existant, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_bourses.sh
# Clé API **serveur** (scope databases.write).

set -euo pipefail
EP="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJ="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COL="bourses"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur, scope databases.write)}"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$EP$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $2\n" || true; }

echo "── Collection '$COL' (lecture publique, écriture admin) ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COL\",\"name\":\"Bourses\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

str() { echo "  • $1 (string $2)"; api POST "/databases/$DB/collections/$COL/attributes/string" "{\"key\":\"$1\",\"size\":$2,\"required\":false}"; }
int() { echo "  • $1 (int)"; api POST "/databases/$DB/collections/$COL/attributes/integer" "{\"key\":\"$1\",\"required\":false,\"min\":0,\"max\":999999}"; }
bool() { echo "  • $1 (bool)"; api POST "/databases/$DB/collections/$COL/attributes/boolean" "{\"key\":\"$1\",\"required\":false}"; }

echo "── Attributs ──"
str title 200       # « Bourse du gouvernement chinois (CSC) »
str provider 160    # organisme, ex. « Gouvernement chinois »
str level 120       # niveaux, ex. « Licence · Master · Doctorat »
str destination 120 # pays/zone, ex. « Chine », « Cameroun »
str coverage 200    # prise en charge, ex. « Frais + logement + allocation »
str deadline 120    # texte libre, ex. « Mars (annuel) »
str description 2000
str link 500        # lien officiel / candidature
str tags 300        # mots-clés, séparés par des virgules
int order           # tri d'affichage
bool active         # cocher pour afficher

echo
echo "Terminé. Ajoute/édite les bourses depuis le back-office (ressource"
echo "« Bourses »). Tant que la collection est vide, l'app affiche la liste"
echo "curée embarquée."
