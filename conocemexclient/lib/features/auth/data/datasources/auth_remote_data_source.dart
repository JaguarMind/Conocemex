import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/config/env.dart';
import '/core/extensions/exceptions.dart' as app_ex;
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> googleLogin();
  Future<AuthResponseModel?> refreshToken(String refreshToken);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session == null) {
        throw app_ex.AuthException('No se pudo obtener una sesión válida');
      }

      return AuthResponseModel.fromSupabase(session);
    } on DioException catch (e) {
      debugPrint(
        'AuthRemoteDataSource.login DioException: ${e.runtimeType} - ${e.message}',
      );
      debugPrint(e.toString());
      throw app_ex.NetworkException(_mapDioError(e));
    } catch (error, stackTrace) {
      debugPrint(
        'AuthRemoteDataSource.login unexpected error: ${error.runtimeType} - $error',
      );
      debugPrint(stackTrace.toString());
      final message = error.toString().toLowerCase();
      if (message.contains('auth') && message.contains('exception')) {
        throw app_ex.AuthException(_mapSupabaseError(error.toString()));
      }
      throw app_ex.UnknownException('No fue posible iniciar sesión.');
    }
  }

  @override
  Future<AuthResponseModel> googleLogin() async {
    try {
      if (!Env.hasGoogleWebClientId) {
        throw app_ex.ValidationException(
          'Google no está configurado todavía. Falta el Client ID web.',
        );
      }

      final googleSignIn = GoogleSignIn(
        clientId: Env.googleIosClientId.isEmpty ? null : Env.googleIosClientId,
        serverClientId: Env.googleWebClientId.isEmpty
            ? null
            : Env.googleWebClientId,
      );
      final account = await googleSignIn.signIn();

      if (account == null) {
        throw app_ex.AuthException('Inicio de sesión con Google cancelado');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw app_ex.AuthException('No se pudo obtener el token de Google');
      }

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authentication.accessToken,
      );

      final session = response.session;
      if (session == null) {
        throw app_ex.AuthException('No se pudo obtener una sesión válida');
      }

      return AuthResponseModel.fromSupabase(session);
    } on DioException catch (e) {
      debugPrint(
        'AuthRemoteDataSource.googleLogin DioException: ${e.runtimeType} - ${e.message}',
      );
      debugPrint(e.toString());
      throw app_ex.NetworkException(_mapDioError(e));
    } catch (error, stackTrace) {
      debugPrint(
        'AuthRemoteDataSource.googleLogin unexpected error: ${error.runtimeType} - $error',
      );
      debugPrint(stackTrace.toString());
      final message = error.toString().toLowerCase();
      if (message.contains('auth') && message.contains('exception')) {
        throw app_ex.AuthException(_mapSupabaseError(error.toString()));
      }
      throw app_ex.AuthException('No fue posible iniciar sesión con Google');
    }
  }

  @override
  Future<AuthResponseModel?> refreshToken(String refreshToken) async {
    try {
      if (refreshToken.isEmpty) {
        return null;
      }

      final response = await supabaseClient.auth.refreshSession();
      final session = response.session;
      if (session == null) {
        return null;
      }

      return AuthResponseModel.fromSupabase(session);
    } on DioException catch (e) {
      debugPrint(
        'AuthRemoteDataSource.refreshToken DioException: ${e.runtimeType} - ${e.message}',
      );
      debugPrint(e.toString());
      throw app_ex.NetworkException(_mapDioError(e));
    } catch (error, stackTrace) {
      debugPrint(
        'AuthRemoteDataSource.refreshToken unexpected error: ${error.runtimeType} - $error',
      );
      debugPrint(stackTrace.toString());
      throw app_ex.UnknownException('No fue posible renovar la sesión.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } on DioException catch (e) {
      debugPrint(
        'AuthRemoteDataSource.logout DioException: ${e.runtimeType} - ${e.message}',
      );
      debugPrint(e.toString());
      throw app_ex.NetworkException(_mapDioError(e));
    } catch (error, stackTrace) {
      debugPrint(
        'AuthRemoteDataSource.logout unexpected error: ${error.runtimeType} - $error',
      );
      debugPrint(stackTrace.toString());
      throw app_ex.UnknownException('No fue posible cerrar sesión.');
    }
  }

  String _mapSupabaseError(String message) {
    final lowered = message.toLowerCase();
    if (lowered.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lowered.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }
    if (lowered.contains('user already registered')) {
      return 'Este correo ya está registrado.';
    }
    return 'No fue posible completar la autenticación.';
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'La solicitud tardó demasiado. Intenta nuevamente.';
      case DioExceptionType.connectionError:
        return 'Sin conexión a internet o servidor no disponible.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'Credenciales inválidas.';
        if (code == 403) return 'No tienes permisos para esta acción.';
        if (code == 404) return 'Servicio no encontrado.';
        if (code != null && code >= 500) return 'Error interno del servidor.';
        return 'Respuesta inválida del servidor.';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada.';
      case DioExceptionType.unknown:
        return 'Error de conexión.';
      case DioExceptionType.badCertificate:
        return 'Certificado de seguridad inválido.';
    }
  }
}
