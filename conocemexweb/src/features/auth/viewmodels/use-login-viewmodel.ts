'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/core/hooks/use-auth';
import { storageService } from '@/core/services/storage.service';
import type { AuthViewState } from '../models/auth.types';

const ONBOARDING_COMPLETE_KEY = 'conocemex_onboarding_complete';

function getPostLoginRoute(): string {
  const done = storageService.get<boolean>(ONBOARDING_COMPLETE_KEY);
  return done ? '/map' : '/onboarding';
}

export function useLoginViewModel() {
  const router = useRouter();
  const { signInWithEmail, signInWithGoogle, signInAnonymously } = useAuth();

  const [state, setState] = useState<AuthViewState>({
    email: '',
    password: '',
    isLoading: false,
    error: null,
  });

  const setEmail = useCallback((email: string) => {
    setState((prev) => ({ ...prev, email, error: null }));
  }, []);

  const setPassword = useCallback((password: string) => {
    setState((prev) => ({ ...prev, password, error: null }));
  }, []);

  const loginWithEmail = useCallback(async () => {
    if (!state.email || !state.password) {
      setState((prev) => ({ ...prev, error: 'Please fill in all fields' }));
      return;
    }
    setState((prev) => ({ ...prev, isLoading: true, error: null }));
    try {
      const { error } = await signInWithEmail(state.email, state.password);
      if (error) {
        setState((prev) => ({ ...prev, error, isLoading: false }));
      } else {
        router.push(getPostLoginRoute());
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Login failed';
      setState((prev) => ({ ...prev, error: message, isLoading: false }));
    }
  }, [state.email, state.password, signInWithEmail, router]);

  const loginWithGoogle = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }));
    try {
      await signInWithGoogle();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Google login failed';
      setState((prev) => ({ ...prev, error: message, isLoading: false }));
    }
  }, [signInWithGoogle]);

  const continueAsGuest = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true }));
    try {
      await signInAnonymously();
      router.push(getPostLoginRoute());
    } catch {
      router.push(getPostLoginRoute());
    }
  }, [signInAnonymously, router]);

  const skip = useCallback(() => {
    router.push('/map');
  }, [router]);

  return {
    ...state,
    setEmail,
    setPassword,
    loginWithEmail,
    loginWithGoogle,
    continueAsGuest,
    skip,
  };
}
