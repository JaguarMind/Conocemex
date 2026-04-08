import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<List<BusinessEntity>> getMyBusinesses();
  Future<BusinessEntity> createBusiness({
    required String name,
    required String categoryId,
    String? phone,
    String? address,
    required double latitude,
    required double longitude,
    String? coverImageUrl,
  });
}
