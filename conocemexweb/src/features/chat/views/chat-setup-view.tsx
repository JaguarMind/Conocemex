'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useChatSetupViewModel } from '../viewmodels/use-chat-setup-viewmodel';
import { CHAT_LANGUAGES } from '../models/chat.types';
import { cn } from '@/core/utils/cn';

export function ChatSetupView() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const businessId = searchParams.get('businessId') ?? '';
  const businessName = searchParams.get('businessName') ?? 'Business';

  const vm = useChatSetupViewModel(businessId, businessName);
  const selectedLang = CHAT_LANGUAGES.find((l) => l.code === vm.selectedLanguage);

  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center p-4">
      {/* Overlay */}
      <div className="absolute inset-0 bg-on-secondary-fixed/40 backdrop-blur-sm" onClick={() => router.back()} />

      {/* Modal */}
      <div className="relative w-full max-w-md bg-surface-container-lowest rounded-xl shadow-[0_32px_64px_-15px_rgba(0,31,58,0.2)] overflow-hidden flex flex-col z-10">
        {/* Header */}
        <header className="flex items-center justify-between px-6 py-4 bg-white/80 backdrop-blur-xl sticky top-0">
          <button onClick={() => router.back()} className="hover:bg-surface-container-low transition-colors p-2 rounded-full active:scale-90 duration-200">
            <span className="material-symbols-outlined text-on-secondary-fixed">arrow_back</span>
          </button>
          <h1 className="font-display font-bold tracking-tight text-xl text-on-secondary-fixed">Chat Setup</h1>
          <div className="w-10" />
        </header>

        {/* Content */}
        <div className="p-8 pt-4">
          {/* Hero */}
          <div className="flex flex-col items-center text-center mb-8">
            <div className="w-20 h-20 bg-secondary-container/30 rounded-full flex items-center justify-center mb-4">
              <span className="material-symbols-outlined text-on-secondary-fixed text-5xl" style={{ fontVariationSettings: '"FILL" 1' }}>
                chat_bubble
              </span>
            </div>
            <h2 className="font-display font-extrabold text-2xl text-on-secondary-fixed tracking-tight">
              Chat with {businessName}
            </h2>
            <p className="text-secondary mt-2 font-medium">
              Ready to translate your request instantly
            </p>
          </div>

          {/* Language Selection */}
          <div className="space-y-6">
            <div className="space-y-3">
              <label className="text-on-secondary-fixed font-semibold text-sm tracking-wide">
                We translate in real-time. Choose your language:
              </label>
              <div className="relative">
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-on-secondary-fixed pointer-events-none">
                  <span className="material-symbols-outlined">public</span>
                </div>
                <select
                  value={vm.selectedLanguage}
                  onChange={(e) => vm.setLanguage(e.target.value)}
                  className="w-full bg-surface-container-low border border-outline-variant/30 rounded-xl py-4 pl-12 pr-10 font-semibold text-on-secondary-fixed appearance-none focus:ring-2 focus:ring-primary-container focus:border-transparent outline-none cursor-pointer"
                >
                  {CHAT_LANGUAGES.map((lang) => (
                    <option key={lang.code} value={lang.code}>
                      {lang.flag} {lang.label}
                    </option>
                  ))}
                </select>
                <div className="absolute right-4 top-1/2 -translate-y-1/2 text-secondary pointer-events-none">
                  <span className="material-symbols-outlined">expand_more</span>
                </div>
              </div>
            </div>

            {/* First Message */}
            <div className="space-y-3">
              <label className="text-on-secondary-fixed font-semibold text-sm tracking-wide">
                First Message
              </label>
              <textarea
                value={vm.firstMessage}
                onChange={(e) => vm.setFirstMessage(e.target.value)}
                className="w-full bg-surface-container-low border-none rounded-xl p-4 text-on-secondary-fixed focus:ring-2 focus:ring-primary-container placeholder:text-secondary/50 resize-none outline-none"
                placeholder="Type your message here..."
                rows={4}
              />
            </div>
          </div>

          {/* Error */}
          {vm.error && (
            <p className="text-tertiary text-sm font-semibold mt-3 text-center">{vm.error}</p>
          )}

          {/* CTA */}
          <div className="mt-10">
            <button
              onClick={vm.startChat}
              disabled={vm.isSubmitting}
              className="w-full bg-primary-container text-on-primary-container py-5 rounded-xl font-display font-bold text-lg shadow-lg shadow-primary-container/20 hover:scale-[1.02] active:scale-95 transition-all duration-200 disabled:opacity-50"
            >
              {vm.isSubmitting ? 'Starting...' : 'Send Request & Start Chat'}
            </button>
            <p className="text-center text-xs text-secondary mt-4 px-4 leading-relaxed">
              By starting this chat, our AI will translate between {selectedLang?.label ?? 'your language'} and Spanish in real-time.
            </p>
          </div>
        </div>

        {/* Bottom gradient line */}
        <div className="h-1.5 w-full bg-gradient-to-r from-primary via-primary-container to-secondary-container" />
      </div>
    </div>
  );
}
