'use client';

import { useEffect, type ReactNode } from 'react';
import { cn } from '@/core/utils/cn';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  className?: string;
}

export function Modal({ isOpen, onClose, title, children, className }: ModalProps) {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-secondary-fixed/40 backdrop-blur-sm" onClick={onClose} />
      <div
        className={cn(
          'relative z-10 w-full max-w-lg rounded-t-[2rem] sm:rounded-[2rem] bg-surface-container-lowest p-6 shadow-(--shadow-elevated) mx-0 sm:mx-4',
          className,
        )}
      >
        {title && (
          <h2 className="mb-4 text-xl font-display font-bold text-on-surface">{title}</h2>
        )}
        {children}
      </div>
    </div>
  );
}
