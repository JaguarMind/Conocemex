import '../entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity> login(String email, String password);
  Future<AuthEntity> googleLogin();
  Future<AuthEntity> biometricLogin();
  Future<void> logout();
  Future<AuthEntity?> refreshToken();
  Stream<AuthEntity?> get authStateStream;
}
