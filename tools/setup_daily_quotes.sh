#!/usr/bin/env bash
# Crée la collection `daily_quotes` : citations motivantes envoyées en push
# chaque matin (07 h Cameroun) par la fonction `review-nudge`. Configurable par
# l'admin (back-office). Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_daily_quotes.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="daily_quotes"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -o /dev/null -w "  [%{http_code}] $2\n" || true; }

echo "── Collection '$COLLECTION' (lecture publique, écriture admin) ──"
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Citations du jour\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}"

str() { # key size required
  echo "  • $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" "{\"key\":\"$1\",\"size\":$2,\"required\":$3}"
}

echo "── Attributs ──"
str text 280 true
str author 80 false
echo "  • active (bool)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" "{\"key\":\"active\",\"required\":false}"
echo "  • order (int)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" "{\"key\":\"order\",\"required\":false,\"min\":0,\"max\":9999}"

sleep 2
echo "── Index (tri par order ASC) ──"
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_order\",\"type\":\"key\",\"attributes\":[\"order\"],\"orders\":[\"ASC\"]}"

# ── Amorçage : citations de départ (idempotent via documentId fixe) ───────────
# L'admin peut les éditer / en ajouter depuis le back-office par la suite.
sleep 2
echo "── Amorçage des citations ──"
seed() { # id order author text
  local id="$1" order="$2" author="$3" text="$4"
  local data
  data=$(python3 - "$order" "$author" "$text" <<'PY'
import json,sys
print(json.dumps({"text":sys.argv[3],"author":sys.argv[2],"active":True,"order":int(sys.argv[1])}))
PY
)
  curl -sS -X POST "$ENDPOINT/databases/$DB/collections/$COLLECTION/documents" "${H[@]}" \
    -d "{\"documentId\":\"$id\",\"data\":$data}" -o /dev/null -w "  [%{http_code}] $id\n" || true
}

seed quote001 1  "Léo"              "Chaque petit effort d'aujourd'hui construit le grand résultat de demain. Au travail 💪"
seed quote002 2  "Nelson Mandela"   "L'éducation est l'arme la plus puissante pour changer le monde."
seed quote003 3  "Léo"              "Tu n'as pas besoin d'être parfait pour commencer, mais commence pour devenir bon."
seed quote004 4  "Proverbe africain" "Seul on va plus vite, mais ensemble on va plus loin. Révise, pose tes questions à Léo 📚"
seed quote005 5  "Léo"              "Une page lue aujourd'hui, c'est une question de moins qui te fera peur à l'examen."
seed quote006 6  "Confucius"        "Peu importe la lenteur à laquelle tu avances, tant que tu n'abandonnes pas."
seed quote007 7  "Léo"              "Le talent ouvre la porte, mais c'est le travail régulier qui te fait entrer."
seed quote008 8  "Albert Einstein"  "Ce n'est pas que je suis si intelligent, c'est que je reste plus longtemps sur les problèmes."
seed quote009 9  "Léo"              "Un exercice qui te résiste est un muscle qui grandit. Ne lâche pas 🔥"
seed quote010 10 "Proverbe camerounais" "La patience cuit même la pierre. Continue, tes efforts vont payer."
seed quote011 11 "Léo"              "Réviser 30 minutes par jour bat largement 5 heures la veille de l'examen."
seed quote012 12 "Mandela"          "Cela semble toujours impossible, jusqu'à ce qu'on le fasse."
seed quote013 13 "Léo"              "Crois en toi autant que Léo croit en toi. Tu es capable ✨"
seed quote014 14 "Aristote"         "Nous sommes ce que nous faisons de manière répétée. L'excellence est donc une habitude."
seed quote015 15 "Léo"              "Aujourd'hui est une nouvelle chance de comprendre ce qui te bloquait hier."
seed quote016 16 "Proverbe africain" "L'eau goutte à goutte finit par creuser le roc. Avance pas à pas."
seed quote017 17 "Léo"              "Les bonnes notes ne tombent pas du ciel : elles tombent des cahiers bien remplis."
seed quote018 18 "Walt Disney"      "La meilleure façon de commencer est d'arrêter de parler et de se mettre à faire."
seed quote019 19 "Léo"              "Ta seule limite, c'est celle que tu acceptes. Vise plus haut 🚀"
seed quote020 20 "Léo"              "Pose une question idiote aujourd'hui pour éviter une erreur grave à l'examen."
seed quote021 21 "Sénèque"          "Ce n'est pas parce que les choses sont difficiles que nous n'osons pas ; c'est parce que nous n'osons pas qu'elles sont difficiles."
seed quote022 22 "Léo"              "Discipline aujourd'hui, liberté demain. Un chapitre à la fois 📖"
seed quote023 23 "Proverbe africain" "Le savoir est une lumière qui ne s'éteint jamais, même la nuit."
seed quote024 24 "Léo"              "Repose-toi si tu es fatigué, mais n'abandonne jamais. Léo est là pour t'aider 🦁"

echo
echo "Terminé. Gère les citations depuis le back-office → « Citations du jour »."
