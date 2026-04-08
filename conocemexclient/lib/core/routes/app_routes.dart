import 'package:flutter/material.dart';

import '/core/constants/app_constants.dart';
import '/features/auth/presentation/pages/login_page.dart';
import '/features/auth/presentation/pages/main_shell_page.dart';
import '/features/auth/presentation/pages/signup_page.dart';
import '/features/auth/presentation/pages/splash_page.dart';
import '/features/profile/presentation/pages/onboarding_page.dart';
import '/features/business/domain/entities/business_entity.dart';
import '/features/business/presentation/pages/business_detail_page.dart';
import '/features/business/presentation/pages/create_business_page.dart';
import '/features/offering/presentation/pages/create_offering_page.dart';

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
      case AppConstants.signUpRoute:
        return MaterialPageRoute(
          builder: (_) => const SignUpPage(),
          settings: settings,
        );
      case AppConstants.onboardingRoute:
        return MaterialPageRoute(
          builder: (_) => const OnboardingPage(),
          settings: settings,
        );
      case AppConstants.homeRoute:
        return MaterialPageRoute(
          builder: (_) => const MainShellPage(),
          settings: settings,
        );
      case AppConstants.createBusinessRoute:
        return MaterialPageRoute(
          builder: (_) => const CreateBusinessPage(),
          settings: settings,
        );
      case AppConstants.businessDetailRoute:
        final business = settings.arguments as BusinessEntity;
        return MaterialPageRoute(
          builder: (_) => BusinessDetailPage(business: business),
          settings: settings,
        );
      case AppConstants.createOfferingRoute:
        final businessId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CreateOfferingPage(businessId: businessId),
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

  static void goToOnboarding(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppConstants.onboardingRoute, (route) => false);
  }

  static void goToBusinessDetail(BuildContext context, BusinessEntity business) {
    Navigator.of(context).pushNamed(
      AppConstants.businessDetailRoute,
      arguments: business,
    );
  }
}
