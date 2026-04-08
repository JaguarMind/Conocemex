import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> signUp(String email, String password, String fullName);
  Future<AuthResponseModel> googleLogin();
  Future<void> logout();
  Future<AuthResponseModel?> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  static const String _webClientId =
      '720755602382-u0v5np2g0b0ot0iue3sbkm3p6l2dedjf.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile', 'openid'],
  );

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = response.session;
    if (session == null) {
      throw Exception('No se obtuvo sesion del login');
    }

    return AuthResponseModel.fromSupabase(session);
  }

  @override
  Future<AuthResponseModel> signUp(String email, String password, String fullName) async {
    final response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final session = response.session;
    if (session == null) {
      throw Exception('Registro exitoso. Revisa tu correo para confirmar la cuenta.');
    }

    // Actualizar el perfil con el nombre y rol microempresario
    await supabaseClient.from('profiles').update({
      'full_name': fullName,
      'role': 'microempresario',
    }).eq('id', response.user!.id);

    return AuthResponseModel.fromSupabase(session);
  }

  @override
  Future<AuthResponseModel> googleLogin() async {
    debugPrint('[GoogleLogin] === INICIO ===');
    debugPrint('[GoogleLogin] serverClientId: $_webClientId');

    try {
      debugPrint('[GoogleLogin] Paso 1: signOut() previo...');
      await _googleSignIn.signOut();
      debugPrint('[GoogleLogin] signOut() OK');

      debugPrint('[GoogleLogin] Paso 2: signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[GoogleLogin] Usuario cancelo el flujo');
        throw Exception('Login cancelado por el usuario');
      }

      debugPrint('[GoogleLogin] Cuenta seleccionada: ${googleUser.email}');

      debugPrint('[GoogleLogin] Paso 3: obteniendo tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      debugPrint('[GoogleLogin] accessToken: ${accessToken != null ? "OK" : "NULL"}');
      debugPrint('[GoogleLogin] idToken: ${idToken != null ? "OK" : "NULL"}');

      if (idToken == null) {
        debugPrint('[GoogleLogin] idToken es NULL - serverClientId debe ser WEB Client ID');
        throw Exception('No se obtuvo idToken de Google');
      }

      debugPrint('[GoogleLogin] Paso 4: enviando a Supabase...');
      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final session = response.session;
      if (session == null) {
        throw Exception('No se obtuvo sesion de Supabase tras Google login');
      }

      debugPrint('[GoogleLogin] Supabase OK - user: ${response.user?.email}');
      return AuthResponseModel.fromSupabase(session);
    } on PlatformException catch (e, st) {
      debugPrint('[GoogleLogin] PlatformException: ${e.code} - ${e.message}');
      debugPrint('[GoogleLogin] details: ${e.details}');
      debugPrint('[GoogleLogin] stack: $st');

      if (e.message?.contains('ApiException: 10') ?? false) {
        debugPrint('[GoogleLogin] ApiException 10 = DEVELOPER_ERROR - SHA-1 o package name mal');
      } else if (e.message?.contains('ApiException: 7') ?? false) {
        debugPrint('[GoogleLogin] ApiException 7 = NETWORK_ERROR - posibles causas:');
        debugPrint('  1) serverClientId no es el WEB Client ID');
        debugPrint('  2) Cuenta no esta en Test Users del OAuth Consent Screen');
        debugPrint('  3) Google Play Services desactualizado');
      }
      rethrow;
    } catch (e, st) {
      debugPrint('[GoogleLogin] Error inesperado: $e');
      debugPrint('[GoogleLogin] stack: $st');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await supabaseClient.auth.signOut();
  }

  @override
  Future<AuthResponseModel?> refreshToken(String refreshToken) async {
    final response = await supabaseClient.auth.refreshSession();

    final session = response.session;
    if (session == null) {
      return null;
    }

    return AuthResponseModel.fromSupabase(session);
  }
}
