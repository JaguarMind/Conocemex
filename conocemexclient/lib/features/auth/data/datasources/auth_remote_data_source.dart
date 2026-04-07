import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '/core/extensions/exceptions.dart';
import '/core/network/api_client.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> googleLogin();
  Future<AuthResponseModel> refreshToken(String refreshToken);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await apiClient.login({
        'email': email,
        'password': password,
      });
      final data = response.data;
      if (data == null) {
        throw UnknownException('Respuesta vacia en login');
      }
      return AuthResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw NetworkException(_mapDioError(e));
    } catch (e) {
      throw UnknownException('Error desconocido: $e');
    }
  }

  @override
  Future<AuthResponseModel> googleLogin() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();

      if (account == null) {
        throw AuthException('Inicio de sesión con Google cancelado');
      }

      final auth = await account.authentication;
      final response = await apiClient.googleLogin({
        'token': auth.idToken ?? '',
      });
      final data = response.data;
      if (data == null) {
        throw UnknownException('Respuesta vacia en login con Google');
      }
      return AuthResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw NetworkException(_mapDioError(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('No fue posible iniciar sesión con Google');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.refreshToken({
        'refresh_token': refreshToken,
      });
      final data = response.data;
      if (data == null) {
        throw UnknownException('Respuesta vacia en refresh token');
      }
      return AuthResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw NetworkException(_mapDioError(e));
    } catch (e) {
      throw UnknownException('Error desconocido: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.logout();
    } on DioException catch (e) {
      throw NetworkException(_mapDioError(e));
    } catch (e) {
      throw UnknownException('Error desconocido: $e');
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Tiempo de espera agotado';
      case DioExceptionType.connectionError:
        return 'Sin conexión a internet o servidor no disponible';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'Credenciales inválidas';
        if (code == 403) return 'No tienes permisos para esta acción';
        if (code == 404) return 'Servicio no encontrado';
        if (code != null && code >= 500) return 'Error interno del servidor';
        return 'Respuesta inválida del servidor';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      case DioExceptionType.unknown:
        return 'Error de conexión';
      case DioExceptionType.badCertificate:
        return 'Certificado de seguridad inválido';
    }
  }
}
