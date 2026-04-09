'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { communityService } from '../services/community.service';
import { translateText } from '../services/translate.service';
import type { CommunityMessage } from '../models/community.types';
import i18n from '@/core/i18n/config';

export function useCommunityChat(communityId: string) {
  const { user } = useAuth();
  const [messages, setMessages] = useState<CommunityMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);
  const userLang = i18n.language?.substring(0, 2) ?? 'es';

  // Load messages + enrich with sender profiles + translate
  useEffect(() => {
    async function load() {
      const msgs = await communityService.getMessages(communityId);

      // Enrich with sender profiles
      const enriched = await Promise.all(
        msgs.map(async (msg) => {
          const profile = await communityService.getSenderProfile(msg.sender_id);
          return { ...msg, senderName: profile?.full_name ?? 'User', senderAvatar: profile?.avatar_url ?? null };
        }),
      );

      // Translate messages from OTHER users to my language
      const userId = user?.id;
      const translated = await Promise.all(
        enriched.map(async (msg) => {
          // Skip my own messages
          if (msg.sender_id === userId) return msg;
          try {
            const t = await translateText(msg.content, userLang);
            console.log('[Chat] Translated:', msg.content, '→', t, '(to', userLang, ')');
            return { ...msg, translatedContent: t };
          } catch (err) {
            console.warn('[Chat] Translation failed:', err);
            return msg;
          }
        }),
      );

      setMessages(translated);
      setIsLoading(false);
    }
    load();
  }, [communityId, userLang]);

  // Realtime subscription
  useEffect(() => {
    const unsub = communityService.subscribeToMessages(communityId, async (newMsg) => {
      const profile = await communityService.getSenderProfile(newMsg.sender_id);
      const isMine = newMsg.sender_id === user?.id;
      const enriched: CommunityMessage = {
        ...newMsg,
        senderName: profile?.full_name ?? 'User',
        senderAvatar: profile?.avatar_url ?? null,
        isTranslating: !isMine,
      };

      setMessages((prev) => [...prev, enriched]);

      // Only translate messages from others
      if (isMine) return;

      try {
        const translated = await translateText(newMsg.content, userLang);
        setMessages((prev) =>
          prev.map((m) => (m.id === newMsg.id ? { ...m, translatedContent: translated, isTranslating: false } : m)),
        );
      } catch {
        setMessages((prev) =>
          prev.map((m) => (m.id === newMsg.id ? { ...m, isTranslating: false } : m)),
        );
      }
    });

    return unsub;
  }, [communityId, userLang]);

  // Auto-scroll
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = useCallback(async () => {
    if (!newMessage.trim() || !user?.id) return;
    setIsSending(true);
    await communityService.sendMessage(communityId, user.id, newMessage.trim());
    setNewMessage('');
    setIsSending(false);
  }, [communityId, user?.id, newMessage]);

  const deleteMessage = useCallback(async (messageId: string) => {
    await communityService.deleteMessage(messageId);
    setMessages((prev) => prev.filter((m) => m.id !== messageId));
  }, []);

  return {
    messages, newMessage, isSending, isLoading,
    userId: user?.id ?? '',
    setNewMessage, sendMessage, deleteMessage, bottomRef,
  };
}
