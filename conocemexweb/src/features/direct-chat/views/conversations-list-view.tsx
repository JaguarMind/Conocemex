'use client';

import { useRouter } from 'next/navigation';
import { useConversationsList } from '../viewmodels/use-conversations-list';
import { cn } from '@/core/utils/cn';

export function ConversationsListView() {
  const router = useRouter();
  const { conversations, isLoading, userId } = useConversationsList();

  return (
    <div className="bg-surface min-h-screen pb-28">
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center justify-between px-6 h-16">
        <div className="flex items-center gap-3">
          <button onClick={() => router.back()} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
            <span className="material-symbols-outlined text-on-surface">arrow_back</span>
          </button>
          <h1 className="font-display text-xl font-bold text-on-surface tracking-tight">Messages</h1>
        </div>
      </header>

      <main className="pt-20 px-5">
        {isLoading && (
          <div className="flex items-center justify-center py-20">
            <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
          </div>
        )}

        {!isLoading && conversations.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <span className="material-symbols-outlined text-5xl text-on-surface-variant/30 mb-3">chat</span>
            <p className="text-on-surface-variant font-medium">No conversations yet</p>
            <p className="text-on-surface-variant/50 text-sm mt-1">Contact a business to start chatting</p>
          </div>
        )}

        <div className="space-y-2">
          {conversations.map((c) => {
            const isBuyer = c.buyer_id === userId;
            const title = isBuyer
              ? (c.business as { name: string } | null)?.name
              : (c.buyer as { full_name: string | null } | null)?.full_name;
            const avatar = isBuyer
              ? (c.business as { cover_image_url: string | null } | null)?.cover_image_url
              : (c.buyer as { avatar_url: string | null } | null)?.avatar_url;
            const unread = isBuyer ? c.buyer_unread : c.owner_unread;

            return (
              <button
                key={c.id}
                onClick={() => router.push(`/messages/${c.id}?name=${encodeURIComponent(title ?? 'Chat')}`)}
                className="w-full flex items-center gap-3 p-4 bg-surface-container-lowest rounded-2xl shadow-sm active:scale-[0.98] transition-all text-left"
              >
                <div className="w-12 h-12 rounded-full bg-secondary-container/30 flex items-center justify-center shrink-0 overflow-hidden">
                  {avatar ? (
                    <img src={avatar} alt="" className="w-full h-full object-cover" />
                  ) : (
                    <span className="material-symbols-outlined text-on-secondary-container">person</span>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="font-bold text-on-surface text-sm truncate">{title ?? 'Chat'}</p>
                    {c.last_message_at && (
                      <span className="text-[10px] text-on-surface-variant/50 shrink-0 ml-2">
                        {new Date(c.last_message_at).toLocaleDateString([], { month: 'short', day: 'numeric' })}
                      </span>
                    )}
                  </div>
                  <p className="text-on-surface-variant text-xs truncate mt-0.5">
                    {c.last_message_preview ?? 'No messages yet'}
                  </p>
                </div>
                {unread > 0 && (
                  <span className="bg-primary-container text-on-primary-container text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center shrink-0">
                    {unread}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </main>
    </div>
  );
}
