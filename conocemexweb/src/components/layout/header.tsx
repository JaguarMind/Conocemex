'use client';

export function Header() {
  return (
    <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex justify-between items-center px-6 h-16">
      <div className="flex items-center gap-3">
        <span className="material-symbols-outlined text-primary-container">menu</span>
        <h1 className="text-xl font-bold tracking-tighter text-on-surface font-display">
          CONOCEMEX
        </h1>
      </div>
      <div className="w-8 h-8 rounded-full overflow-hidden border border-outline-variant/20 bg-surface-container">
        <span className="material-symbols-outlined text-on-surface-variant text-2xl flex items-center justify-center h-full">
          person
        </span>
      </div>
    </header>
  );
}
