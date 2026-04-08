class AppConstants {
  // API
  static const String baseUrl = 'https://api.conocemex.com/api/v1';
  static const String connectTimeout = '30000'; // ms
  static const String receiveTimeout = '30000'; // ms

  // Routes
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String splashRoute = '/';
  static const String signUpRoute = '/signup';
  static const String createBusinessRoute = '/business/create';
  static const String businessDetailRoute = '/business/detail';
  static const String createOfferingRoute = '/offering/create';

  // Biometric
  static const String biometricReason = 'Autentícate para acceder a Conocemex';

  // Assets
  static const String appLogoPath = 'assets/icon/conocemex.png';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String biometricEnabledKey = 'biometric_enabled';
}
