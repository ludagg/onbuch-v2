#!/usr/bin/env bash
# Crée les collections de l'« agent d'études » Léo — Phase 0 (fondations data) :
#   • quiz_attempts   : chaque tentative de QCM (score, erreurs) → mesure de maîtrise
#   • topic_mastery   : maîtrise dérivée par chapitre/topic (0..1)
#   • tutor_threads   : conversations persistantes (mémoire conversationnelle)
#   • student_memory  : mémoire longue de l'élève (forces/faiblesses/objectifs/ton)
#
# Toutes ces collections sont des DONNÉES UTILISATEUR : permission de collection
# `create("users")` + documentSecurity activé (chaque doc est restreint à son
# propriétaire au moment de l'écriture, comme `chapter_progress` / `tutor_jobs`).
#
# Idempotent : relançable sans risque (les conflits 409 « déjà existant » sont OK).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_agent_collections.sh
#
# La clé doit être une clé API **serveur** avec le scope `databases.write`.

set -uo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

api() { # method path json
  curl -sS -X "$1" "$ENDPOINT$2" \
    -H "X-Appwrite-Project: $PROJECT" \
    -H "X-Appwrite-Key: $KEY" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'
}

# Crée une collection de données utilisateur (create("users") + documentSecurity).
make_collection() { # id name
  echo "── Collection '$1' ($2) ──"
  api POST "/databases/$DB/collections" \
    "{\"collectionId\":\"$1\",\"name\":\"$2\",\"permissions\":[\"create(\\\"users\\\")\"],\"documentSecurity\":true}"
}

str() { # collection key size required [default]
  local body="{\"key\":\"$2\",\"size\":$3,\"required\":$4"
  [ -n "${5:-}" ] && body="$body,\"default\":\"$5\""
  body="$body}"
  echo "• $1.$2 (string)"
  api POST "/databases/$DB/collections/$1/attributes/string" "$body"
}
intg() { # collection key required
  echo "• $1.$2 (integer)"
  api POST "/databases/$DB/collections/$1/attributes/integer" \
    "{\"key\":\"$2\",\"required\":$3}"
}
flt() { # collection key required
  echo "• $1.$2 (float)"
  api POST "/databases/$DB/collections/$1/attributes/float" \
    "{\"key\":\"$2\",\"required\":$3}"
}
dtime() { # collection key required
  echo "• $1.$2 (datetime)"
  api POST "/databases/$DB/collections/$1/attributes/datetime" \
    "{\"key\":\"$2\",\"required\":$3}"
}
index() { # collection key attributesCsv  (type=key, order ASC)
  local attrs=""
  IFS=',' read -ra A <<< "$3"
  for a in "${A[@]}"; do attrs="$attrs\"$a\","; done
  attrs="${attrs%,}"
  echo "• index $1.$2 [$3]"
  api POST "/databases/$DB/collections/$1/indexes" \
    "{\"key\":\"$2\",\"type\":\"key\",\"attributes\":[$attrs]}"
}

# ─── quiz_attempts ────────────────────────────────────────────────────────────
make_collection quiz_attempts "Quiz attempts"
str   quiz_attempts userId    64   true
str   quiz_attempts subject   100  false
str   quiz_attempts chapterId 64   false
str   quiz_attempts topic     200  false
intg  quiz_attempts score     true
intg  quiz_attempts total     true
str   quiz_attempts wrong     1000 false   # JSON: indices des questions ratées
dtime quiz_attempts createdAt true

# ─── topic_mastery ────────────────────────────────────────────────────────────
make_collection topic_mastery "Topic mastery"
str   topic_mastery userId         64  true
str   topic_mastery chapterId      64  false
str   topic_mastery subject        100 false
str   topic_mastery topic          200 false
flt   topic_mastery mastery        true   # 0..1
intg  topic_mastery attempts       false
dtime topic_mastery lastReviewedAt false

# ─── tutor_threads ────────────────────────────────────────────────────────────
make_collection tutor_threads "Tutor threads"
str   tutor_threads userId    64     true
str   tutor_threads title     200    false
str   tutor_threads subject   100    false
str   tutor_threads messages  100000 false   # JSON [{role,content}]
str   tutor_threads summary   4000   false
dtime tutor_threads updatedAt false

# ─── student_memory (1 doc par élève, documentId = userId) ────────────────────
make_collection student_memory "Student memory"
str   student_memory userId     64   true
str   student_memory strengths  2000 false
str   student_memory weaknesses 2000 false
str   student_memory goals      1000 false
str   student_memory tone       200  false
str   student_memory notes      4000 false
dtime student_memory lastSeen   false

# ─── Index (best-effort : on attend que les attributs soient « available ») ───
echo "── Index (attente de la disponibilité des attributs) ──"
sleep 8
index quiz_attempts idx_user      userId
index quiz_attempts idx_user_chap userId,chapterId
index topic_mastery idx_user      userId
index tutor_threads idx_user      userId

echo "── Terminé. (409 = déjà existant ; un index en 400 = attribut pas encore prêt, relancer le script) ──"
