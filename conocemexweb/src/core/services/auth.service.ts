import { createBrowserClient } from '@supabase/ssr';
import { env } from '@/core/config/env';
import type { SupabaseClient, Session, User } from '@supabase/supabase-js';

let _client: SupabaseClient | null = null;

function getClient(): SupabaseClient {
  if (!_client) {
    _client = createBrowserClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);
  }
  return _client;
}

export const authService = {
  get client() {
    return getClient();
  },

  async getSession(): Promise<Session | null> {
    const { data } = await this.client.auth.getSession();
    return data.session;
  },

  async getUser(): Promise<User | null> {
    const { data } = await this.client.auth.getUser();
    return data.user;
  },

  async signInWithEmail(email: string, password: string) {
    return this.client.auth.signInWithPassword({ email, password });
  },

  async signUpWithEmail(email: string, password: string) {
    return this.client.auth.signUp({ email, password });
  },

  async signInWithGoogle() {
    return this.client.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/map`,
        queryParams: {
          access_type: 'offline',
          prompt: 'consent',
        },
      },
    });
  },

  async signInAnonymously() {
    return this.client.auth.signInAnonymously();
  },

  async signOut() {
    return this.client.auth.signOut();
  },
};
