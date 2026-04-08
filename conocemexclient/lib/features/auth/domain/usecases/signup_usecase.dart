import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUsecase {
  final AuthRepository repository;

  SignUpUsecase(this.repository);

  Future<AuthEntity> call(String email, String password, String fullName) =>
      repository.signUp(email, password, fullName);
}
