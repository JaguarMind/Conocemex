'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { directChatService } from '../services/direct-chat.service';
import { cn } from '@/core/utils/cn';

interface Props {
  businessId: string;
  businessName: string;
  className?: string;
  variant?: 'full' | 'icon';
}

export function ContactBusinessButton({ businessId, businessName, className, variant = 'full' }: Props) {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const handleContact = useCallback(async () => {
    setIsLoading(true);
    const convId = await directChatService.openConversation(businessId);
    if (convId) {
      router.push(`/messages/${convId}?name=${encodeURIComponent(businessName)}`);
    }
    setIsLoading(false);
  }, [businessId, businessName, router]);

  if (variant === 'icon') {
    return (
      <button
        onClick={handleContact}
        disabled={isLoading}
        className={cn('bg-secondary-container text-on-secondary-container font-bold py-2.5 px-4 rounded-full text-sm active:scale-95 transition-all flex items-center gap-1 disabled:opacity-50', className)}
      >
        <span className="material-symbols-outlined text-[16px]">chat</span>
        Chat
      </button>
    );
  }

  return (
    <button
      onClick={handleContact}
      disabled={isLoading}
      className={cn('flex-1 bg-secondary-container text-on-secondary-container py-3.5 rounded-full font-display font-extrabold text-sm flex items-center justify-center gap-1.5 active:scale-95 transition-all disabled:opacity-50', className)}
    >
      <span className="material-symbols-outlined text-lg">chat</span>
      {isLoading ? 'Opening...' : 'Chat'}
    </button>
  );
}
