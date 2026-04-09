'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/core/hooks/use-auth';
import { storageService } from '@/core/services/storage.service';
import { surveyService } from '../services/survey.service';
import i18n from '@/core/i18n/config';
import type {
  OnboardingViewState,
  TravelCompanion,
  DietaryRestriction,
  BudgetRange,
} from '../models/survey.types';

const ONBOARDING_COMPLETE_KEY = 'conocemex_onboarding_complete';
const TOTAL_STEPS = 4; // 0: companion+interests, 1: nationality+language, 2: dietary, 3: budget

export function useOnboardingViewModel() {
  const router = useRouter();
  const { user } = useAuth();

  const [state, setState] = useState<OnboardingViewState>({
    step: 0,
    data: {
      companion: null,
      nationality: '',
      language: 'en',
      dietaryRestriction: 'none',
      budgetRange: 'medium',
      interests: [],
    },
    isSubmitting: false,
    error: null,
  });

  const setCompanion = useCallback((companion: TravelCompanion) => {
    setState((prev) => ({ ...prev, data: { ...prev.data, companion } }));
  }, []);

  const toggleInterest = useCallback((interestId: string) => {
    setState((prev) => {
      const interests = prev.data.interests.includes(interestId)
        ? prev.data.interests.filter((i) => i !== interestId)
        : [...prev.data.interests, interestId];
      return { ...prev, data: { ...prev.data, interests } };
    });
  }, []);

  const setNationality = useCallback((nationality: string) => {
    setState((prev) => ({ ...prev, data: { ...prev.data, nationality } }));
  }, []);

  const setLanguage = useCallback((language: string) => {
    setState((prev) => ({ ...prev, data: { ...prev.data, language } }));
    // Change app language immediately so user sees the effect
    i18n.changeLanguage(language);
  }, []);

  const setDietary = useCallback((dietaryRestriction: DietaryRestriction) => {
    setState((prev) => ({ ...prev, data: { ...prev.data, dietaryRestriction } }));
  }, []);

  const setBudget = useCallback((budgetRange: BudgetRange) => {
    setState((prev) => ({ ...prev, data: { ...prev.data, budgetRange } }));
  }, []);

  const nextStep = useCallback(() => {
    setState((prev) => ({ ...prev, step: Math.min(prev.step + 1, TOTAL_STEPS - 1) }));
  }, []);

  const prevStep = useCallback(() => {
    setState((prev) => ({ ...prev, step: Math.max(prev.step - 1, 0) }));
  }, []);

  const submit = useCallback(async () => {
    setState((prev) => ({ ...prev, isSubmitting: true, error: null }));
    try {
      if (user?.id) {
        await surveyService.submitOnboarding({
          userId: user.id,
          nationality: state.data.nationality,
          language: state.data.language,
          dietaryRestriction: state.data.dietaryRestriction,
          budgetRange: state.data.budgetRange,
          interests: state.data.interests,
        });
      }
      storageService.set(ONBOARDING_COMPLETE_KEY, true);
      router.push('/map');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error saving preferences';
      console.error('[Onboarding] Submit error:', err);
      setState((prev) => ({ ...prev, error: message, isSubmitting: false }));
    }
  }, [user?.id, state.data, router]);

  const skip = useCallback(() => {
    storageService.set(ONBOARDING_COMPLETE_KEY, true);
    router.push('/map');
  }, [router]);

  return {
    ...state,
    totalSteps: TOTAL_STEPS,
    setCompanion,
    toggleInterest,
    setNationality,
    setLanguage,
    setDietary,
    setBudget,
    nextStep,
    prevStep,
    submit,
    skip,
  };
}
