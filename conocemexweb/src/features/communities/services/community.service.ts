import { authService } from '@/core/services/auth.service';
import type { Community, CommunityMessage, SenderProfile } from '../models/community.types';

const profileCache = new Map<string, SenderProfile>();

export const communityService = {
  async getMyCommunities(userId: string): Promise<Community[]> {
    const supabase = authService.client;
    const { data, error } = await supabase
      .from('community_members')
      .select('community_id, role, communities(id, name, description, slug, member_count, creator_id)')
      .eq('profile_id', userId)
      .order('joined_at', { ascending: false });

    if (error) { console.error('[Communities]', error); return []; }

    return (data ?? []).map((row) => {
      const c = row.communities as unknown as Omit<Community, 'my_role'>;
      return { ...c, my_role: row.role as Community['my_role'] };
    });
  },

  async createCommunity(userId: string, name: string, description?: string): Promise<Community | null> {
    const supabase = authService.client;
    const code = Array.from({ length: 6 }, () => 'abcdefghijklmnopqrstuvwxyz0123456789'[Math.floor(Math.random() * 36)]).join('');
    const slug = name.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-');

    const { data: community, error } = await supabase
      .from('communities')
      .insert({ creator_id: userId, name, slug: `${slug}-${code}`, description: description ?? null })
      .select()
      .single();

    if (error) { console.error('[Communities] Create:', error); return null; }

    await supabase.from('community_members').insert({ community_id: community.id, profile_id: userId, role: 'admin' });

    return { ...community, my_role: 'admin' } as Community;
  },

  async joinByCode(userId: string, code: string): Promise<Community | null> {
    const supabase = authService.client;
    const trimmed = code.trim().toLowerCase();

    const { data: community } = await supabase
      .from('communities')
      .select('id, name, slug, description, member_count, creator_id')
      .or(`slug.eq.${trimmed},slug.ilike.%${trimmed}`)
      .eq('is_active', true)
      .maybeSingle();

    if (!community) return null;

    const { data: existing } = await supabase
      .from('community_members')
      .select('community_id')
      .eq('community_id', community.id)
      .eq('profile_id', userId)
      .maybeSingle();

    if (existing) return { ...community, my_role: 'member' } as Community;

    await supabase.from('community_members').insert({ community_id: community.id, profile_id: userId, role: 'member' });
    return { ...community, my_role: 'member' } as Community;
  },

  async leaveCommunity(userId: string, communityId: string): Promise<void> {
    const supabase = authService.client;
    await supabase.from('community_members').delete().eq('community_id', communityId).eq('profile_id', userId);
  },

  async getMessages(communityId: string): Promise<CommunityMessage[]> {
    const supabase = authService.client;
    const { data } = await supabase
      .from('community_messages')
      .select('*')
      .eq('community_id', communityId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true })
      .limit(100);
    return (data ?? []) as CommunityMessage[];
  },

  async sendMessage(communityId: string, senderId: string, content: string): Promise<void> {
    const supabase = authService.client;
    await supabase.from('community_messages').insert({ community_id: communityId, sender_id: senderId, content });
  },

  async deleteMessage(messageId: string): Promise<void> {
    const supabase = authService.client;
    await supabase.from('community_messages').update({ is_deleted: true }).eq('id', messageId);
  },

  async getSenderProfile(senderId: string): Promise<SenderProfile | null> {
    if (profileCache.has(senderId)) return profileCache.get(senderId)!;
    const supabase = authService.client;
    const { data } = await supabase.from('profiles').select('id, full_name, avatar_url').eq('id', senderId).maybeSingle();
    if (data) profileCache.set(senderId, data as SenderProfile);
    return data as SenderProfile | null;
  },

  subscribeToMessages(communityId: string, onMessage: (msg: CommunityMessage) => void) {
    const supabase = authService.client;
    const channel = supabase
      .channel(`community-${communityId}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'community_messages', filter: `community_id=eq.${communityId}` },
        (payload) => onMessage(payload.new as CommunityMessage))
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  },
};
