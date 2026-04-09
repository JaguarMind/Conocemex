'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { authService } from '@/core/services/auth.service';
import type { RegisterViewState } from '../models/auth.types';

const EMPTY_ERRORS: RegisterViewState['errors'] = { fullName: null, email: null, password: null, terms: null, general: null };

export function useRegisterViewModel() {
  const router = useRouter();

  const [state, setState] = useState<RegisterViewState>({
    fullName: '',
    email: '',
    password: '',
    acceptedTerms: false,
    isLoading: false,
    errors: { ...EMPTY_ERRORS },
  });

  const setFullName = useCallback((fullName: string) => {
    setState((prev) => ({ ...prev, fullName, errors: { ...prev.errors, fullName: null } }));
  }, []);

  const setEmail = useCallback((email: string) => {
    setState((prev) => ({ ...prev, email, errors: { ...prev.errors, email: null } }));
  }, []);

  const setPassword = useCallback((password: string) => {
    setState((prev) => ({ ...prev, password, errors: { ...prev.errors, password: null } }));
  }, []);

  const toggleTerms = useCallback(() => {
    setState((prev) => ({
      ...prev,
      acceptedTerms: !prev.acceptedTerms,
      errors: { ...prev.errors, terms: null },
    }));
  }, []);

  const validate = useCallback((): boolean => {
    const errors = { ...EMPTY_ERRORS };
    let valid = true;

    if (!state.fullName.trim()) {
      errors.fullName = 'El nombre es obligatorio';
      valid = false;
    } else if (state.fullName.trim().length < 2) {
      errors.fullName = 'El nombre debe tener al menos 2 caracteres';
      valid = false;
    }

    if (!state.email.trim()) {
      errors.email = 'El correo es obligatorio';
      valid = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(state.email)) {
      errors.email = 'Ingresa un correo válido';
      valid = false;
    }

    if (!state.password) {
      errors.password = 'La contraseña es obligatoria';
      valid = false;
    } else if (state.password.length < 6) {
      errors.password = 'Mínimo 6 caracteres';
      valid = false;
    }

    if (!state.acceptedTerms) {
      errors.terms = 'Debes aceptar los términos';
      valid = false;
    }

    setState((prev) => ({ ...prev, errors }));
    return valid;
  }, [state.fullName, state.email, state.password, state.acceptedTerms]);

  const register = useCallback(async () => {
    if (!validate()) return;

    setState((prev) => ({ ...prev, isLoading: true, errors: { ...EMPTY_ERRORS } }));

    try {
      const { data, error } = await authService.client.auth.signUp({
        email: state.email,
        password: state.password,
        options: {
          data: {
            full_name: state.fullName.trim(),
          },
        },
      });

      if (error) {
        let message = error.message;
        if (message.includes('already registered')) {
          message = 'Este correo ya está registrado';
        }
        setState((prev) => ({
          ...prev,
          isLoading: false,
          errors: { ...prev.errors, general: message },
        }));
        return;
      }

      // Update profile with full_name
      if (data.user) {
        await authService.client.from('profiles').update({
          full_name: state.fullName.trim(),
        }).eq('id', data.user.id);
      }

      router.push('/onboarding');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al registrar';
      setState((prev) => ({
        ...prev,
        isLoading: false,
        errors: { ...prev.errors, general: message },
      }));
    }
  }, [state.email, state.password, state.fullName, validate, router]);

  return {
    ...state,
    setFullName,
    setEmail,
    setPassword,
    toggleTerms,
    register,
  };
}
