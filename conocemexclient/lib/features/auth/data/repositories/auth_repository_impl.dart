import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/secure_storage_service.dart';
import '/features/auth/domain/entities/auth_entity.dart';
import '/features/auth/domain/entities/user_entity.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.supabaseClient,
    required this.storageService,
  });

  @override
  Future<AuthEntity> login(String email, String password) async {
    final response = await remoteDataSource.login(email, password);

    // Guardar tokens
    await storageService.saveToken(response.accessToken);
    await storageService.saveRefreshToken(response.refreshToken);

    // Guardar usuario
    final userJson = jsonEncode(response.user.toJson());
    await storageService.saveUser(userJson);

    return _mapToEntity(
      response.accessToken,
      response.refreshToken,
      response.user,
    );
  }

  @override
  Future<AuthEntity> googleLogin() async {
    final response = await remoteDataSource.googleLogin();

    // Guardar tokens
    await storageService.saveToken(response.accessToken);
    await storageService.saveRefreshToken(response.refreshToken);

    // Guardar usuario
    final userJson = jsonEncode(response.user.toJson());
    await storageService.saveUser(userJson);

    return _mapToEntity(
      response.accessToken,
      response.refreshToken,
      response.user,
    );
  }

  @override
  Future<AuthEntity> biometricLogin() async {
    final token = storageService.getToken();
    final userJson = storageService.getUser();

    if (token == null || userJson == null) {
      throw Exception('No hay credenciales biométricas guardadas');
    }

    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final userModel = UserModel.fromJson(userMap);
    final refreshToken = storageService.getRefreshToken() ?? '';

    return _mapToEntity(token, refreshToken, userModel);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await storageService.clearAll();
  }

  @override
  Future<AuthEntity?> refreshToken() async {
    final refreshToken = storageService.getRefreshToken();

    if (refreshToken == null) {
      return null;
    }

    final response = await remoteDataSource.refreshToken(refreshToken);

    if (response == null) {
      return null;
    }

    // Actualizar tokens
    await storageService.saveToken(response.accessToken);
    await storageService.saveRefreshToken(response.refreshToken);

    return _mapToEntity(
      response.accessToken,
      response.refreshToken,
      response.user,
    );
  }

  @override
  Stream<AuthEntity?> get authStateStream async* {
    final session = supabaseClient.auth.currentSession;
    if (session == null) {
      yield null;
      return;
    }

    yield _mapToEntity(
      session.accessToken,
      session.refreshToken ?? '',
      UserModel.fromSupabase(session.user),
    );
  }

  AuthEntity _mapToEntity(
    String accessToken,
    String refreshToken,
    UserModel user,
  ) {
    return AuthEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: UserEntity(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        profilePicture: user.profilePicture,
        createdAt: user.createdAt,
      ),
    );
  }
}
