import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient supabaseClient;

  CategoryRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final rows = await supabaseClient
        .from('categories')
        .select('*, category_translations(name, description)')
        .eq('is_active', true)
        .order('sort_order');

    return rows
        .map((row) => CategoryModel.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }
}
