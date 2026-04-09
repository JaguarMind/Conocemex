import type { ChatMessage } from '@/core/hooks/use-chat';

export interface DirectMessage extends ChatMessage {
  conversation_id: string;
  shared_offering_id: string | null;
  is_read: boolean;
  sender: { id: string; full_name: string | null; avatar_url: string | null } | null;
}

export interface Conversation {
  id: string;
  buyer_id: string;
  owner_id: string;
  last_message_at: string | null;
  last_message_preview: string | null;
  buyer_unread: number;
  owner_unread: number;
  business: { id: string; name: string; cover_image_url: string | null } | null;
  buyer: { full_name: string | null; avatar_url: string | null } | null;
  owner: { full_name: string | null; avatar_url: string | null } | null;
}
