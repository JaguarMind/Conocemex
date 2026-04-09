'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useChatViewModel } from '../viewmodels/use-chat-viewmodel';
import { cn } from '@/core/utils/cn';

interface Props {
  chatId: string;
}

export function ChatView({ chatId }: Props) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const businessName = searchParams.get('businessName') ?? 'Business';
  const lang = searchParams.get('lang') ?? 'en';

  const vm = useChatViewModel(chatId, lang);

  return (
    <div className="bg-background min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
        <button onClick={() => router.push('/map')} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">arrow_back</span>
        </button>
        <div className="flex-1 min-w-0">
          <h1 className="font-display font-bold text-on-surface text-base truncate">{businessName}</h1>
          <div className="flex items-center gap-1">
            <span className="w-2 h-2 bg-primary-container rounded-full" />
            <p className="text-xs text-on-surface-variant">Auto-translating</p>
          </div>
        </div>
        <div className="flex items-center gap-1 bg-surface-container-low px-3 py-1.5 rounded-full">
          <span className="material-symbols-outlined text-sm text-primary">translate</span>
          <span className="text-xs font-bold text-on-surface-variant uppercase">{lang} ⇄ ES</span>
        </div>
      </header>

      {/* Messages */}
      <main className="flex-1 pt-20 pb-24 px-4 overflow-y-auto">
        {vm.isLoading ? (
          <div className="flex items-center justify-center h-40">
            <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
          </div>
        ) : vm.messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-40 text-center">
            <span className="material-symbols-outlined text-4xl text-on-surface-variant/30 mb-2">chat</span>
            <p className="text-on-surface-variant text-sm">Start the conversation!</p>
          </div>
        ) : (
          <div className="space-y-4">
            {vm.messages.map((msg) => {
              const isMine = msg.sender_id === vm.userId;
              return (
                <div key={msg.id} className={cn('flex flex-col max-w-[80%]', isMine ? 'ml-auto items-end' : 'mr-auto items-start')}>
                  {/* Message bubble */}
                  <div className={cn(
                    'px-4 py-3 rounded-2xl shadow-sm',
                    isMine
                      ? 'bg-primary-container text-on-primary-container rounded-br-md'
                      : 'bg-surface-container-lowest text-on-surface rounded-bl-md',
                  )}>
                    {!isMine && msg.translated_text && msg.translated_text !== msg.original_text ? (
                      <>
                        <p className="text-sm font-medium">{msg.translated_text}</p>
                        <div className="flex items-center gap-1 mt-1.5 pt-1.5 border-t border-on-surface/5">
                          <span className="material-symbols-outlined text-[11px] text-on-surface-variant/50">translate</span>
                          <p className="text-[11px] text-on-surface-variant/50 italic">{msg.original_text}</p>
                        </div>
                      </>
                    ) : (
                      <p className="text-sm font-medium">{msg.original_text}</p>
                    )}
                  </div>

                  <span className="text-[10px] text-on-surface-variant/50 mt-1 px-1">
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
          <div className="flex-1 bg-surface-container-lowest rounded-2xl shadow-sm flex items-end">
            <textarea
              value={vm.newMessage}
              onChange={(e) => vm.setNewMessage(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  vm.sendMessage();
                }
              }}
              placeholder="Type a message..."
              className="flex-1 bg-transparent border-none rounded-2xl px-4 py-3 text-sm text-on-surface resize-none focus:ring-0 focus:outline-none placeholder:text-on-surface-variant/40 max-h-32"
              rows={1}
            />
          </div>
          <button
            onClick={vm.sendMessage}
            disabled={!vm.newMessage.trim() || vm.isSending}
            className={cn(
              'w-12 h-12 rounded-full flex items-center justify-center transition-all active:scale-90 shrink-0',
              vm.newMessage.trim()
                ? 'bg-primary-container text-on-primary-container shadow-lg'
                : 'bg-surface-container text-on-surface-variant/40',
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
