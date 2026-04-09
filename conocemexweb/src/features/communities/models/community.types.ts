export interface Community {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  member_count: number;
  creator_id: string;
  my_role: 'member' | 'moderator' | 'admin';
}

export interface CommunityMessage {
  id: string;
  community_id: string;
  sender_id: string;
  content: string;
  is_deleted: boolean;
  created_at: string;
  // Enriched client-side
  senderName?: string;
  senderAvatar?: string | null;
  translatedContent?: string;
  isTranslating?: boolean;
}

export interface SenderProfile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
}

export const DEEPL_LANG_MAP: Record<string, string> = {
  es: 'ES',
  en: 'EN',
  fr: 'FR',
  pt: 'PT-BR',
};
