import { cn } from '@/core/utils/cn';
import type { HTMLAttributes } from 'react';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  padding?: 'none' | 'sm' | 'md' | 'lg';
  elevated?: boolean;
}

const paddings = {
  none: '',
  sm: 'p-3',
  md: 'p-5',
  lg: 'p-8',
};

export function Card({
  padding = 'md',
  elevated = false,
  className,
  children,
  ...props
}: CardProps) {
  return (
    <div
      className={cn(
        'rounded-[2rem] bg-surface-container-lowest',
        elevated ? 'shadow-(--shadow-elevated)' : 'shadow-(--shadow-ambient)',
        paddings[padding],
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}
