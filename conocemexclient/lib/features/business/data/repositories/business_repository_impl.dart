import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_remote_data_source.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource remoteDataSource;

  BusinessRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<BusinessEntity>> getMyBusinesses() async {
    final models = await remoteDataSource.getMyBusinesses();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BusinessEntity> createBusiness({
    required String name,
    required String categoryId,
    String? phone,
    String? address,
    required double latitude,
    required double longitude,
    String? coverImageUrl,
  }) async {
    final model = await remoteDataSource.createBusiness({
      'name': name,
      'category_id': categoryId,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
    });
    return model.toEntity();
  }
}
