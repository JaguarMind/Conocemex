import { cn } from '@/core/utils/cn';
import { forwardRef, type SelectHTMLAttributes } from 'react';
import type { SelectOption } from '@/core/types/common.types';

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  options: SelectOption[];
  placeholder?: string;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, options, placeholder, className, id, ...props }, ref) => {
    const selectId = id ?? label?.toLowerCase().replace(/\s+/g, '-');

    return (
      <div className="flex flex-col gap-1.5">
        {label && (
          <label htmlFor={selectId} className="text-sm font-medium text-on-surface-variant">
            {label}
          </label>
        )}
        <select
          ref={ref}
          id={selectId}
          className={cn(
            'rounded-full bg-surface-container-low px-5 py-3 text-base text-on-surface transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-primary-container appearance-none',
            error && 'ring-2 ring-tertiary-container',
            className,
          )}
          {...props}
        >
          {placeholder && (
            <option value="" disabled>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        {error && <p className="text-sm text-tertiary-container pl-4">{error}</p>}
      </div>
    );
  },
);

Select.displayName = 'Select';
