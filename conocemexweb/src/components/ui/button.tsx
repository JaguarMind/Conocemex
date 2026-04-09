import { cn } from '@/core/utils/cn';
import type { ButtonHTMLAttributes } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'inverted' | 'outlined';
  size?: 'sm' | 'md' | 'lg';
}

const variants = {
  primary:
    'bg-primary-container text-on-primary-container hover:brightness-110 active:scale-[0.98]',
  secondary:
    'bg-surface-container-low text-on-surface hover:bg-surface-container active:scale-[0.98]',
  inverted:
    'bg-secondary-fixed text-on-secondary hover:brightness-110 active:scale-[0.98]',
  outlined:
    'bg-transparent text-on-surface ring-1 ring-outline-variant hover:bg-surface-container-low active:scale-[0.98]',
};

const sizes = {
  sm: 'px-4 py-1.5 text-sm',
  md: 'px-6 py-2.5 text-base',
  lg: 'px-8 py-3.5 text-lg',
};

export function Button({
  variant = 'primary',
  size = 'md',
  className,
  disabled,
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center rounded-full font-display font-semibold transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-container focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none',
        variants[variant],
        sizes[size],
        className,
      )}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
}
