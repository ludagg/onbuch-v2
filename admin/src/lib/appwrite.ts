import { Client, Account, Databases, Teams, Functions, Storage, ID, Query } from 'appwrite';
import { APPWRITE_ENDPOINT, APPWRITE_PROJECT } from './config';

export const client = new Client()
  .setEndpoint(APPWRITE_ENDPOINT)
  .setProject(APPWRITE_PROJECT);

export const account = new Account(client);
export const databases = new Databases(client);
export const teams = new Teams(client);
export const functions = new Functions(client);
export const storage = new Storage(client);

// Bucket Storage des PDF de résultats chargés par l'admin. On réutilise le
// bucket `annales_files` (le plan Appwrite limite le nombre de buckets).
export const RESULT_PDFS_BUCKET = 'annales_files';

// Fonction « ops » côté serveur (gestion des comptes Auth — bloquer/supprimer).
export const ADMIN_FUNCTION_ID = 'review-nudge';

export { ID, Query };
