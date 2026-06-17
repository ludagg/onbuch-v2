import { Client, Account, Databases, Teams, ID, Query } from 'appwrite';
import { APPWRITE_ENDPOINT, APPWRITE_PROJECT } from './config';

export const client = new Client()
  .setEndpoint(APPWRITE_ENDPOINT)
  .setProject(APPWRITE_PROJECT);

export const account = new Account(client);
export const databases = new Databases(client);
export const teams = new Teams(client);

export { ID, Query };
