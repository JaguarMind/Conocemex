'use client';

import { useRouter } from 'next/navigation';
import { useRegisterViewModel } from '../viewmodels/use-register-viewmodel';
import { cn } from '@/core/utils/cn';

export function RegisterView() {
  const router = useRouter();
  const vm = useRegisterViewModel();

  return (
    <div className="bg-surface text-on-surface min-h-screen relative">
      {/* Decorative blurs */}
      <div className="fixed -bottom-24 -right-24 w-64 h-64 bg-primary-container/5 rounded-full blur-[80px] -z-10" />
      <div className="fixed -top-24 -left-24 w-64 h-64 bg-secondary-container/5 rounded-full blur-[80px] -z-10" />

      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl h-16 flex items-center px-6">
        <button
          onClick={() => router.push('/')}
          className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-surface-container transition-colors"
        >
          <span className="material-symbols-outlined text-on-secondary-fixed">arrow_back</span>
        </button>
        <div className="ml-4">
          <span className="font-display text-xl font-extrabold text-on-secondary-fixed tracking-tighter">
            CONOCEMEX
          </span>
        </div>
      </header>

      <main className="pt-24 pb-12 px-6 flex flex-col min-h-screen max-w-md mx-auto">
        {/* Headline */}
        <section className="mb-10">
          <h1 className="text-[2.5rem] font-extrabold leading-tight text-on-secondary-fixed tracking-tight mb-3 font-display">
            Crea tu cuenta
          </h1>
          <p className="text-secondary font-medium leading-relaxed">
            Únete a la aventura y apoya al comercio local
          </p>
        </section>

        {/* Form */}
        <form
          className="space-y-6 flex-grow"
          onSubmit={(e) => {
            e.preventDefault();
            vm.register();
          }}
        >
          {/* General error */}
          {vm.errors.general && (
            <div className="bg-error-container/20 text-error rounded-xl px-5 py-3 text-sm font-medium">
              {vm.errors.general}
            </div>
          )}

          {/* Full Name */}
          <div className="space-y-2">
            <label className="block text-sm font-bold text-on-secondary-fixed ml-1" htmlFor="name">
              Nombre completo
            </label>
            <input
              id="name"
              type="text"
              value={vm.fullName}
              onChange={(e) => vm.setFullName(e.target.value)}
              placeholder="Ej. Juan Pérez"
              className={cn(
                'w-full h-16 px-5 rounded-lg border-2 bg-white text-on-surface focus:ring-4 focus:ring-primary-container/30 focus:border-primary outline-none transition-all duration-200 text-lg placeholder:text-outline-variant font-medium',
                vm.errors.fullName ? 'border-error' : 'border-on-secondary-fixed',
              )}
            />
            {vm.errors.fullName && (
              <p className="text-error text-xs font-semibold ml-1">{vm.errors.fullName}</p>
            )}
          </div>

          {/* Email */}
          <div className="space-y-2">
            <label className="block text-sm font-bold text-on-secondary-fixed ml-1" htmlFor="email">
              Correo electrónico
            </label>
            <input
              id="email"
              type="email"
              value={vm.email}
              onChange={(e) => vm.setEmail(e.target.value)}
              placeholder="nombre@ejemplo.com"
              className={cn(
                'w-full h-16 px-5 rounded-lg border-2 bg-white text-on-surface focus:ring-4 focus:ring-primary-container/30 focus:border-primary outline-none transition-all duration-200 text-lg placeholder:text-outline-variant font-medium',
                vm.errors.email ? 'border-error' : 'border-on-secondary-fixed',
              )}
            />
            {vm.errors.email && (
              <p className="text-error text-xs font-semibold ml-1">{vm.errors.email}</p>
            )}
          </div>

          {/* Password */}
          <div className="space-y-2">
            <label className="block text-sm font-bold text-on-secondary-fixed ml-1" htmlFor="password">
              Contraseña
            </label>
            <input
              id="password"
              type="password"
              value={vm.password}
              onChange={(e) => vm.setPassword(e.target.value)}
              placeholder="••••••••"
              className={cn(
                'w-full h-16 px-5 rounded-lg border-2 bg-white text-on-surface focus:ring-4 focus:ring-primary-container/30 focus:border-primary outline-none transition-all duration-200 text-lg placeholder:text-outline-variant font-medium',
                vm.errors.password ? 'border-error' : 'border-on-secondary-fixed',
              )}
            />
            {vm.errors.password && (
              <p className="text-error text-xs font-semibold ml-1">{vm.errors.password}</p>
            )}
          </div>

          {/* Terms */}
          <div className="flex items-start space-x-3 pt-2">
            <button
              type="button"
              onClick={vm.toggleTerms}
              className={cn(
                'w-5 h-5 rounded border-2 flex items-center justify-center shrink-0 mt-0.5 transition-all',
                vm.acceptedTerms
                  ? 'bg-primary border-primary'
                  : vm.errors.terms
                    ? 'border-error'
                    : 'border-on-secondary-fixed',
              )}
            >
              {vm.acceptedTerms && (
                <span className="material-symbols-outlined text-white text-sm" style={{ fontVariationSettings: '"FILL" 1' }}>
                  check
                </span>
              )}
            </button>
            <label
              className={cn(
                'text-sm font-medium leading-tight cursor-pointer',
                vm.errors.terms ? 'text-error' : 'text-on-secondary-fixed',
              )}
              onClick={vm.toggleTerms}
            >
              Acepto los términos y condiciones
            </label>
          </div>
          {vm.errors.terms && (
            <p className="text-error text-xs font-semibold ml-1 -mt-4">{vm.errors.terms}</p>
          )}

          {/* Submit */}
          <div className="pt-6">
            <button
              type="submit"
              disabled={vm.isLoading}
              className="w-full h-16 bg-primary-container text-on-primary-container text-lg font-extrabold rounded-xl shadow-[0px_4px_24px_rgba(0,223,95,0.25)] hover:scale-[1.02] active:scale-95 transition-all duration-200 uppercase tracking-widest disabled:opacity-50"
            >
              {vm.isLoading ? 'Registrando...' : 'Registrarme'}
            </button>
          </div>
        </form>

        {/* Footer */}
        <footer className="mt-12 text-center">
          <p className="text-on-secondary-fixed font-medium">
            ¿Ya tienes cuenta?{' '}
            <a
              href="/"
              className="text-primary font-bold hover:underline underline-offset-4 ml-1"
            >
              Inicia sesión
            </a>
          </p>
        </footer>
      </main>
    </div>
  );
}
