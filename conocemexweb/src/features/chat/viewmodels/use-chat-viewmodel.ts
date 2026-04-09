'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { chatService } from '../services/chat.service';
import type { ChatMessage } from '../models/chat.types';

export function useChatViewModel(chatId: string, touristLanguage: string) {
  const { user } = useAuth();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const msgs = await chatService.getMessages(chatId);
      setMessages(msgs);
      setIsLoading(false);
    }
    load();
  }, [chatId]);

  const sendMessage = useCallback(async () => {
    if (!newMessage.trim() || !user?.id) return;

    setIsSending(true);
    const msg = await chatService.sendMessage({
      chatId,
      senderId: user.id,
      text: newMessage,
      originalLanguage: touristLanguage,
      targetLanguage: 'es',
    });

    if (msg) {
      setMessages((prev) => [...prev, msg]);
    }
    setNewMessage('');
    setIsSending(false);
  }, [chatId, newMessage, user?.id, touristLanguage]);

  return {
    messages,
    newMessage,
    isSending,
    isLoading,
    userId: user?.id ?? '',
    setNewMessage,
    sendMessage,
  };
}
