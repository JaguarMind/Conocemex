import 'package:flutter/material.dart';

import '/core/constants/app_constants.dart';
import '/features/auth/presentation/pages/home_page.dart';
import '/features/auth/presentation/pages/login_page.dart';
import '/features/auth/presentation/pages/splash_page.dart';

class AppRoutes {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.splashRoute:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
          settings: settings,
        );
      case AppConstants.loginRoute:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case AppConstants.homeRoute:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
          settings: settings,
        );
    }
  }

  static void goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppConstants.loginRoute, (route) => false);
  }

  static void goToHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
  }

  static void goToSplash(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppConstants.splashRoute, (route) => false);
  }
}
