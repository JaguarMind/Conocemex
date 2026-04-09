import { authService } from '@/core/services/auth.service';
import type { Conversation } from '../models/direct-chat.types';

export const directChatService = {
  async openConversation(businessId: string): Promise<string | null> {
    const supabase = authService.client;

    // Try RPC first (handles dedup)
    const { data, error } = await supabase.rpc('open_conversation', {
      p_business_id: businessId,
    });

    if (!error && data) return data as string;

    // Fallback: manual lookup/create
    console.warn('[DirectChat] RPC failed, trying manual:', error);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    // Check existing
    const { data: existing } = await supabase
      .from('conversations')
      .select('id')
      .eq('business_id', businessId)
      .eq('buyer_id', user.id)
      .maybeSingle();

    if (existing) return existing.id;

    // Get business owner
    const { data: biz } = await supabase
      .from('businesses')
      .select('owner_id')
      .eq('id', businessId)
      .single();

    if (!biz) return null;

    // Create new
    const { data: conv } = await supabase
      .from('conversations')
      .insert({
        buyer_id: user.id,
        owner_id: biz.owner_id,
        business_id: businessId,
      })
      .select('id')
      .single();

    return conv?.id ?? null;
  },

  async getConversations(userId: string): Promise<Conversation[]> {
    const supabase = authService.client;

    const { data, error } = await supabase
      .from('conversations')
      .select(`
        id, buyer_id, owner_id, last_message_at, last_message_preview, buyer_unread, owner_unread,
        business:businesses!business_id(id, name, cover_image_url),
        buyer:profiles!buyer_id(full_name, avatar_url),
        owner:profiles!owner_id(full_name, avatar_url)
      `)
      .or(`buyer_id.eq.${userId},owner_id.eq.${userId}`)
      .order('last_message_at', { ascending: false, nullsFirst: false });

    if (error) {
      console.error('[DirectChat] getConversations:', error);
      return [];
    }

    return (data ?? []) as unknown as Conversation[];
  },

  async markAsRead(conversationId: string, userId: string): Promise<void> {
    const supabase = authService.client;

    const { data: conv } = await supabase
      .from('conversations')
      .select('buyer_id, owner_id')
      .eq('id', conversationId)
      .single();

    if (!conv) return;
    const field = conv.buyer_id === userId ? 'buyer_unread' : 'owner_unread';
    await supabase.from('conversations').update({ [field]: 0 }).eq('id', conversationId);
  },
};
