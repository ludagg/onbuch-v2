import { Client, Account, Databases, Teams, Functions, ID, Query } from 'appwrite';
import { APPWRITE_ENDPOINT, APPWRITE_PROJECT } from './config';

export const client = new Client()
  .setEndpoint(APPWRITE_ENDPOINT)
  .setProject(APPWRITE_PROJECT);

export const account = new Account(client);
export const databases = new Databases(client);
export const teams = new Teams(client);
export const functions = new Functions(client);

// Fonction « ops » côté serveur (gestion des comptes Auth — bloquer/supprimer).
export const ADMIN_FUNCTION_ID = 'review-nudge';

export { ID, Query };
