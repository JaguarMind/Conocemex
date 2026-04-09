import { Suspense } from 'react';
import { ChatSetupView } from '@/features/chat/views/chat-setup-view';

export default function ChatSetupPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-screen">Loading...</div>}>
      <ChatSetupView />
    </Suspense>
  );
}
