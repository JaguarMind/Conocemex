import { Suspense } from 'react';
import { DirectChatContent } from './content';

export default function DirectChatPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-screen">Loading...</div>}>
      <DirectChatContent />
    </Suspense>
  );
}
