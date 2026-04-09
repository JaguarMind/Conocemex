'use client';

import { useLocale } from '@/core/hooks/use-locale';

export function LanguageToggle() {
  const { currentLocale, toggleLocale } = useLocale();

  return (
    <button
      onClick={toggleLocale}
      className="rounded-full bg-surface-container-low px-4 py-1.5 text-sm font-semibold text-on-surface-variant transition-all duration-200 hover:bg-surface-container active:scale-95"
    >
      {currentLocale === 'es' ? 'EN' : 'ES'}
    </button>
  );
}
