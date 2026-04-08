import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel?> getCurrentProfile();
  Future<ProfileModel?> updateProfileRole(String role);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<ProfileModel?> getCurrentProfile() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final row = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return ProfileModel.fromUserId(userId);
    }

    return ProfileModel.fromSupabase(Map<String, dynamic>.from(row));
  }

  @override
  Future<ProfileModel?> updateProfileRole(String role) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await supabaseClient
        .from('profiles')
        .update({'role': role})
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromSupabase(Map<String, dynamic>.from(row));
  }
}
