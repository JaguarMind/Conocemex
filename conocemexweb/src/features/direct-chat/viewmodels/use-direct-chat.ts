'use client';

import { useEffect } from 'react';
import { useChat } from '@/core/hooks/use-chat';
import { directChatService } from '../services/direct-chat.service';
import type { DirectMessage } from '../models/direct-chat.types';

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

  // Mark as read when opening
  useEffect(() => {
    if (!chat.userId) return;
    directChatService.markAsRead(conversationId, chat.userId);
  }, [conversationId, chat.userId]);

  return chat;
}
