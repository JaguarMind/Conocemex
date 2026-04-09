'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { storageService } from '@/core/services/storage.service';

const ONBOARDING_COMPLETE_KEY = 'conocemex_onboarding_complete';

/**
 * Redirects to /onboarding if the user hasn't completed preferences yet.
 * Call this in pages that require onboarding (e.g., /map).
 */
export function useOnboardingGuard() {
  const router = useRouter();

  useEffect(() => {
    const done = storageService.get<boolean>(ONBOARDING_COMPLETE_KEY);
    if (!done) {
      router.replace('/onboarding');
    }
  }, [router]);
}
