'use client';

import { useEffect, useState, useCallback } from 'react';
import { useChat } from '@/core/hooks/use-chat';
import { translateText } from '@/core/services/translate.service';
import { directChatService } from '../services/direct-chat.service';
import type { DirectMessage } from '../models/direct-chat.types';
import i18n from '@/core/i18n/config';

const SELECT = `
  *,
  sender:profiles!sender_id(id, full_name, avatar_url)
`;

export function useDirectChat(conversationId: string) {
  const chat = useChat<DirectMessage>({
    table: 'direct_messages',
    scopeColumn: 'conversation_id',
    scopeValue: conversationId,
    selectQuery: SELECT,
    channelName: `conversation:${conversationId}`,
  });

  const userLang = i18n.language?.substring(0, 2) ?? 'es';
  const [translatedMessages, setTranslatedMessages] = useState<DirectMessage[]>([]);

  // Translate messages from others when they load or change
  useEffect(() => {
    async function translateAll() {
      const result: DirectMessage[] = [];
      for (const msg of chat.messages) {
        if (msg.sender_id === chat.userId || !msg.content) {
          result.push(msg);
          continue;
        }
        try {
          const translated = await translateText(msg.content, userLang);
          result.push({ ...msg, _translated: translated } as DirectMessage & { _translated: string });
        } catch {
          result.push(msg);
        }
      }
      setTranslatedMessages(result);
    }
    if (chat.messages.length > 0) {
      translateAll();
    } else {
      setTranslatedMessages([]);
    }
  }, [chat.messages, chat.userId, userLang]);

  // Mark as read when opening
  useEffect(() => {
    if (!chat.userId) return;
    directChatService.markAsRead(conversationId, chat.userId);
  }, [conversationId, chat.userId]);

  return { ...chat, messages: translatedMessages, userLang };
}
