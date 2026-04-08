import '../../domain/entities/offering_entity.dart';

class OfferingModel {
  final String id;
  final String businessId;
  final String type;
  final double priceMxn;
  final String priceType;
  final int? durationMin;
  final String? imageUrl;
  final bool isActive;
  final String name;
  final String? description;
  final DateTime createdAt;

  OfferingModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.priceMxn,
    required this.priceType,
    this.durationMin,
    this.imageUrl,
    required this.isActive,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory OfferingModel.fromSupabase(Map<String, dynamic> row) {
    String name = '';
    String? description;

    final translations = row['offering_translations'];
    if (translations is List && translations.isNotEmpty) {
      final t = translations[0] as Map<String, dynamic>;
      name = t['name'] as String? ?? '';
      description = t['description'] as String?;
    }

    return OfferingModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      type: row['type'] as String,
      priceMxn: (row['price_mxn'] as num).toDouble(),
      priceType: row['price_type'] as String? ?? 'fixed',
      durationMin: row['duration_min'] as int?,
      imageUrl: row['image_url'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      name: name,
      description: description,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  OfferingEntity toEntity() {
    return OfferingEntity(
      id: id,
      businessId: businessId,
      type: type,
      priceMxn: priceMxn,
      priceType: priceType,
      durationMin: durationMin,
      imageUrl: imageUrl,
      isActive: isActive,
      name: name,
      description: description,
      createdAt: createdAt,
    );
  }
}
