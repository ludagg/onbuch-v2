#!/usr/bin/env bash
# Ajoute à la collection `users` les attributs « ambitions universitaires »
# collectés à la création du profil (étape 3 de l'onboarding).
# Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_users_profile_attributes.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="users"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

api() { # method path json
  curl -sS -X "$1" "$ENDPOINT$2" \
    -H "X-Appwrite-Project: $PROJECT" \
    -H "X-Appwrite-Key: $KEY" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'
}

str() { # key size
  echo "• $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
    "{\"key\":\"$1\",\"size\":$2,\"required\":false}"
}

echo "── Attributs ambitions sur la collection '$COLLECTION' ──"
str studyField 64        # domaine d'études visé (ex. « Santé / Médecine »)
str careerGoal 128       # métier de rêve (texte libre)
str studyDestination 64  # où étudier (ex. « France », « Cameroun »)

echo
echo "Terminé. (409 = attribut déjà présent, sans gravité.)"
