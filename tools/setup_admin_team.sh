#!/usr/bin/env bash
# Crée l'équipe `admins` et lui donne le droit d'écrire sur les collections
# gérées par le back-office. Idempotent.
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_admin_team.sh
# Clé serveur avec scopes : teams.write + databases.write.

set -euo pipefail
ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
TEAM="admins"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")

echo "── Équipe '$TEAM' ──"
curl -sS -X POST "$ENDPOINT/teams" "${H[@]}" \
  -d "{\"teamId\":\"$TEAM\",\"name\":\"Admins\"}" -w $'\n[HTTP %{http_code}]\n' || true

PERMS="[\"read(\\\"any\\\")\",\"create(\\\"team:$TEAM\\\")\",\"update(\\\"team:$TEAM\\\")\",\"delete(\\\"team:$TEAM\\\")\"]"

for COL in notifications articles concours prep_centers concours_resources exam_results exams; do
  NAME=$(curl -sS "$ENDPOINT/databases/$DB/collections/$COL" "${H[@]}" \
    | python3 -c "import sys,json;print(json.load(sys.stdin).get('name','$COL'))" 2>/dev/null || echo "$COL")
  echo "── $COL (write → team:$TEAM) ──"
  curl -sS -X PUT "$ENDPOINT/databases/$DB/collections/$COL" "${H[@]}" \
    -d "{\"name\":\"$NAME\",\"permissions\":$PERMS,\"documentSecurity\":false}" \
    -w $'\n[HTTP %{http_code}]\n' -o /dev/null
done

echo "── Terminé. Ajoute ton compte à l'équipe 'admins' dans la console Appwrite. ──"
