'use client';

import { useParams } from 'next/navigation';
import { DirectChatView } from '@/features/direct-chat/views/direct-chat-view';

export function DirectChatContent() {
  const params = useParams();
  const convId = params.convId as string;
  return <DirectChatView conversationId={convId} />;
}
