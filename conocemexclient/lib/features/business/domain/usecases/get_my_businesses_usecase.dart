import '../entities/business_entity.dart';
import '../repositories/business_repository.dart';

class GetMyBusinessesUseCase {
  final BusinessRepository repository;

  GetMyBusinessesUseCase(this.repository);

  Future<List<BusinessEntity>> call() => repository.getMyBusinesses();
}
