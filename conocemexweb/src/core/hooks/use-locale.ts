'use client';

import { useTranslation } from 'react-i18next';
import type { Locale } from '@/core/types/common.types';

export function useLocale() {
  const { i18n } = useTranslation();

  const currentLocale = (i18n.language?.startsWith('en') ? 'en' : 'es') as Locale;

  const changeLocale = (locale: Locale) => {
    i18n.changeLanguage(locale);
  };

  const toggleLocale = () => {
    changeLocale(currentLocale === 'es' ? 'en' : 'es');
  };

  return { currentLocale, changeLocale, toggleLocale };
}
