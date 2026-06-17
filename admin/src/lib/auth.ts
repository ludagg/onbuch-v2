import { writable } from 'svelte/store';
import { account, teams } from './appwrite';
import { ADMIN_TEAM_ID } from './config';

export interface SessionState {
  loading: boolean;
  user: { $id: string; name: string; email: string } | null;
  isAdmin: boolean;
}

export const session = writable<SessionState>({ loading: true, user: null, isAdmin: false });

/** Vérifie la session courante et l'appartenance à l'équipe admin. */
export async function refreshSession(): Promise<void> {
  session.set({ loading: true, user: null, isAdmin: false });
  try {
    const user = await account.get();
    let isAdmin = false;
    try {
      const list = await teams.list();
      isAdmin = list.teams.some((t) => t.$id === ADMIN_TEAM_ID);
    } catch {
      isAdmin = false;
    }
    session.set({
      loading: false,
      user: { $id: user.$id, name: user.name, email: user.email },
      isAdmin
    });
  } catch {
    session.set({ loading: false, user: null, isAdmin: false });
  }
}

export async function login(email: string, password: string): Promise<void> {
  try {
    await account.deleteSession('current');
  } catch {
    /* pas de session active */
  }
  await account.createEmailPasswordSession(email.trim(), password);
  await refreshSession();
}

export async function logout(): Promise<void> {
  try {
    await account.deleteSession('current');
  } catch {
    /* ignore */
  }
  session.set({ loading: false, user: null, isAdmin: false });
}
