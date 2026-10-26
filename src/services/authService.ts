import { supabase, isSupabaseConfigured } from './learningRepository';

export interface AuthUser {
  id: string;
  email: string;
}

const LOCAL_AUTH_USER_KEY = 'vedomax_current_user';
const LOCAL_ACCOUNTS_KEY = 'vedomax_accounts';

export const authService = {
  getCurrentUser(): AuthUser | null {
    if (isSupabaseConfigured && supabase) {
      // Supabase handled in listener
    }
    const raw = localStorage.getItem(LOCAL_AUTH_USER_KEY);
    return raw ? JSON.parse(raw) : null;
  },

  async signIn(email: string, pass: string): Promise<AuthUser> {
    const cleanEmail = email.trim().toLowerCase();
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: cleanEmail,
        password: pass,
      });
      if (error) {
        throw new Error(error.message);
      }
      return { id: data.user.id, email: data.user.email || cleanEmail };
    }

    // Local authentication fallback
    const accounts = JSON.parse(localStorage.getItem(LOCAL_ACCOUNTS_KEY) || '{}');
    if (!accounts[cleanEmail] || accounts[cleanEmail] !== pass) {
      throw new Error('Nesprávny e-mail alebo heslo. Skontroluj údaje.');
    }
    const user: AuthUser = {
      id: 'usr_' + btoa(cleanEmail).replace(/[^a-zA-Z0-9]/g, '').slice(0, 16),
      email: cleanEmail,
    };
    localStorage.setItem(LOCAL_AUTH_USER_KEY, JSON.stringify(user));
    return user;
  },

  async signUp(email: string, pass: string): Promise<{ user?: AuthUser; requiresEmailConfirm: boolean }> {
    const cleanEmail = email.trim().toLowerCase();
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase.auth.signUp({
        email: cleanEmail,
        password: pass,
      });
      if (error) {
        throw new Error(error.message);
      }
      return {
        user: data.user ? { id: data.user.id, email: data.user.email || cleanEmail } : undefined,
        requiresEmailConfirm: !data.session,
      };
    }

    // Local authentication fallback
    const accounts = JSON.parse(localStorage.getItem(LOCAL_ACCOUNTS_KEY) || '{}');
    accounts[cleanEmail] = pass;
    localStorage.setItem(LOCAL_ACCOUNTS_KEY, JSON.stringify(accounts));
    const user: AuthUser = {
      id: 'usr_' + btoa(cleanEmail).replace(/[^a-zA-Z0-9]/g, '').slice(0, 16),
      email: cleanEmail,
    };
    localStorage.setItem(LOCAL_AUTH_USER_KEY, JSON.stringify(user));
    return { user, requiresEmailConfirm: false };
  },

  async resendConfirmation(email: string): Promise<void> {
    const cleanEmail = email.trim().toLowerCase();
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email: cleanEmail,
      });
      if (error) {
        throw new Error(error.message);
      }
    }
    // Success / simulation
  },

  async signOut(): Promise<void> {
    if (isSupabaseConfigured && supabase) {
      await supabase.auth.signOut();
    }
    localStorage.removeItem(LOCAL_AUTH_USER_KEY);
  },
};
