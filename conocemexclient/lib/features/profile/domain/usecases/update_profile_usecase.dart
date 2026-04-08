import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<ProfileEntity?> call(Map<String, dynamic> data) =>
      repository.updateProfile(data);
}
