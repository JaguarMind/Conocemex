import { cn } from '@/core/utils/cn';
import type { HTMLAttributes } from 'react';

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'success' | 'warning' | 'error' | 'live';
}

const variants = {
  default: 'bg-surface-container-low text-on-surface-variant',
  success: 'bg-primary-container/20 text-primary',
  warning: 'bg-tertiary-container/15 text-tertiary',
  error: 'bg-tertiary-container/20 text-tertiary',
  live: 'bg-tertiary-container text-on-tertiary animate-pulse',
};

export function Badge({ variant = 'default', className, children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold',
        variants[variant],
        className,
      )}
      {...props}
    >
      {children}
    </span>
  );
}
