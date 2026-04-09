'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { chatService } from '../services/chat.service';
import { translateText } from '@/core/services/translate.service';
import type { ChatMessage } from '../models/chat.types';

export function useChatViewModel(chatId: string, touristLanguage: string) {
  const { user } = useAuth();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // Load messages + translate received ones
  useEffect(() => {
    async function load() {
      const msgs = await chatService.getMessages(chatId);

      // Translate messages from the other person to my language
      const translated = await Promise.all(
        msgs.map(async (msg) => {
          if (msg.sender_id === user?.id) return msg; // My messages — no need to translate
          if (msg.translated_text && msg.original_language !== touristLanguage) return msg; // Already has translation

          try {
            const t = await translateText(msg.original_text, touristLanguage);
            return { ...msg, translated_text: t };
          } catch {
            return msg;
          }
        }),
      );

      setMessages(translated);
      setIsLoading(false);
    }
    load();
  }, [chatId, user?.id, touristLanguage]);

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
    touristLanguage,
    setNewMessage,
    sendMessage,
  };
}
