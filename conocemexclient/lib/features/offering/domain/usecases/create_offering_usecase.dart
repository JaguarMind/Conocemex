import '../entities/offering_entity.dart';
import '../repositories/offering_repository.dart';

class CreateOfferingUseCase {
  final OfferingRepository repository;

  CreateOfferingUseCase(this.repository);

  Future<OfferingEntity> call({
    required String businessId,
    required String type,
    required String name,
    String? description,
    required double priceMxn,
    String priceType = 'fixed',
    int? durationMin,
    String? imageUrl,
  }) =>
      repository.createOffering(
        businessId: businessId,
        type: type,
        name: name,
        description: description,
        priceMxn: priceMxn,
        priceType: priceType,
        durationMin: durationMin,
        imageUrl: imageUrl,
      );
}
