#!/usr/bin/env bash
# Ouvre les permissions nécessaires pour une administration complète :
#   • lessons / quizzes  : contenu pédagogique éditable par l'admin
#       → lecture publique + écriture team:admins (documentSecurity off).
#   • concours_applications / pack_purchases : données utilisateur privées que
#       l'admin doit pouvoir CONSULTER (vue suivi/audit)
#       → on AJOUTE read("team:admins") en gardant create("users") +
#         documentSecurity (chaque élève ne voit toujours que ses propres docs).
# Idempotent (l'update de collection écrase les permissions à la valeur cible).
# Usage : APPWRITE_API_KEY="standard_xxx" ./tools/setup_admin_complete_perms.sh
set -euo pipefail
EP="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJ="${APPWRITE_PROJECT:-6a30463b00001375e229}"
DB="${APPWRITE_DATABASE:-6a3047f8001d11d1b3c1}"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY}"
TEAM="${ADMIN_TEAM_ID:-admins}"
H=(-H "X-Appwrite-Project: $PROJ" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")

# update_collection <id> <name> <permissions-json> <documentSecurity:true|false>
update_collection() {
  curl -sS -X PUT "$EP/databases/$DB/collections/$1" "${H[@]}" \
    -d "{\"name\":\"$2\",\"permissions\":$3,\"documentSecurity\":$4}" \
    -o /dev/null -w "  • $1 [%{http_code}]\n" || true
}

echo "── Contenu pédagogique (lecture publique + écriture admin) ──"
CONTENT_PERMS="[\"read(\\\"any\\\")\",\"create(\\\"team:$TEAM\\\")\",\"update(\\\"team:$TEAM\\\")\",\"delete(\\\"team:$TEAM\\\")\"]"
update_collection lessons "Lessons" "$CONTENT_PERMS" false
update_collection quizzes "Quizzes" "$CONTENT_PERMS" false

echo "── Données utilisateur : lecture admin ajoutée (suivi/audit) ──"
# create("users") conservé pour que l'app crée les docs ; read("team:admins")
# ajouté pour la vue back-office ; documentSecurity gardé pour l'isolation élève.
APPS_PERMS="[\"create(\\\"users\\\")\",\"read(\\\"team:$TEAM\\\")\"]"
update_collection concours_applications "Concours applications" "$APPS_PERMS" true
update_collection pack_purchases "Achats de packs" "$APPS_PERMS" true

echo "── tutor_quota : lecture admin (voir le solde de crédits des élèves) ──"
# Pas de create/update : seuls les serveurs (clé API) écrivent le quota.
# documentSecurity gardé → chaque élève lit toujours son propre solde (perm/doc).
update_collection tutor_quota "Tutor quota" "[\"read(\\\"team:$TEAM\\\")\"]" true

echo "── Terminé. (Redéploie ensuite le back-office admin.) ──"
