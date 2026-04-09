'use client';

import { useParams } from 'next/navigation';
import { ChatView } from '@/features/chat/views/chat-view';

export function ChatPageContent() {
  const params = useParams();
  const chatId = params.id as string;

  return <ChatView chatId={chatId} />;
}
