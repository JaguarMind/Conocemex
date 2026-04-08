import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetCurrentProfileUseCase {
  final ProfileRepository repository;

  GetCurrentProfileUseCase(this.repository);

  Future<ProfileEntity?> call() => repository.getCurrentProfile();
}
