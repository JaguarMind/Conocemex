'use client';

import { useMemo, useCallback, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslation } from 'react-i18next';
import { useAuth } from '@/core/hooks/use-auth';
import { authService } from '@/core/services/auth.service';
import i18n from '@/core/i18n/config';
import type { UserProfile, ProfileMenuItem } from '../models/profile.types';

const LANGUAGES = [
  { code: 'es', label: 'Español', flag: '🇲🇽' },
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'pt', label: 'Português', flag: '🇧🇷' },
  { code: 'fr', label: 'Français', flag: '🇫🇷' },
];

export function useProfileViewModel() {
  const router = useRouter();
  const { t } = useTranslation();
  const { user, isLoading, signOut } = useAuth();
  const [showLanguageModal, setShowLanguageModal] = useState(false);
  const [currentLanguage, setCurrentLanguage] = useState(i18n.language?.substring(0, 2) ?? 'es');

  const profile: UserProfile | null = useMemo(() => {
    if (!user) return null;
    return {
      id: user.id,
      email: user.email ?? '',
      displayName: user.user_metadata?.full_name ?? user.user_metadata?.name ?? null,
      avatarUrl: user.user_metadata?.avatar_url ?? user.user_metadata?.picture ?? null,
      isAnonymous: user.is_anonymous ?? false,
    };
  }, [user]);

  const menuItems: ProfileMenuItem[] = useMemo(() => [
    { icon: 'language', label: t('profile.language'), action: 'language' },
    { icon: 'payments', label: t('profile.currencyConverter'), href: '/converter' },
    { icon: 'qr_code_2', label: t('profile.payViaQR'), href: '/pay' },
    { icon: 'tune', label: t('profile.travelPreferences'), href: '/onboarding' },
    { icon: 'help', label: t('profile.helpSupport') },
    { icon: 'logout', label: t('profile.signOut'), action: 'signout', destructive: true },
  ], [t]);

  const changeLanguage = useCallback(async (langCode: string) => {
    setCurrentLanguage(langCode);
    await i18n.changeLanguage(langCode);

    if (user?.id) {
      try {
        const supabase = authService.client;
        const { data: lang } = await supabase
          .from('languages')
          .select('id')
          .eq('code', langCode)
          .single();

        if (lang) {
          await supabase.from('profile_languages').delete().eq('profile_id', user.id);
          await supabase.from('profile_languages').insert({
            profile_id: user.id,
            language_id: lang.id,
            is_preferred: true,
            proficiency: 'fluent',
          });
        }
      } catch (err) {
        console.warn('[Profile] Failed to save language:', err);
      }
    }

    setShowLanguageModal(false);
  }, [user?.id]);

  const handleMenuAction = useCallback(async (item: ProfileMenuItem) => {
    if (item.action === 'signout') {
      await signOut();
      router.push('/');
    } else if (item.action === 'language') {
      setShowLanguageModal(true);
    } else if (item.href) {
      router.push(item.href);
    }
  }, [signOut, router]);

  return {
    profile,
    isLoading,
    menuItems,
    handleMenuAction,
    showLanguageModal,
    setShowLanguageModal,
    currentLanguage,
    changeLanguage,
    languages: LANGUAGES,
  };
}
