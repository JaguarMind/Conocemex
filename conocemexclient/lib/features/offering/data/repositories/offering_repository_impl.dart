import '../../domain/entities/offering_entity.dart';
import '../../domain/repositories/offering_repository.dart';
import '../datasources/offering_remote_data_source.dart';

class OfferingRepositoryImpl implements OfferingRepository {
  final OfferingRemoteDataSource remoteDataSource;

  OfferingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<OfferingEntity>> getOfferingsByBusiness(String businessId) async {
    final models = await remoteDataSource.getOfferingsByBusiness(businessId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<OfferingEntity> createOffering({
    required String businessId,
    required String type,
    required String name,
    String? description,
    required double priceMxn,
    String priceType = 'fixed',
    int? durationMin,
    String? imageUrl,
  }) async {
    final offeringData = {
      'business_id': businessId,
      'type': type,
      'price_mxn': priceMxn,
      'price_type': priceType,
      if (durationMin != null) 'duration_min': durationMin,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    final translationData = {
      'name': name,
      if (description != null) 'description': description,
    };

    final model = await remoteDataSource.createOffering(offeringData, translationData);
    return model.toEntity();
  }
}
