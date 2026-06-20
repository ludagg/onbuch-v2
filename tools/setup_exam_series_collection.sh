#!/usr/bin/env bash
# Crée la collection `exam_series` : les séries / filières proposées à l'élève,
# configurables par cursus (examen). Ex. : Baccalauréat → Enseignement général
# (A, C, D, E…) & technique (F1–F4, G1–G3) ; BTS → filières ; etc.
# L'admin peut ensuite ajouter/modifier les entrées depuis la console Appwrite.
# Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_exam_series_collection.sh
#
# Clé API **serveur** avec scope `databases.write`.

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
COLLECTION="exam_series"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope databases.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── Collection '$COLLECTION' ──"
# Lecture publique (l'app lit le catalogue), écriture réservée à l'équipe admins.
api POST "/databases/$DB/collections" \
  "{\"collectionId\":\"$COLLECTION\",\"name\":\"Exam series\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"documentSecurity\":false}" >/dev/null || true

str() { # key size required
  echo "• attr $1 (string $2)"
  api POST "/databases/$DB/collections/$COLLECTION/attributes/string" \
    "{\"key\":\"$1\",\"size\":$2,\"required\":$3}" >/dev/null || true
}
echo "── Attributs ──"
str exam 64 true        # cursus, ex. « Baccalauréat » (doit matcher la liste de l'app)
str category 64 false   # regroupement, ex. « Enseignement général » / « technique »
str name 128 true       # libellé affiché ET stocké dans le profil, ex. « C — Maths & Sc. physiques »
echo "• attr sortOrder (int)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/integer" \
  "{\"key\":\"sortOrder\",\"required\":false,\"min\":0,\"max\":9999}" >/dev/null || true
echo "• attr active (bool)"
api POST "/databases/$DB/collections/$COLLECTION/attributes/boolean" \
  "{\"key\":\"active\",\"required\":false}" >/dev/null || true

echo "── Index ──"
api POST "/databases/$DB/collections/$COLLECTION/indexes" \
  "{\"key\":\"idx_exam\",\"type\":\"key\",\"attributes\":[\"exam\"]}" >/dev/null || true

# Attendre que les attributs soient « available » avant de seeder.
echo -n "── Attente des attributs"
for _ in $(seq 1 30); do
  st=$(curl -sS "$ENDPOINT/databases/$DB/collections/$COLLECTION/attributes" "${H[@]}")
  if ! grep -q '"status":"processing"' <<<"$st" && grep -q '"key":"active"' <<<"$st"; then break; fi
  echo -n "."; sleep 1
done
echo " ok"

# ── Seed du système scolaire camerounais ─────────────────────────────────────
doc() { # id exam category name sortOrder
  api POST "/databases/$DB/collections/$COLLECTION/documents" \
    "{\"documentId\":\"$1\",\"data\":{\"exam\":\"$2\",\"category\":\"$3\",\"name\":\"$4\",\"sortOrder\":$5,\"active\":true}}" \
    | grep -qE '\[HTTP 20[01]\]|\[HTTP 409\]' && echo "  ✓ $4" || echo "  ⚠ $4 (voir réponse)"
}

echo "── Seed Baccalauréat (général) ──"
doc bac_g_a  "Baccalauréat" "Enseignement général"   "A — Lettres-Philosophie"           10
doc bac_g_c  "Baccalauréat" "Enseignement général"   "C — Maths & Sciences physiques"    11
doc bac_g_d  "Baccalauréat" "Enseignement général"   "D — Maths & Sciences de la vie"    12
doc bac_g_e  "Baccalauréat" "Enseignement général"   "E — Maths & Technique"             13
doc bac_g_ti "Baccalauréat" "Enseignement général"   "TI — Technologies de l'information" 14

echo "── Seed Baccalauréat (technique) ──"
doc bac_t_f1 "Baccalauréat" "Enseignement technique" "F1 — Construction mécanique"       20
doc bac_t_f2 "Baccalauréat" "Enseignement technique" "F2 — Électronique"                 21
doc bac_t_f3 "Baccalauréat" "Enseignement technique" "F3 — Électrotechnique"             22
doc bac_t_f4 "Baccalauréat" "Enseignement technique" "F4 — Génie civil"                  23
doc bac_t_g1 "Baccalauréat" "Enseignement technique" "G1 — Techniques administratives"   24
doc bac_t_g2 "Baccalauréat" "Enseignement technique" "G2 — Techniques de gestion"        25
doc bac_t_g3 "Baccalauréat" "Enseignement technique" "G3 — Techniques commerciales"      26

echo "── Seed Probatoire (général + technique) ──"
doc prob_g_a  "Probatoire" "Enseignement général"   "A — Lettres-Philosophie"          10
doc prob_g_c  "Probatoire" "Enseignement général"   "C — Maths & Sciences physiques"   11
doc prob_g_d  "Probatoire" "Enseignement général"   "D — Maths & Sciences de la vie"   12
doc prob_g_e  "Probatoire" "Enseignement général"   "E — Maths & Technique"            13
doc prob_t_f2 "Probatoire" "Enseignement technique" "F2 — Électronique"                21
doc prob_t_f3 "Probatoire" "Enseignement technique" "F3 — Électrotechnique"            22
doc prob_t_g2 "Probatoire" "Enseignement technique" "G2 — Techniques de gestion"       25
doc prob_t_g3 "Probatoire" "Enseignement technique" "G3 — Techniques commerciales"     26

echo "── Seed GCE A Level ──"
doc gce_sci  "GCE A Level" "" "Science"    10
doc gce_arts "GCE A Level" "" "Arts"       11
doc gce_com  "GCE A Level" "" "Commercial" 12

echo "── Seed BTS (filières) ──"
doc bts_cge  "BTS" "Filière" "Comptabilité & Gestion des entreprises" 10
doc bts_grh  "BTS" "Filière" "Gestion des ressources humaines"        11
doc bts_mcv  "BTS" "Filière" "Marketing-Commerce-Vente"               12
doc bts_bf   "BTS" "Filière" "Banque & Finance"                       13
doc bts_info "BTS" "Filière" "Informatique"                           14
doc bts_gl   "BTS" "Filière" "Génie logiciel"                         15
doc bts_rt   "BTS" "Filière" "Réseaux & Télécoms"                     16
doc bts_gc   "BTS" "Filière" "Génie civil"                            17
doc bts_msi  "BTS" "Filière" "Maintenance des systèmes industriels"   18
doc bts_elt  "BTS" "Filière" "Électrotechnique"                       19
doc bts_co   "BTS" "Filière" "Communication des organisations"        20
doc bts_sb   "BTS" "Filière" "Secrétariat bureautique"                21

echo
echo "Terminé. L'admin peut ajouter d'autres séries/filières depuis la console"
echo "Appwrite (collection '$COLLECTION') — l'app les chargera automatiquement."
