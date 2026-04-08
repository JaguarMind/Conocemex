import '../entities/offering_entity.dart';
import '../repositories/offering_repository.dart';

class GetOfferingsUseCase {
  final OfferingRepository repository;

  GetOfferingsUseCase(this.repository);

  Future<List<OfferingEntity>> call(String businessId) =>
      repository.getOfferingsByBusiness(businessId);
}
