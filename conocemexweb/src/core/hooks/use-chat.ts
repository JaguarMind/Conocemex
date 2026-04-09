'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { authService } from '@/core/services/auth.service';
import type { RealtimeChannel } from '@supabase/supabase-js';

const PAGE_SIZE = 50;

export interface UseChatConfig {
  table: 'community_messages' | 'direct_messages';
  scopeColumn: string;
  scopeValue: string;
  selectQuery: string;
  channelName: string;
}

export interface ChatMessage {
  id: string;
  sender_id: string;
  content: string | null;
  is_deleted: boolean;
  created_at: string;
  [key: string]: unknown;
}

export function useChat<T extends ChatMessage>(config: UseChatConfig) {
  const supabase = authService.client;
  const [messages, setMessages] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasMore, setHasMore] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const oldestCreatedAt = useRef<string | null>(null);

  // Initial load
  useEffect(() => {
    let active = true;
    (async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!active) return;
      setUserId(user?.id ?? null);

      const { data, error } = await supabase
        .from(config.table)
        .select(config.selectQuery)
        .eq(config.scopeColumn, config.scopeValue)
        .eq('is_deleted', false)
        .order('created_at', { ascending: false })
        .limit(PAGE_SIZE);

      if (!active) return;
      if (error) {
        console.error('[useChat] initial load', error);
        setLoading(false);
        return;
      }

      const ordered = ((data ?? []) as unknown as T[]).reverse();
      setMessages(ordered);
      oldestCreatedAt.current = ordered[0]?.created_at ?? null;
      setHasMore((data?.length ?? 0) === PAGE_SIZE);
      setLoading(false);
    })();
    return () => { active = false; };
  }, [config.table, config.scopeColumn, config.scopeValue, config.selectQuery, supabase]);

  // Realtime
  useEffect(() => {
    const channel: RealtimeChannel = supabase
      .channel(config.channelName)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: config.table,
        filter: `${config.scopeColumn}=eq.${config.scopeValue}`,
      }, async (payload) => {
        const { data } = await supabase
          .from(config.table)
          .select(config.selectQuery)
          .eq('id', payload.new.id)
          .single();
        if (data) setMessages((prev) => [...prev, data as unknown as T]);
      })
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: config.table,
        filter: `${config.scopeColumn}=eq.${config.scopeValue}`,
      }, (payload) => {
        setMessages((prev) =>
          (payload.new as { is_deleted: boolean }).is_deleted
            ? prev.filter((m) => m.id !== (payload.new as { id: string }).id)
            : prev.map((m) => (m.id === (payload.new as { id: string }).id ? { ...m, ...payload.new } : m)),
        );
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [config.channelName, config.table, config.scopeColumn, config.scopeValue, config.selectQuery, supabase]);

  // Actions
  const sendMessage = useCallback(async (payload: Record<string, unknown>) => {
    if (!userId) return;
    const { error } = await supabase.from(config.table).insert({
      [config.scopeColumn]: config.scopeValue,
      sender_id: userId,
      ...payload,
    });
    if (error) console.error('[useChat] send', error);
  }, [userId, config.table, config.scopeColumn, config.scopeValue, supabase]);

  const deleteMessage = useCallback(async (id: string) => {
    await supabase.from(config.table).update({ is_deleted: true }).eq('id', id);
  }, [config.table, supabase]);

  const loadMore = useCallback(async () => {
    if (!hasMore || !oldestCreatedAt.current) return;
    const { data } = await supabase
      .from(config.table)
      .select(config.selectQuery)
      .eq(config.scopeColumn, config.scopeValue)
      .eq('is_deleted', false)
      .lt('created_at', oldestCreatedAt.current)
      .order('created_at', { ascending: false })
      .limit(PAGE_SIZE);

    if (data && data.length) {
      const older = (data as unknown as T[]).reverse();
      setMessages((prev) => [...older, ...prev]);
      oldestCreatedAt.current = older[0].created_at;
    }
    setHasMore((data?.length ?? 0) === PAGE_SIZE);
  }, [hasMore, config.table, config.scopeColumn, config.scopeValue, config.selectQuery, supabase]);

  return { messages, loading, hasMore, userId, sendMessage, deleteMessage, loadMore, setMessages };
}
