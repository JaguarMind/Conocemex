'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/core/utils/cn';

const navItems = [
  { href: '/map', icon: 'map' },
  { href: '/discover', icon: 'restaurant' },
  { href: '/communities', icon: 'forum' },
  { href: '/profile', icon: 'person' },
];

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-6 left-1/2 -translate-x-1/2 w-[90%] max-w-md rounded-full bg-on-secondary-fixed/80 backdrop-blur-xl shadow-2xl shadow-on-secondary-fixed/40 flex justify-around items-center h-16 px-4 z-50">
      {navItems.map((item) => {
        const isActive = pathname === item.href;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              'relative flex items-center justify-center transition-all active:scale-90 duration-150',
              isActive
                ? "text-primary-container after:content-[''] after:absolute after:-bottom-1 after:w-1 after:h-1 after:bg-primary-container after:rounded-full"
                : 'text-white/60 hover:text-white',
            )}
          >
            <span
              className="material-symbols-outlined"
              style={isActive ? { fontVariationSettings: '"FILL" 1' } : undefined}
            >
              {item.icon}
            </span>
          </Link>
        );
      })}
    </nav>
  );
}
