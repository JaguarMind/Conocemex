'use client';

import { Header } from '@/components/layout/header';
import { BottomNav } from '@/components/layout/bottom-nav';
import type { ReactNode } from 'react';

export default function TouristLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <Header />
      <main className="flex-1">{children}</main>
      <BottomNav />
    </div>
  );
}
