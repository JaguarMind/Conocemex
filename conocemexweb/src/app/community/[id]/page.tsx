import { Suspense } from 'react';
import { CommunityChatContent } from './content';

export default function CommunityPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-screen">Loading...</div>}>
      <CommunityChatContent />
    </Suspense>
  );
}
