// Configuration Appwrite (identique à l'app mobile OnBuch).
export const APPWRITE_ENDPOINT = 'https://nyc.cloud.appwrite.io/v1';
export const APPWRITE_PROJECT = '6a30463b00001375e229';
export const APPWRITE_DATABASE = '6a3047f8001d11d1b3c1';

// Équipe Appwrite dont les membres ont accès à l'admin (et le droit d'écrire).
export const ADMIN_TEAM_ID = 'admins';

// 2ᵉ couche : code secret demandé APRÈS la connexion Appwrite (en plus du
// mot de passe + appartenance à l'équipe admins). On ne stocke que l'empreinte
// SHA-256 du code (jamais le code en clair). Pour changer le code : remplacer
// ce hash par `printf '%s' "NOUVEAU_CODE" | sha256sum`. NB : c'est une couche
// de dissuasion côté client ; la vraie barrière reste la session Appwrite +
// l'équipe `admins` (vérifiées côté serveur à chaque requête).
export const ADMIN_GATE_SHA256 = '7a653483564ca93ac6b64431aef2f03d1583be5dc7747615e05c3d4f818072d6';
