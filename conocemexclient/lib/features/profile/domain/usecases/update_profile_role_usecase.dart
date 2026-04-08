import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileRoleUseCase {
  final ProfileRepository repository;

  UpdateProfileRoleUseCase(this.repository);

  Future<ProfileEntity?> call(String role) =>
      repository.updateProfileRole(role);
}
