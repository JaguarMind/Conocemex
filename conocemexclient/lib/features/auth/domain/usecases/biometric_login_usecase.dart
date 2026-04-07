import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class BiometricLoginUsecase {
  final AuthRepository repository;

  BiometricLoginUsecase(this.repository);

  Future<AuthEntity> call() {
    return repository.biometricLogin();
  }
}
