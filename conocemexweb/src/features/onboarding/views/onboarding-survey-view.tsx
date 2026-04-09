'use client';

import { cn } from '@/core/utils/cn';
import { useOnboardingViewModel } from '../viewmodels/use-onboarding-viewmodel';
import {
  COMPANION_OPTIONS,
  INTEREST_OPTIONS,
  NATIONALITY_OPTIONS,
  LANGUAGE_OPTIONS,
  DIETARY_OPTIONS,
  BUDGET_OPTIONS,
  type TravelCompanion,
  type DietaryRestriction,
  type BudgetRange,
} from '../models/survey.types';

export function OnboardingSurveyView() {
  const vm = useOnboardingViewModel();

  return (
    <div className="bg-surface text-on-surface min-h-screen">
      {/* Header */}
      <header className="fixed top-0 w-full bg-white/95 backdrop-blur-xl z-50 flex items-center justify-between px-6 py-5 border-b border-surface-container-low">
        <button
          onClick={vm.step > 0 ? vm.prevStep : vm.skip}
          className="flex items-center justify-center p-2 rounded-full hover:bg-surface-container-low"
        >
          <span className="material-symbols-outlined text-on-surface">
            {vm.step > 0 ? 'arrow_back' : 'close'}
          </span>
        </button>
        <div className="font-display font-extrabold tracking-tight text-lg">
          Travel Preferences
        </div>
        <button onClick={vm.skip} className="text-on-surface font-bold text-sm hover:text-primary transition-colors">
          Skip
        </button>
      </header>

      {/* Progress bar */}
      <div className="fixed top-17 left-0 w-full h-1 bg-surface-container-low z-50">
        <div
          className="h-full bg-primary-container transition-all duration-300"
          style={{ width: `${((vm.step + 1) / vm.totalSteps) * 100}%` }}
        />
      </div>

      <main className="pt-24 pb-44 px-6 max-w-lg mx-auto">
        {/* ── Step 0: Companion + Interests ── */}
        {vm.step === 0 && (
          <>
            <section className="mb-12">
              <h1 className="text-4xl font-extrabold tracking-tighter text-on-surface mb-4 font-display">
                Personalize your experience
              </h1>
              <p className="text-lg text-on-surface-variant font-medium leading-relaxed">
                Tell us about your trip for custom recommendations.
              </p>
            </section>

            <section className="mb-14">
              <h2 className="text-2xl font-extrabold text-on-surface mb-6 flex items-center gap-3 font-display">
                <span className="w-2.5 h-8 bg-primary rounded-full" />
                Who are you traveling with?
              </h2>
              <div className="flex flex-wrap gap-4">
                {COMPANION_OPTIONS.map((opt) => {
                  const sel = vm.data.companion === opt.id;
                  return (
                    <button key={opt.id} onClick={() => vm.setCompanion(opt.id as TravelCompanion)}
                      className={cn('px-8 py-4 rounded-xl font-bold transition-all active:scale-95',
                        sel ? 'bg-primary text-white font-extrabold shadow-xl shadow-primary/30 scale-105 border-2 border-primary flex items-center gap-2'
                          : 'border-2 border-surface-container-high bg-white text-on-surface shadow-sm')}>
                      {opt.label}
                      {sel && <span className="material-symbols-outlined text-sm" style={{ fontVariationSettings: '"FILL" 1' }}>check_circle</span>}
                    </button>
                  );
                })}
              </div>
            </section>

            <section className="mb-14">
              <h2 className="text-2xl font-extrabold text-on-surface mb-6 flex items-center gap-3 font-display">
                <span className="w-2.5 h-8 bg-primary rounded-full" />
                What are you looking for?
              </h2>
              <div className="grid grid-cols-2 gap-4">
                {INTEREST_OPTIONS.map((opt, i) => {
                  const sel = vm.data.interests.includes(opt.id);
                  const isLast = i === INTEREST_OPTIONS.length - 1 && INTEREST_OPTIONS.length % 2 !== 0;
                  return (
                    <button key={opt.id} onClick={() => vm.toggleInterest(opt.id)}
                      className={cn('p-6 rounded-2xl flex transition-all',
                        isLast ? 'col-span-2 items-center justify-between' : 'col-span-1 flex-col items-start gap-4',
                        sel ? 'bg-primary shadow-2xl shadow-primary/30 scale-[1.02] border-2 border-primary relative' : 'bg-white border-2 border-surface-container-low shadow-sm')}>
                      {isLast ? (
                        <>
                          <div className="flex items-center gap-5">
                            <span className="text-4xl">{opt.emoji}</span>
                            <span className={cn('font-extrabold', sel ? 'text-white' : 'text-on-surface')}>{opt.label}</span>
                          </div>
                          <span className={cn('material-symbols-outlined', sel ? 'text-white' : 'text-outline')}
                            style={sel ? { fontVariationSettings: '"FILL" 1' } : undefined}>
                            {sel ? 'check_circle' : 'add'}
                          </span>
                        </>
                      ) : (
                        <>
                          <span className="text-4xl">{opt.emoji}</span>
                          <span className={cn('font-extrabold', sel ? 'text-white' : 'text-on-surface')}>{opt.label}</span>
                          {sel && <span className="material-symbols-outlined absolute top-4 right-4 text-white" style={{ fontVariationSettings: '"FILL" 1' }}>check_circle</span>}
                        </>
                      )}
                    </button>
                  );
                })}
              </div>
            </section>
          </>
        )}

        {/* ── Step 1: Nationality + Language ── */}
        {vm.step === 1 && (
          <>
            <section className="mb-12">
              <h1 className="text-3xl font-extrabold tracking-tighter text-on-surface mb-4 font-display">
                Where are you from?
              </h1>
              <p className="text-base text-on-surface-variant font-medium">This helps us show content in your language.</p>
            </section>

            <section className="mb-10">
              <h2 className="text-lg font-extrabold text-on-surface mb-4 flex items-center gap-3 font-display">
                <span className="w-2.5 h-6 bg-primary rounded-full" />
                Nationality
              </h2>
              <div className="flex flex-wrap gap-3">
                {NATIONALITY_OPTIONS.map((nat) => (
                  <button key={nat} onClick={() => vm.setNationality(nat)}
                    className={cn('px-5 py-3 rounded-xl font-semibold text-sm transition-all active:scale-95',
                      vm.data.nationality === nat ? 'bg-primary text-white shadow-lg' : 'bg-white border border-surface-container-high text-on-surface shadow-sm')}>
                    {nat}
                  </button>
                ))}
              </div>
            </section>

            <section className="mb-10">
              <h2 className="text-lg font-extrabold text-on-surface mb-4 flex items-center gap-3 font-display">
                <span className="w-2.5 h-6 bg-primary rounded-full" />
                Preferred Language
              </h2>
              <div className="grid grid-cols-2 gap-3">
                {LANGUAGE_OPTIONS.map((lang) => (
                  <button key={lang.code} onClick={() => vm.setLanguage(lang.code)}
                    className={cn('p-5 rounded-2xl font-bold text-base flex items-center gap-3 transition-all active:scale-95',
                      vm.data.language === lang.code ? 'bg-primary text-white shadow-lg' : 'bg-white border border-surface-container-high text-on-surface shadow-sm')}>
                    <span className="text-2xl">{lang.flag}</span>
                    {lang.label}
                  </button>
                ))}
              </div>
            </section>
          </>
        )}

        {/* ── Step 2: Dietary ── */}
        {vm.step === 2 && (
          <>
            <section className="mb-12">
              <h1 className="text-3xl font-extrabold tracking-tighter text-on-surface mb-4 font-display">
                Any dietary preferences?
              </h1>
              <p className="text-base text-on-surface-variant font-medium">We&apos;ll prioritize restaurants that match.</p>
            </section>

            <div className="grid grid-cols-2 gap-4">
              {DIETARY_OPTIONS.map((opt) => (
                <button key={opt.id} onClick={() => vm.setDietary(opt.id as DietaryRestriction)}
                  className={cn('p-6 rounded-2xl flex flex-col items-start gap-3 transition-all active:scale-95',
                    vm.data.dietaryRestriction === opt.id ? 'bg-primary text-white shadow-xl shadow-primary/30 border-2 border-primary' : 'bg-white border-2 border-surface-container-low shadow-sm')}>
                  <span className="text-3xl">{opt.emoji}</span>
                  <span className={cn('font-extrabold', vm.data.dietaryRestriction === opt.id ? 'text-white' : 'text-on-surface')}>{opt.label}</span>
                </button>
              ))}
            </div>
          </>
        )}

        {/* ── Step 3: Budget ── */}
        {vm.step === 3 && (
          <>
            <section className="mb-12">
              <h1 className="text-3xl font-extrabold tracking-tighter text-on-surface mb-4 font-display">
                What&apos;s your budget?
              </h1>
              <p className="text-base text-on-surface-variant font-medium">We&apos;ll recommend places that fit.</p>
            </section>

            <div className="flex flex-col gap-4">
              {BUDGET_OPTIONS.map((opt) => (
                <button key={opt.id} onClick={() => vm.setBudget(opt.id as BudgetRange)}
                  className={cn('p-6 rounded-2xl flex items-center gap-5 transition-all active:scale-95 w-full text-left',
                    vm.data.budgetRange === opt.id ? 'bg-primary text-white shadow-xl shadow-primary/30 border-2 border-primary' : 'bg-white border-2 border-surface-container-low shadow-sm')}>
                  <span className="text-2xl">{opt.emoji}</span>
                  <div>
                    <span className={cn('font-extrabold text-lg block', vm.data.budgetRange === opt.id ? 'text-white' : 'text-on-surface')}>{opt.label}</span>
                    <span className={cn('text-sm', vm.data.budgetRange === opt.id ? 'text-white/70' : 'text-on-surface-variant')}>{opt.desc}</span>
                  </div>
                </button>
              ))}
            </div>
          </>
        )}
      </main>

      {/* Bottom CTA */}
      <footer className="fixed bottom-0 left-0 right-0 z-50 px-6 pb-12 pt-8 bg-white/90 backdrop-blur-2xl border-t border-surface-container-low">
        <button
          onClick={vm.step < vm.totalSteps - 1 ? vm.nextStep : vm.submit}
          disabled={vm.isSubmitting}
          className="w-full h-20 bg-primary text-white font-display font-extrabold text-xl rounded-full shadow-2xl shadow-primary/40 flex items-center justify-center gap-3 transition-all hover:scale-[1.02] active:scale-95 disabled:opacity-50"
        >
          {vm.isSubmitting
            ? 'Saving...'
            : vm.step < vm.totalSteps - 1
              ? 'Next'
              : 'Generate My Custom Routes'}
          <span className="material-symbols-outlined font-bold" style={{ fontVariationSettings: '"FILL" 1' }}>
            {vm.step < vm.totalSteps - 1 ? 'arrow_forward' : 'auto_awesome'}
          </span>
        </button>
        {vm.error && <p className="text-tertiary text-sm text-center mt-3">{vm.error}</p>}
      </footer>

      {/* Floating pulse */}
      <div className="fixed top-24 right-6 z-40">
        <div className="w-4 h-4 bg-primary rounded-full animate-pulse shadow-[0_0_15px_rgba(0,110,43,0.4)]" />
      </div>
    </div>
  );
}
