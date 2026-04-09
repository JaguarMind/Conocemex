'use client';

import { useParams } from 'next/navigation';
import { CommunityChatView } from '@/features/communities/views/community-chat-view';

export function CommunityChatContent() {
  const params = useParams();
  const communityId = params.id as string;
  return <CommunityChatView communityId={communityId} />;
}
