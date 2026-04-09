'use client';

import { useLoginViewModel } from '../viewmodels/use-login-viewmodel';

export function WelcomeView() {
  const {
    email,
    password,
    isLoading,
    error,
    setEmail,
    setPassword,
    loginWithEmail,
    loginWithGoogle,
    continueAsGuest,
    skip,
  } = useLoginViewModel();

  return (
    <div className="bg-white min-h-screen flex flex-col items-center">
      {/* Header */}
      <header className="w-full max-w-md flex justify-between items-center px-6 py-6">
        <div className="text-xl font-extrabold text-on-secondary-fixed tracking-tight font-display">
          CONOCEMEX
        </div>
        <button
          onClick={skip}
          className="text-secondary font-semibold text-sm hover:bg-primary-container/10 px-4 py-2 rounded-full transition-colors active:scale-95 duration-200"
        >
          Skip
        </button>
      </header>

      <main className="w-full max-w-md mx-auto flex flex-col flex-grow">
        {/* Headline */}
        <section className="px-6 pt-8 pb-10">
          <h1 className="text-5xl font-extrabold text-on-secondary-fixed tracking-tight leading-[1.1]">
            Welcome to
            <br />
            Mexico
          </h1>
        </section>

        {/* Localization Selectors */}
        <section className="px-6">
          <div className="flex gap-3">
            <button className="flex-1 bg-white border-2 border-on-secondary-fixed/5 shadow-sm rounded-2xl py-4 px-4 flex items-center justify-between active:scale-95 transition-all">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-on-secondary-fixed text-lg">
                  public
                </span>
                <span className="text-sm font-bold text-on-secondary-fixed">
                  English (EN)
                </span>
              </div>
              <span className="material-symbols-outlined text-on-secondary-fixed/40">
                expand_more
              </span>
            </button>
            <button className="flex-1 bg-white border-2 border-on-secondary-fixed/5 shadow-sm rounded-2xl py-4 px-4 flex items-center justify-between active:scale-95 transition-all">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-on-secondary-fixed text-lg">
                  payments
                </span>
                <span className="text-sm font-bold text-on-secondary-fixed">
                  USD ($)
                </span>
              </div>
              <span className="material-symbols-outlined text-on-secondary-fixed/40">
                expand_more
              </span>
            </button>
          </div>
        </section>

        {/* Login Section */}
        <section className="px-6 pt-10 pb-12 flex-grow flex flex-col">
          {/* OAuth Buttons */}
          <div className="space-y-4">
            <button
              onClick={loginWithGoogle}
              disabled={isLoading}
              className="w-full py-4 rounded-xl border-2 border-on-secondary-fixed flex items-center justify-center gap-3 bg-white hover:bg-surface-container-low transition-all active:scale-[0.98] disabled:opacity-50"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
              <span className="font-bold text-on-secondary-fixed">
                Continue with Google
              </span>
            </button>

            <button
              disabled={isLoading}
              className="w-full py-4 rounded-xl border-2 border-on-secondary-fixed flex items-center justify-center gap-3 bg-white hover:bg-surface-container-low transition-all active:scale-[0.98] disabled:opacity-50"
            >
              <span
                className="material-symbols-outlined text-xl"
                style={{ fontVariationSettings: '"FILL" 1' }}
              >
                ios
              </span>
              <span className="font-bold text-on-secondary-fixed">
                Continue with Apple
              </span>
            </button>
          </div>

          {/* Divider */}
          <div className="flex items-center my-10">
            <div className="flex-grow h-px bg-on-secondary-fixed/10" />
            <span className="px-6 text-[11px] font-black text-on-secondary-fixed/30 uppercase tracking-widest">
              OR
            </span>
            <div className="flex-grow h-px bg-on-secondary-fixed/10" />
          </div>

          {/* Form */}
          <form
            className="space-y-5"
            onSubmit={(e) => {
              e.preventDefault();
              loginWithEmail();
            }}
          >
            <div className="space-y-1.5">
              <label className="text-[11px] font-black text-on-secondary-fixed/50 uppercase tracking-widest ml-1">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-surface-container-low border-none rounded-xl py-4 px-6 focus:ring-2 focus:ring-primary-container text-on-secondary-fixed placeholder:text-on-secondary-fixed/30 font-semibold outline-none"
                placeholder="example@conocemex.com"
              />
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between items-center">
                <label className="text-[11px] font-black text-on-secondary-fixed/50 uppercase tracking-widest ml-1">
                  Password
                </label>
                <button
                  type="button"
                  className="text-[11px] font-black text-primary-container hover:underline uppercase tracking-widest"
                >
                  Forgot?
                </button>
              </div>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-surface-container-low border-none rounded-xl py-4 px-6 focus:ring-2 focus:ring-primary-container text-on-secondary-fixed placeholder:text-on-secondary-fixed/30 font-semibold outline-none"
                placeholder="••••••••"
              />
            </div>

            {error && (
              <div className="bg-tertiary-container/10 text-tertiary rounded-xl px-4 py-3 text-sm font-medium">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-5 rounded-full bg-primary-container text-on-primary-container font-black text-lg shadow-(--shadow-glow-primary) hover:brightness-105 active:scale-95 transition-all mt-6 disabled:opacity-50"
            >
              {isLoading ? 'Loading...' : 'Log In'}
            </button>
          </form>

          {/* Bottom Actions */}
          <div className="mt-auto pt-10 text-center pb-8">
            <p className="text-secondary text-sm font-bold mb-5">
              Don&apos;t have an account?{' '}
              <a
                href="/register"
                className="text-primary-container font-black hover:underline"
              >
                Sign Up
              </a>
            </p>
            <button
              onClick={continueAsGuest}
              className="inline-flex items-center text-on-secondary-fixed/40 hover:text-on-secondary-fixed text-sm font-black tracking-tight transition-colors group uppercase"
            >
              Skip &amp; continue as Guest
              <span className="material-symbols-outlined text-sm ml-1 group-hover:translate-x-1 transition-transform">
                arrow_forward
              </span>
            </button>
          </div>
        </section>
      </main>
    </div>
  );
}
