'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/core/hooks/use-auth';
import { chatService } from '../services/chat.service';
import type { ChatSetupState } from '../models/chat.types';
import i18n from '@/core/i18n/config';

export function useChatSetupViewModel(businessId: string, businessName: string) {
  const router = useRouter();
  const { user } = useAuth();

  const [state, setState] = useState<ChatSetupState>({
    businessId,
    businessName,
    selectedLanguage: i18n.language?.substring(0, 2) ?? 'en',
    firstMessage: '',
    isSubmitting: false,
    error: null,
  });

  const setLanguage = useCallback((lang: string) => {
    setState((prev) => ({ ...prev, selectedLanguage: lang }));
  }, []);

  const setFirstMessage = useCallback((msg: string) => {
    setState((prev) => ({ ...prev, firstMessage: msg }));
  }, []);

  const startChat = useCallback(async () => {
    if (!state.firstMessage.trim()) {
      setState((prev) => ({ ...prev, error: 'Please write a message' }));
      return;
    }
    if (!user?.id) {
      setState((prev) => ({ ...prev, error: 'Please sign in to chat' }));
      return;
    }

    setState((prev) => ({ ...prev, isSubmitting: true, error: null }));

    try {
      const room = await chatService.createChatRoom({
        touristId: user.id,
        businessId: state.businessId,
        touristLanguage: state.selectedLanguage,
        firstMessage: state.firstMessage,
      });

      if (room) {
        router.push(`/chat/${room.id}?businessName=${encodeURIComponent(state.businessName)}&lang=${state.selectedLanguage}`);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to start chat';
      setState((prev) => ({ ...prev, error: message, isSubmitting: false }));
    }
  }, [state, user?.id, router]);

  return { ...state, setLanguage, setFirstMessage, startChat };
}
