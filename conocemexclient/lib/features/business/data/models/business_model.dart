import '../../domain/entities/business_entity.dart';

class BusinessModel {
  final String id;
  final String ownerId;
  final String categoryId;
  final String name;
  final String? phone;
  final String? address;
  final double latitude;
  final double longitude;
  final String? coverImageUrl;
  final bool isVerified;
  final bool isActive;
  final int totalVisits;
  final double? averageRating;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.categoryId,
    required this.name,
    this.phone,
    this.address,
    required this.latitude,
    required this.longitude,
    this.coverImageUrl,
    required this.isVerified,
    required this.isActive,
    required this.totalVisits,
    this.averageRating,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessModel.fromSupabase(Map<String, dynamic> row) {
    String? categoryName;
    final categories = row['categories'];
    if (categories is Map<String, dynamic>) {
      final translations = categories['category_translations'];
      if (translations is List && translations.isNotEmpty) {
        categoryName = translations[0]['name'] as String?;
      }
    }

    return BusinessModel(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String,
      categoryId: row['category_id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      coverImageUrl: row['cover_image_url'] as String?,
      isVerified: row['is_verified'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
      totalVisits: row['total_visits'] as int? ?? 0,
      averageRating: (row['average_rating'] as num?)?.toDouble(),
      categoryName: categoryName,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  BusinessEntity toEntity() {
    return BusinessEntity(
      id: id,
      ownerId: ownerId,
      categoryId: categoryId,
      name: name,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      coverImageUrl: coverImageUrl,
      isVerified: isVerified,
      isActive: isActive,
      totalVisits: totalVisits,
      averageRating: averageRating,
      categoryName: categoryName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
