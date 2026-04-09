import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityChatService {
  final SupabaseClient supabaseClient;

  CommunityChatService(this.supabaseClient);

  String get _userId => supabaseClient.auth.currentUser!.id;

  // ══════════════════════════════════════
  // CHAT GRUPAL (comunidades)
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> watchMessages(String communityId) {
    return supabaseClient
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: true)
        .limit(100);
  }

  Future<void> sendMessage({
    required String communityId,
    required String content,
    String? replyToId,
  }) async {
    await supabaseClient.from('community_messages').insert({
      'community_id': communityId,
      'sender_id': _userId,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await supabaseClient
        .from('community_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  // ══════════════════════════════════════
  // CHAT 1 A 1 (conversaciones directas)
  // ══════════════════════════════════════

  /// Cargar lista de conversaciones del vendedor.
  Future<List<Map<String, dynamic>>> getMyConversations() async {
    final rows = await supabaseClient
        .from('conversations')
        .select('id, buyer_id, owner_id, business_id, last_message_at, last_message_preview, buyer_unread, owner_unread, business:businesses!business_id(name, cover_image_url), buyer:profiles!buyer_id(full_name, avatar_url)')
        .or('buyer_id.eq.$_userId,owner_id.eq.$_userId')
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Stream de mensajes directos en tiempo real.
  Stream<List<Map<String, dynamic>>> watchDirectMessages(String conversationId) {
    return supabaseClient
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(100);
  }

  /// Enviar mensaje directo.
  Future<void> sendDirectMessage({
    required String conversationId,
    required String content,
  }) async {
    await supabaseClient.from('direct_messages').insert({
      'conversation_id': conversationId,
      'sender_id': _userId,
      'content': content,
    });
  }

  /// Marcar conversacion como leida.
  Future<void> markAsRead(String conversationId) async {
    try {
      final conv = await supabaseClient
          .from('conversations')
          .select('buyer_id, owner_id')
          .eq('id', conversationId)
          .single();

      final field = conv['buyer_id'] == _userId ? 'buyer_unread' : 'owner_unread';
      await supabaseClient.from('conversations').update({field: 0}).eq('id', conversationId);
    } catch (_) {}
  }

  // ══════════════════════════════════════
  // PERFILES (cache compartido)
  // ══════════════════════════════════════

  final Map<String, Map<String, dynamic>> _profileCache = {};

  Future<Map<String, dynamic>?> getSenderProfile(String senderId) async {
    if (_profileCache.containsKey(senderId)) return _profileCache[senderId];

    try {
      final row = await supabaseClient
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('id', senderId)
          .maybeSingle();

      if (row != null) _profileCache[senderId] = Map<String, dynamic>.from(row);
      return row;
    } catch (_) {
      return null;
    }
  }
}
