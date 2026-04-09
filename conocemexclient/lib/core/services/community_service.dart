import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  final SupabaseClient supabaseClient;

  CommunityService(this.supabaseClient);

  String get _userId => supabaseClient.auth.currentUser!.id;

  /// Comunidades donde soy miembro.
  Future<List<Map<String, dynamic>>> getMyCommunities() async {
    final rows = await supabaseClient
        .from('community_members')
        .select('community_id, role, communities(id, name, description, icon_url, cover_image_url, member_count, slug, creator_id)')
        .eq('profile_id', _userId)
        .order('joined_at', ascending: false);

    return rows.map((row) {
      final c = row['communities'] as Map<String, dynamic>;
      return {
        ...c,
        'my_role': row['role'],
      };
    }).toList();
  }

  /// Crear comunidad con codigo de invitacion y auto-unirse como admin.
  Future<Map<String, dynamic>> createCommunity({
    required String name,
    String? description,
  }) async {
    final inviteCode = _generateInviteCode();
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    final row = await supabaseClient
        .from('communities')
        .insert({
          'creator_id': _userId,
          'name': name,
          'slug': '$slug-$inviteCode',
          'description': description,
        })
        .select()
        .single();

    // Auto-join como admin
    await supabaseClient.from('community_members').insert({
      'community_id': row['id'],
      'profile_id': _userId,
      'role': 'admin',
    });

    return Map<String, dynamic>.from(row);
  }

  /// Unirse a una comunidad por su ID.
  Future<void> joinCommunity(String communityId) async {
    await supabaseClient.from('community_members').insert({
      'community_id': communityId,
      'profile_id': _userId,
      'role': 'member',
    });
  }

  /// Unirse a una comunidad usando el codigo de invitacion (slug).
  /// Retorna el nombre de la comunidad si se unio, o lanza error.
  Future<String> joinByInviteCode(String code) async {
    final trimmed = code.trim().toLowerCase();

    // Buscar comunidad por slug (el slug contiene el invite code)
    final row = await supabaseClient
        .from('communities')
        .select('id, name, slug')
        .or('slug.eq.$trimmed,slug.ilike.%$trimmed')
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) {
      throw Exception('Codigo de invitacion no valido');
    }

    // Verificar si ya es miembro
    final existing = await supabaseClient
        .from('community_members')
        .select('community_id')
        .eq('community_id', row['id'])
        .eq('profile_id', _userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya eres miembro de esta comunidad');
    }

    await joinCommunity(row['id'] as String);
    return row['name'] as String;
  }

  /// Obtener el codigo de invitacion de una comunidad (es el slug).
  String getInviteCode(Map<String, dynamic> community) {
    return community['slug'] as String? ?? '';
  }

  /// Salir de una comunidad.
  Future<void> leaveCommunity(String communityId) async {
    await supabaseClient
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('profile_id', _userId);
  }

  /// Genera un codigo alfanumerico de 6 caracteres.
  String _generateInviteCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
