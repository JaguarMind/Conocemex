import '../entities/offering_entity.dart';

abstract class OfferingRepository {
  Future<List<OfferingEntity>> getOfferingsByBusiness(String businessId);
  Future<OfferingEntity> createOffering({
    required String businessId,
    required String type,
    required String name,
    String? description,
    required double priceMxn,
    String priceType,
    int? durationMin,
    String? imageUrl,
  });
}
