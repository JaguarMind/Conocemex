'use client';

import { useTranslation } from 'react-i18next';
import { cn } from '@/core/utils/cn';
import { useProfileViewModel } from '../viewmodels/use-profile-viewmodel';

export function ProfileView() {
  const {
    profile,
    isLoading,
    menuItems,
    handleMenuAction,
    showLanguageModal,
    setShowLanguageModal,
    currentLanguage,
    changeLanguage,
    languages,
  } = useProfileViewModel();
  const { t } = useTranslation();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-10 h-10 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="pt-20 pb-28 px-6 max-w-lg mx-auto">
      {/* Profile Header */}
      <section className="flex flex-col items-center mb-10">
        {/* Avatar */}
        <div className="w-24 h-24 rounded-full bg-primary-container/20 flex items-center justify-center mb-5 overflow-hidden">
          {profile?.avatarUrl ? (
            <img
              src={profile.avatarUrl}
              alt={profile.displayName ?? 'Profile'}
              className="w-full h-full object-cover"
            />
          ) : (
            <span
              className="material-symbols-outlined text-primary text-5xl"
              style={{ fontVariationSettings: '"FILL" 1' }}
            >
              person
            </span>
          )}
        </div>

        {/* Name & Email */}
        <h1 className="font-display font-extrabold text-2xl text-on-surface tracking-tight">
          {profile?.displayName ?? (profile?.isAnonymous ? t('profile.guestExplorer') : t('profile.traveler'))}
        </h1>
        {profile?.email && !profile.isAnonymous && (
          <p className="text-on-surface-variant text-sm mt-1">{profile.email}</p>
        )}
        {profile?.isAnonymous && (
          <p className="text-on-surface-variant text-sm mt-1">{t('profile.browsingAsGuest')}</p>
        )}

        {/* Quick Stats */}
        <div className="flex gap-6 mt-6">
          <div className="flex flex-col items-center">
            <span className="font-display font-extrabold text-xl text-on-surface">0</span>
            <span className="text-xs text-on-surface-variant font-medium mt-0.5">{t('profile.routes')}</span>
          </div>
          <div className="w-px h-10 bg-surface-container-high" />
          <div className="flex flex-col items-center">
            <span className="font-display font-extrabold text-xl text-on-surface">0</span>
            <span className="text-xs text-on-surface-variant font-medium mt-0.5">{t('profile.visits')}</span>
          </div>
          <div className="w-px h-10 bg-surface-container-high" />
          <div className="flex flex-col items-center">
            <span className="font-display font-extrabold text-xl text-on-surface">0</span>
            <span className="text-xs text-on-surface-variant font-medium mt-0.5">{t('profile.reviews')}</span>
          </div>
        </div>
      </section>

      {/* Menu Items */}
      <section className="bg-surface-container-lowest rounded-2xl shadow-sm overflow-hidden">
        {menuItems.map((item, index) => (
          <button
            key={item.label}
            onClick={() => handleMenuAction(item)}
            className={cn(
              'w-full flex items-center gap-4 px-6 py-4 transition-all active:scale-[0.98] active:bg-surface-container-low text-left',
              index < menuItems.length - 1 && 'border-b border-surface-container-low',
              item.destructive ? 'text-tertiary' : 'text-on-surface',
            )}
          >
            <span
              className={cn(
                'material-symbols-outlined text-xl',
                item.destructive ? 'text-tertiary' : 'text-on-surface-variant',
              )}
            >
              {item.icon}
            </span>
            <span className="font-semibold text-sm flex-1">{item.label}</span>
            {!item.destructive && (
              <span className="material-symbols-outlined text-on-surface-variant/40 text-lg">
                chevron_right
              </span>
            )}
          </button>
        ))}
      </section>

      {/* Sign In Prompt for Guests */}
      {profile?.isAnonymous && (
        <section className="mt-8 bg-primary/5 rounded-2xl p-6 text-center">
          <span
            className="material-symbols-outlined text-primary text-3xl mb-3"
            style={{ fontVariationSettings: '"FILL" 1' }}
          >
            lock_open
          </span>
          <h3 className="font-display font-bold text-on-surface mb-1">
            {t('profile.signInPrompt')}
          </h3>
          <p className="text-on-surface-variant text-sm mb-4">
            {t('profile.signInDesc')}
          </p>
          <a
            href="/"
            className="inline-flex items-center justify-center px-8 py-3 bg-primary-container text-on-primary-container font-bold rounded-full text-sm hover:brightness-105 active:scale-95 transition-all"
          >
            {t('profile.signIn')}
          </a>
        </section>
      )}

      {/* App Version */}
      <p className="text-center text-on-surface-variant/40 text-xs mt-10 font-medium">
        CONOCEMEX v1.0 — Hackathon Talent Land 2026
      </p>

      {/* Language Modal */}
      {showLanguageModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
          <div className="fixed inset-0 bg-on-secondary-fixed/40 backdrop-blur-sm" onClick={() => setShowLanguageModal(false)} />
          <div className="relative z-10 w-full max-w-sm rounded-t-2xl sm:rounded-2xl bg-surface-container-lowest p-6 shadow-(--shadow-elevated) mx-0 sm:mx-4">
            <h2 className="text-xl font-display font-bold text-on-surface mb-1">
              {t('profile.chooseLanguage')}
            </h2>
            <p className="text-sm text-on-surface-variant mb-5">
              {t('profile.languageDesc')}
            </p>
            <div className="space-y-2">
              {languages.map((lang) => (
                <button
                  key={lang.code}
                  onClick={() => changeLanguage(lang.code)}
                  className={cn(
                    'w-full flex items-center gap-4 px-5 py-4 rounded-xl transition-all active:scale-[0.98]',
                    currentLanguage === lang.code
                      ? 'bg-primary text-white shadow-lg'
                      : 'bg-surface-container-low text-on-surface hover:bg-surface-container',
                  )}
                >
                  <span className="text-2xl">{lang.flag}</span>
                  <span className="font-bold text-base">{lang.label}</span>
                  {currentLanguage === lang.code && (
                    <span className="material-symbols-outlined ml-auto text-lg" style={{ fontVariationSettings: '"FILL" 1' }}>
                      check_circle
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
