'use client';

import Link from 'next/link';

export function Sidebar() {
  return (
    <aside className="fixed left-0 top-0 z-40 flex h-full w-64 flex-col bg-secondary-fixed text-on-secondary">
      <div className="flex h-16 items-center px-6">
        <h1 className="text-lg font-display font-bold text-primary-container tracking-tight">
          CONOCEMEX
        </h1>
      </div>
      <nav className="flex flex-col gap-1 px-3 mt-4">
        <Link
          href="/dashboard"
          className="rounded-2xl px-4 py-3 text-sm font-medium text-on-secondary/70 hover:bg-white/10 hover:text-on-secondary transition-all duration-200"
        >
          Dashboard de Impacto
        </Link>
      </nav>
    </aside>
  );
}
