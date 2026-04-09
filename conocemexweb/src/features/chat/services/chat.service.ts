import { authService } from '@/core/services/auth.service';
import type { ChatRoom, ChatMessage } from '../models/chat.types';

export const chatService = {
  async createChatRoom(params: {
    touristId: string;
    businessId: string;
    touristLanguage: string;
    firstMessage: string;
  }): Promise<ChatRoom | null> {
    const supabase = authService.client;

    // Get business name
    const { data: biz } = await supabase
      .from('businesses')
      .select('name')
      .eq('id', params.businessId)
      .single();

    // Create chat room
    const { data: room, error } = await supabase
      .from('chat_rooms')
      .insert({
        tourist_id: params.touristId,
        business_id: params.businessId,
        business_name: biz?.name ?? 'Business',
        tourist_language: params.touristLanguage,
        business_language: 'es', // Businesses in Mexico speak Spanish
        status: 'pending',
      })
      .select()
      .single();

    if (error) {
      console.error('[Chat] Create room error:', error);
      // If table doesn't exist yet, simulate
      return {
        id: crypto.randomUUID(),
        tourist_id: params.touristId,
        business_id: params.businessId,
        business_name: biz?.name ?? 'Business',
        tourist_language: params.touristLanguage,
        business_language: 'es',
        status: 'active',
        created_at: new Date().toISOString(),
      };
    }

    // Send first message
    if (room) {
      await chatService.sendMessage({
        chatId: room.id,
        senderId: params.touristId,
        text: params.firstMessage,
        originalLanguage: params.touristLanguage,
        targetLanguage: 'es',
      });
    }

    return room as ChatRoom;
  },

  async sendMessage(params: {
    chatId: string;
    senderId: string;
    text: string;
    originalLanguage: string;
    targetLanguage: string;
  }): Promise<ChatMessage | null> {
    const supabase = authService.client;

    // Simple translation simulation — in production, call DeepL/OpenAI
    const translated = await translateTextDeepL(params.text, params.originalLanguage, params.targetLanguage);

    const { data, error } = await supabase
      .from('chat_messages')
      .insert({
        chat_id: params.chatId,
        sender_id: params.senderId,
        original_text: params.text,
        translated_text: translated,
        original_language: params.originalLanguage,
        target_language: params.targetLanguage,
      })
      .select()
      .single();

    if (error) {
      console.error('[Chat] Send message error:', error);
      // Simulate if table doesn't exist
      return {
        id: crypto.randomUUID(),
        chat_id: params.chatId,
        sender_id: params.senderId,
        original_text: params.text,
        translated_text: translated,
        original_language: params.originalLanguage,
        target_language: params.targetLanguage,
        created_at: new Date().toISOString(),
      };
    }

    return data as ChatMessage;
  },

  async getMessages(chatId: string): Promise<ChatMessage[]> {
    const supabase = authService.client;

    const { data, error } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('chat_id', chatId)
      .order('created_at', { ascending: true });

    if (error) {
      console.warn('[Chat] Get messages error:', error);
      return [];
    }

    return (data ?? []) as ChatMessage[];
  },
};

// DeepL translation
async function translateTextDeepL(text: string, _from: string, to: string): Promise<string> {
  if (_from === to) return text;
  const { translateText: deepl } = await import('@/core/services/translate.service');
  return deepl(text, to);
}
