import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<AuthEntity> call(String email, String password) {
    return repository.login(email, password);
  }
}
