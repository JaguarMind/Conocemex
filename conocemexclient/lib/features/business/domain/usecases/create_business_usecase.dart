import '../entities/business_entity.dart';
import '../repositories/business_repository.dart';

class CreateBusinessUseCase {
  final BusinessRepository repository;

  CreateBusinessUseCase(this.repository);

  Future<BusinessEntity> call({
    required String name,
    required String categoryId,
    String? phone,
    String? address,
    required double latitude,
    required double longitude,
    String? coverImageUrl,
  }) =>
      repository.createBusiness(
        name: name,
        categoryId: categoryId,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        coverImageUrl: coverImageUrl,
      );
}
