import '../../domain/entities/category_entity.dart';

class CategoryModel {
  final String id;
  final String slug;
  final String? icon;
  final int sortOrder;
  final String name;
  final String? description;

  CategoryModel({
    required this.id,
    required this.slug,
    this.icon,
    required this.sortOrder,
    required this.name,
    this.description,
  });

  factory CategoryModel.fromSupabase(Map<String, dynamic> row) {
    String name = '';
    String? description;

    final translations = row['category_translations'];
    if (translations is List && translations.isNotEmpty) {
      final t = translations[0] as Map<String, dynamic>;
      name = t['name'] as String? ?? '';
      description = t['description'] as String?;
    }

    return CategoryModel(
      id: row['id'] as String,
      slug: row['slug'] as String,
      icon: row['icon'] as String?,
      sortOrder: row['sort_order'] as int? ?? 0,
      name: name,
      description: description,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      slug: slug,
      icon: icon,
      sortOrder: sortOrder,
      name: name,
      description: description,
    );
  }
}
