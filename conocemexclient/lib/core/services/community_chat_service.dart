import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityChatService {
  final SupabaseClient supabaseClient;

  CommunityChatService(this.supabaseClient);

  /// Stream en tiempo real de los mensajes de una comunidad.
  Stream<List<Map<String, dynamic>>> watchMessages(String communityId) {
    return supabaseClient
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: true)
        .limit(100);
  }

  /// Enviar un mensaje de texto.
  Future<void> sendMessage({
    required String communityId,
    required String content,
    String? replyToId,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('No autenticado');

    await supabaseClient.from('community_messages').insert({
      'community_id': communityId,
      'sender_id': userId,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  /// Soft delete de un mensaje (solo el autor puede).
  Future<void> deleteMessage(String messageId) async {
    await supabaseClient
        .from('community_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  /// Cargar perfiles de los senders para mostrar nombres.
  /// Cachea en el cliente para no repetir queries.
  final Map<String, Map<String, dynamic>> _profileCache = {};

  Future<Map<String, dynamic>?> getSenderProfile(String senderId) async {
    if (_profileCache.containsKey(senderId)) {
      return _profileCache[senderId];
    }

    try {
      final row = await supabaseClient
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('id', senderId)
          .maybeSingle();

      if (row != null) {
        _profileCache[senderId] = Map<String, dynamic>.from(row);
      }
      return row;
    } catch (_) {
      return null;
    }
  }
}
