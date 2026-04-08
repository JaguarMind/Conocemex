import 'package:flutter/material.dart';

import '/core/extensions/exceptions.dart';
import '/core/services/biometric_service.dart';
import '/features/auth/domain/entities/auth_entity.dart';
import '/features/auth/domain/usecases/biometric_login_usecase.dart';
import '/features/auth/domain/usecases/google_login_usecase.dart';
import '/features/auth/domain/usecases/login_usecase.dart';
import '/features/auth/domain/usecases/logout_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUsecase loginUsecase;
  final GoogleLoginUsecase googleLoginUsecase;
  final BiometricLoginUsecase biometricLoginUsecase;
  final LogoutUsecase logoutUsecase;
  final BiometricService biometricService;

  AuthEntity? _auth;
  bool _isLoading = false;
  String? _error;
  bool _biometricAvailable = false;

  // Getters
  AuthEntity? get auth => _auth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get biometricAvailable => _biometricAvailable;
  bool get isAuthenticated => _auth != null;

  LoginViewModel({
    required this.loginUsecase,
    required this.googleLoginUsecase,
    required this.biometricLoginUsecase,
    required this.logoutUsecase,
    required this.biometricService,
  }) {
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    _biometricAvailable = await biometricService
        .canAuthenticateWithBiometrics();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _auth = await loginUsecase(email, password);
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      debugPrint('LoginViewModel.login AppException: ${e.runtimeType} - ${e.message}');
      _error = _toUserFriendlyMessage(e.message);
      notifyListeners();
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('LoginViewModel.login unexpected error: ${e.runtimeType} - $e');
      debugPrint(stackTrace.toString());
      _error = _toUserFriendlyMessage(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _auth = await googleLoginUsecase();
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      debugPrint('LoginViewModel.googleLogin AppException: ${e.runtimeType} - ${e.message}');
      _error = _toUserFriendlyMessage(e.message);
      notifyListeners();
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('LoginViewModel.googleLogin unexpected error: ${e.runtimeType} - $e');
      debugPrint(stackTrace.toString());
      _error = _toUserFriendlyMessage(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> biometricLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authenticated = await biometricService.authenticate(
        reason: 'Autentícate con huella dactilar o cara',
      );

      if (authenticated) {
        _auth = await biometricLoginUsecase();
        _error = null;
        notifyListeners();
      } else {
        _error = 'Autenticación biométrica cancelada';
        notifyListeners();
      }
    } on AppException catch (e) {
      debugPrint('LoginViewModel.biometricLogin AppException: ${e.runtimeType} - ${e.message}');
      _error = _toUserFriendlyMessage(e.message);
      notifyListeners();
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('LoginViewModel.biometricLogin unexpected error: ${e.runtimeType} - $e');
      debugPrint(stackTrace.toString());
      _error = _toUserFriendlyMessage(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await logoutUsecase();
      _auth = null;
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      debugPrint('LoginViewModel.logout AppException: ${e.runtimeType} - ${e.message}');
      _error = _toUserFriendlyMessage(e.message);
      notifyListeners();
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('LoginViewModel.logout unexpected error: ${e.runtimeType} - $e');
      debugPrint(stackTrace.toString());
      _error = _toUserFriendlyMessage(e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _toUserFriendlyMessage(String raw) {
    final message = raw.toLowerCase();

    if (message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('connection error') ||
        message.contains('network')) {
      return 'No se pudo conectar al servidor. Verifica tu internet e intenta de nuevo.';
    }

    if (message.contains('timeout')) {
      return 'La solicitud tardó demasiado. Intenta nuevamente.';
    }

    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('credenciales')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (message.contains('google') && message.contains('cancel')) {
      return 'Inicio de sesión con Google cancelado.';
    }

    if (message.contains('biometric') || message.contains('biometr')) {
      return 'No fue posible validar tu biometría. Intenta nuevamente.';
    }

    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
}
