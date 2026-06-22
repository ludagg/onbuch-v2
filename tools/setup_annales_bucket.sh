#!/usr/bin/env bash
# Crée le bucket Storage `annales_files` : les fichiers (PDF/vidéo) des épreuves
# téléversés depuis le back-office (collection `annales`, champ `fileUrl`).
# Lecture publique (l'app affiche/télécharge), écriture réservée aux admins.
# Idempotent (409 = déjà existant, ignoré).
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" ./tools/setup_annales_bucket.sh
#
# Clé API **serveur** avec scope `buckets.write` (ou `files.write`).

set -euo pipefail

ENDPOINT="${APPWRITE_ENDPOINT:-https://nyc.cloud.appwrite.io/v1}"
PROJECT="${APPWRITE_PROJECT:-6a30463b00001375e229}"
BUCKET="annales_files"
KEY="${APPWRITE_API_KEY:?Définis APPWRITE_API_KEY (clé serveur avec scope buckets.write)}"

H=(-H "X-Appwrite-Project: $PROJECT" -H "X-Appwrite-Key: $KEY" -H "Content-Type: application/json")
api() { curl -sS -X "$1" "$ENDPOINT$2" "${H[@]}" ${3:+-d "$3"} -w $'\n[HTTP %{http_code}]\n'; }

echo "── Bucket '$BUCKET' ──"
# maximumFileSize en octets (~30 Mo). Extensions limitées aux PDF/images/vidéos.
api POST "/storage/buckets" \
  "{\"bucketId\":\"$BUCKET\",\"name\":\"Annales (fichiers)\",\"permissions\":[\"read(\\\"any\\\")\",\"create(\\\"team:admins\\\")\",\"update(\\\"team:admins\\\")\",\"delete(\\\"team:admins\\\")\"],\"fileSecurity\":false,\"enabled\":true,\"maximumFileSize\":31457280,\"allowedFileExtensions\":[\"pdf\",\"jpg\",\"jpeg\",\"png\",\"mp4\"],\"compression\":\"none\",\"encryption\":true,\"antivirus\":true}"

echo
echo "Terminé. L'admin peut téléverser des PDF dans le champ « Document » des"
echo "épreuves (back-office → Annales), ou coller un lien externe."
