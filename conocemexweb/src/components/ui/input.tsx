import { cn } from '@/core/utils/cn';
import { forwardRef, type InputHTMLAttributes } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  icon?: React.ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, icon, className, id, ...props }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, '-');

    return (
      <div className="flex flex-col gap-1.5">
        {label && (
          <label htmlFor={inputId} className="text-sm font-medium text-on-surface-variant">
            {label}
          </label>
        )}
        <div className="relative">
          {icon && (
            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant">
              {icon}
            </span>
          )}
          <input
            ref={ref}
            id={inputId}
            className={cn(
              'w-full rounded-full bg-surface-container-low px-5 py-3 text-base text-on-surface placeholder:text-on-surface-variant/50 transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-primary-container',
              icon && 'pl-12',
              error && 'ring-2 ring-tertiary-container',
              className,
            )}
            {...props}
          />
        </div>
        {error && <p className="text-sm text-tertiary-container pl-4">{error}</p>}
      </div>
    );
  },
);

Input.displayName = 'Input';
