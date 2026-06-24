#!/usr/bin/env bash
# Module Exercices d'OnBuch : banque d'exercices par matière/classe.
#   - exercise_chapters : chapitres (matière + classe), gérés par l'admin
#   - exercise_sheets    : fiches d'exercices (énoncé + correction), ≥5/chapitre
#   - exercise_progress  : suivi par élève (trouvé / pas trouvé) — privé
# Idempotent (409 = déjà existant, ignoré).
#
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_exercises.sh

set -euo pipefail
ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api(){ curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $1 $2\n" || true; }

mkcol(){ # id name permsJson docSecurity
  echo "── Collection '$1' ──"
  api POST "/databases/$DB/collections" "{\"collectionId\":\"$1\",\"name\":\"$2\",\"permissions\":$3,\"documentSecurity\":$4}"
}
str(){ api POST "/databases/$DB/collections/$1/attributes/string" "{\"key\":\"$2\",\"size\":$3,\"required\":$4}"; echo "  • $2 (string $3)"; }
intt(){ api POST "/databases/$DB/collections/$1/attributes/integer" "{\"key\":\"$2\",\"required\":false,\"min\":0,\"max\":99999}"; echo "  • $2 (int)"; }
dt(){ api POST "/databases/$DB/collections/$1/attributes/datetime" "{\"key\":\"$2\",\"required\":false}"; echo "  • $2 (datetime)"; }
idx(){ api POST "/databases/$DB/collections/$1/indexes" "{\"key\":\"$2\",\"type\":\"key\",\"attributes\":[\"$3\"],\"orders\":[\"ASC\"]}"; echo "  • index $2"; }

PUB='["read(\"any\")","create(\"team:admins\")","update(\"team:admins\")","delete(\"team:admins\")"]'
USERW='["create(\"users\")"]'

mkcol exercise_chapters "Exercices — chapitres" "$PUB" false
str exercise_chapters subject 80 true
str exercise_chapters title 160 true
str exercise_chapters exam 60 false
str exercise_chapters track 40 false
str exercise_chapters levels 120 false
str exercise_chapters description 400 false
intt exercise_chapters order

mkcol exercise_sheets "Exercices — fiches" "$PUB" false
str exercise_sheets chapterId 40 true
str exercise_sheets subject 80 false
str exercise_sheets title 160 true
str exercise_sheets statementPdfUrl 1024 true
str exercise_sheets correctionPdfUrl 1024 false
str exercise_sheets difficulty 16 false
intt exercise_sheets order

mkcol exercise_progress "Exercices — progression (privé)" "$USERW" true
str exercise_progress userId 40 true
str exercise_progress sheetId 40 true
str exercise_progress subject 80 false
str exercise_progress chapterId 40 false
str exercise_progress status 16 false
dt  exercise_progress updatedAt

sleep 2
echo "── Index ──"
idx exercise_chapters idx_order order
idx exercise_sheets idx_chapter chapterId
idx exercise_progress idx_user userId

echo "Terminé. Gère les chapitres et fiches depuis le back-office."
