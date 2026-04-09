'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useEffect, useRef } from 'react';
import { useDirectChat } from '../viewmodels/use-direct-chat';
import { cn } from '@/core/utils/cn';

interface Props {
  conversationId: string;
}

export function DirectChatView({ conversationId }: Props) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const chatName = searchParams.get('name') ?? 'Chat';

  const { messages, loading, userId, sendMessage, deleteMessage, loadMore, hasMore } =
    useDirectChat(conversationId);

  const scrollRef = useRef<HTMLDivElement>(null);
  const stickBottom = useRef(true);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  // Auto-scroll
  useEffect(() => {
    if (!scrollRef.current || !stickBottom.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages]);

  const handleScroll = () => {
    const el = scrollRef.current;
    if (!el) return;
    stickBottom.current = el.scrollHeight - el.scrollTop - el.clientHeight < 100;
    if (el.scrollTop < 80 && hasMore) loadMore();
  };

  const handleSend = async () => {
    const text = inputRef.current?.value?.trim();
    if (!text) return;
    stickBottom.current = true;
    if (inputRef.current) inputRef.current.value = '';
    await sendMessage({ content: text });
  };

  return (
    <div className="bg-background min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
        <button onClick={() => router.push('/messages')} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">arrow_back</span>
        </button>
        <div className="w-9 h-9 bg-primary-container/20 rounded-full flex items-center justify-center">
          <span className="material-symbols-outlined text-primary text-lg">storefront</span>
        </div>
        <div className="flex-1 min-w-0">
          <h1 className="font-display font-bold text-on-surface text-sm truncate">{chatName}</h1>
          <div className="flex items-center gap-1">
            <span className="w-2 h-2 bg-primary-container rounded-full" />
            <p className="text-[10px] text-on-surface-variant">Auto-translating</p>
          </div>
        </div>
        <div className="flex items-center gap-1 bg-primary-container/10 px-2.5 py-1 rounded-full">
          <span className="material-symbols-outlined text-primary text-xs">translate</span>
          <span className="text-[10px] font-bold text-primary">DeepL</span>
        </div>
      </header>

      {/* Messages */}
      <main
        ref={scrollRef}
        onScroll={handleScroll}
        className="flex-1 pt-20 pb-20 px-4 overflow-y-auto"
      >
        {loading ? (
          <div className="flex items-center justify-center h-40">
            <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
          </div>
        ) : messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-40 text-center">
            <span className="material-symbols-outlined text-4xl text-on-surface-variant/30 mb-2">chat</span>
            <p className="text-on-surface-variant text-sm">Send a message to start the conversation</p>
          </div>
        ) : (
          <div className="space-y-3">
            {messages.map((msg) => {
              const isMine = msg.sender_id === userId;
              const senderName = (msg.sender as { full_name: string | null } | null)?.full_name;

              return (
                <div key={msg.id} className={cn('flex flex-col max-w-[80%]', isMine ? 'ml-auto items-end' : 'mr-auto items-start')}>
                  {!isMine && senderName && (
                    <p className="text-[10px] font-bold text-on-surface-variant ml-3 mb-0.5">{senderName}</p>
                  )}
                  <div
                    className={cn(
                      'px-4 py-2.5 shadow-sm',
                      isMine
                        ? 'bg-primary-container/15 text-on-surface rounded-2xl rounded-br-md'
                        : 'bg-surface-container-low text-on-surface rounded-2xl rounded-bl-md',
                    )}
                  >
                    {!isMine && (msg as Record<string, unknown>)._translated && (msg as Record<string, unknown>)._translated !== msg.content ? (
                      <>
                        <p className="text-sm">{(msg as Record<string, unknown>)._translated as string}</p>
                        <div className="flex items-center gap-1 mt-1.5 pt-1.5 border-t border-on-surface/5">
                          <span className="material-symbols-outlined text-[11px] text-on-surface-variant/40">translate</span>
                          <p className="text-[11px] text-on-surface-variant/40 italic">{msg.content}</p>
                        </div>
                      </>
                    ) : (
                      <p className="text-sm">{msg.content}</p>
                    )}
                  </div>
                  <span className="text-[10px] text-on-surface-variant/40 mt-0.5 px-1">
                    {new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </main>

      {/* Input */}
      <footer className="fixed bottom-0 left-0 w-full bg-surface/95 backdrop-blur-md px-4 py-3 border-t border-surface-container-low">
        <div className="flex items-end gap-2 max-w-lg mx-auto">
          <div className="flex-1 bg-surface-container-lowest rounded-2xl shadow-sm">
            <textarea
              ref={inputRef}
              onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend(); } }}
              placeholder="Type a message..."
              className="w-full bg-transparent border-none rounded-2xl px-4 py-3 text-sm text-on-surface resize-none focus:ring-0 focus:outline-none placeholder:text-on-surface-variant/40 max-h-32"
              rows={1}
            />
          </div>
          <button
            onClick={handleSend}
            className="w-12 h-12 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center transition-all active:scale-90 shadow-lg shrink-0"
          >
            <span className="material-symbols-outlined" style={{ fontVariationSettings: '"FILL" 1' }}>send</span>
          </button>
        </div>
      </footer>
    </div>
  );
}
