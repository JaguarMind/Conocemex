'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCommunityChat } from '../viewmodels/use-community-chat-viewmodel';
import { cn } from '@/core/utils/cn';

interface Props {
  communityId: string;
}

export function CommunityChatView({ communityId }: Props) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const communityName = searchParams.get('name') ?? 'Community';

  const vm = useCommunityChat(communityId);

  return (
    <div className="bg-background min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
        <button onClick={() => router.push('/communities')} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">arrow_back</span>
        </button>
        <div className="w-9 h-9 bg-secondary-container/30 rounded-full flex items-center justify-center">
          <span className="material-symbols-outlined text-on-secondary-container text-lg">group</span>
        </div>
        <div className="flex-1 min-w-0">
          <h1 className="font-display font-bold text-on-surface text-sm truncate">{communityName}</h1>
          <p className="text-[10px] text-on-surface-variant">Community chat</p>
        </div>
        <div className="flex items-center gap-1 bg-primary-container/10 px-2.5 py-1 rounded-full">
          <span className="material-symbols-outlined text-primary text-xs">translate</span>
          <span className="text-[10px] font-bold text-primary">Auto</span>
        </div>
      </header>

      {/* Messages */}
      <main className="flex-1 pt-20 pb-20 px-4 overflow-y-auto">
        {vm.isLoading ? (
          <div className="flex items-center justify-center h-40">
            <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
          </div>
        ) : vm.messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-40 text-center">
            <span className="material-symbols-outlined text-4xl text-on-surface-variant/30 mb-2">forum</span>
            <p className="text-on-surface-variant text-sm">No messages yet. Start the conversation!</p>
          </div>
        ) : (
          <div className="space-y-3">
            {vm.messages.map((msg) => {
              const isMine = msg.sender_id === vm.userId;
              return (
                <div key={msg.id} className={cn('flex flex-col max-w-[85%]', isMine ? 'ml-auto items-end' : 'mr-auto items-start')}>
                  {/* Sender name (not mine) */}
                  {!isMine && (
                    <p className="text-[10px] font-bold text-on-surface-variant ml-3 mb-0.5">
                      {msg.senderName ?? 'User'}
                    </p>
                  )}

                  {/* Message bubble */}
                  {/* Message bubble */}
                  <div className={cn(
                    'px-4 py-2.5 shadow-sm',
                    isMine
                      ? 'bg-primary-container/15 text-on-surface rounded-2xl rounded-br-md'
                      : 'bg-surface-container-low text-on-surface rounded-2xl rounded-bl-md',
                  )}>
                    {/* Show translation as main text for received messages */}
                    {!isMine && msg.translatedContent && msg.translatedContent !== msg.content ? (
                      <>
                        <p className="text-sm">{msg.translatedContent}</p>
                        <div className="flex items-center gap-1 mt-1.5 pt-1.5 border-t border-on-surface/5">
                          <span className="material-symbols-outlined text-[11px] text-on-surface-variant/40">translate</span>
                          <p className="text-[11px] text-on-surface-variant/40 italic">{msg.content}</p>
                        </div>
                      </>
                    ) : (
                      <p className="text-sm">{msg.content}</p>
                    )}
                  </div>

                  {/* Translating indicator */}
                  {msg.isTranslating && (
                    <div className="flex items-center gap-1 mt-1 px-3">
                      <div className="w-3 h-3 border border-primary-container border-t-transparent rounded-full animate-spin" />
                      <span className="text-[10px] text-on-surface-variant">Translating...</span>
                    </div>
                  )}

                  {/* Time */}
                  <span className="text-[10px] text-on-surface-variant/40 mt-0.5 px-1">
                    {new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              );
            })}
            <div ref={vm.bottomRef} />
          </div>
        )}
      </main>

      {/* Input */}
      <footer className="fixed bottom-0 left-0 w-full bg-surface/95 backdrop-blur-md px-4 py-3 border-t border-surface-container-low">
        <div className="flex items-end gap-2 max-w-lg mx-auto">
          <div className="flex-1 bg-surface-container-lowest rounded-2xl shadow-sm">
            <textarea
              value={vm.newMessage}
              onChange={(e) => vm.setNewMessage(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); vm.sendMessage(); }
              }}
              placeholder="Type a message..."
              className="w-full bg-transparent border-none rounded-2xl px-4 py-3 text-sm text-on-surface resize-none focus:ring-0 focus:outline-none placeholder:text-on-surface-variant/40 max-h-32"
              rows={1}
            />
          </div>
          <button
            onClick={vm.sendMessage}
            disabled={!vm.newMessage.trim() || vm.isSending}
            className={cn(
              'w-12 h-12 rounded-full flex items-center justify-center transition-all active:scale-90 shrink-0',
              vm.newMessage.trim() ? 'bg-primary-container text-on-primary-container shadow-lg' : 'bg-surface-container text-on-surface-variant/40',
            )}
          >
            <span className="material-symbols-outlined" style={{ fontVariationSettings: '"FILL" 1' }}>
              {vm.isSending ? 'hourglass_empty' : 'send'}
            </span>
          </button>
        </div>
      </footer>
    </div>
  );
}
