'use client';

import { createContext, useEffect, useState, type ReactNode } from 'react';
import { authService } from '@/core/services/auth.service';
import i18n from '@/core/i18n/config';
import type { User, Session } from '@supabase/supabase-js';

export interface AuthContextValue {
  user: User | null;
  session: Session | null;
  isLoading: boolean;
  signInWithEmail: (email: string, password: string) => Promise<{ error: string | null }>;
  signInWithGoogle: () => Promise<void>;
  signInAnonymously: () => Promise<void>;
  signOut: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

async function syncLanguageFromProfile(userId: string) {
  try {
    const supabase = authService.client;

    // Get the user's preferred language from profile_languages
    const { data } = await supabase
      .from('profile_languages')
      .select('language:languages(code)')
      .eq('profile_id', userId)
      .eq('is_preferred', true)
      .single();

    const langCode = (data?.language as unknown as { code: string } | null)?.code;
    if (langCode && langCode !== i18n.language) {
      await i18n.changeLanguage(langCode);
    }
  } catch {
    // No preferred language set, keep current
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    authService.getSession().then((s) => {
      setSession(s);
      setUser(s?.user ?? null);
      setIsLoading(false);

      // Sync language on initial load
      if (s?.user?.id) {
        syncLanguageFromProfile(s.user.id);
      }
    });

    const {
      data: { subscription },
    } = authService.client.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      setUser(newSession?.user ?? null);
      setIsLoading(false);

      // Sync language when auth state changes (login, etc.)
      if (newSession?.user?.id) {
        syncLanguageFromProfile(newSession.user.id);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const signInWithEmail = async (email: string, password: string) => {
    const { error } = await authService.signInWithEmail(email, password);
    if (error) {
      return { error: error.message };
    }
    return { error: null };
  };

  const signInWithGoogle = async () => {
    await authService.signInWithGoogle();
  };

  const signInAnonymously = async () => {
    await authService.signInAnonymously();
  };

  const signOut = async () => {
    await authService.signOut();
    setUser(null);
    setSession(null);
    // Reset to default language
    await i18n.changeLanguage('es');
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        isLoading,
        signInWithEmail,
        signInWithGoogle,
        signInAnonymously,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
