import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_model.dart';

abstract class BusinessRemoteDataSource {
  Future<List<BusinessModel>> getMyBusinesses();
  Future<BusinessModel> createBusiness(Map<String, dynamic> data);
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final SupabaseClient supabaseClient;

  BusinessRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<BusinessModel>> getMyBusinesses() async {
    final userId = supabaseClient.auth.currentUser!.id;

    final rows = await supabaseClient
        .from('businesses')
        .select('*, categories(category_translations(name))')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => BusinessModel.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<BusinessModel> createBusiness(Map<String, dynamic> data) async {
    final userId = supabaseClient.auth.currentUser!.id;

    final row = await supabaseClient
        .from('businesses')
        .insert({
          ...data,
          'owner_id': userId,
        })
        .select('*, categories(category_translations(name))')
        .single();

    return BusinessModel.fromSupabase(Map<String, dynamic>.from(row));
  }
}
