import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/offering_model.dart';

abstract class OfferingRemoteDataSource {
  Future<List<OfferingModel>> getOfferingsByBusiness(String businessId);
  Future<OfferingModel> createOffering(Map<String, dynamic> offeringData, Map<String, dynamic> translationData);
}

class OfferingRemoteDataSourceImpl implements OfferingRemoteDataSource {
  final SupabaseClient supabaseClient;

  OfferingRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<OfferingModel>> getOfferingsByBusiness(String businessId) async {
    final rows = await supabaseClient
        .from('offerings')
        .select('*, offering_translations(name, description)')
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('sort_order');

    return rows
        .map((row) => OfferingModel.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<OfferingModel> createOffering(
    Map<String, dynamic> offeringData,
    Map<String, dynamic> translationData,
  ) async {
    // Insert offering
    final offeringRow = await supabaseClient
        .from('offerings')
        .insert(offeringData)
        .select()
        .single();

    final offeringId = offeringRow['id'] as String;

    // Get Spanish language ID
    final langRow = await supabaseClient
        .from('languages')
        .select('id')
        .eq('code', 'es')
        .single();

    // Insert translation
    await supabaseClient.from('offering_translations').insert({
      'offering_id': offeringId,
      'language_id': langRow['id'],
      ...translationData,
    });

    // Fetch full offering with translation
    final fullRow = await supabaseClient
        .from('offerings')
        .select('*, offering_translations(name, description)')
        .eq('id', offeringId)
        .single();

    return OfferingModel.fromSupabase(Map<String, dynamic>.from(fullRow));
  }
}
