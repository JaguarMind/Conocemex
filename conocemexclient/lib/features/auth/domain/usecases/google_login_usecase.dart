import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUsecase {
  final AuthRepository repository;

  GoogleLoginUsecase(this.repository);

  Future<AuthEntity> call() {
    return repository.googleLogin();
  }
}
