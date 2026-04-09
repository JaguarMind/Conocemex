'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { directChatService } from '../services/direct-chat.service';
import type { Conversation } from '../models/direct-chat.types';

export function useConversationsList() {
  const { user } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    if (!user?.id) return;
    setIsLoading(true);
    const data = await directChatService.getConversations(user.id);
    setConversations(data);
    setIsLoading(false);
  }, [user?.id]);

  useEffect(() => { load(); }, [load]);

  return { conversations, isLoading, userId: user?.id ?? '', refresh: load };
}
