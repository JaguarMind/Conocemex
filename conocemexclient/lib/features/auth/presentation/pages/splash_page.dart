import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/profile/domain/usecases/get_current_profile_usecase.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      AppRoutes.goToLogin(context);
      return;
    }

    // Verificar si completo el onboarding
    try {
      final profile = await getIt<GetCurrentProfileUseCase>()();
      if (!mounted) return;

      if (profile == null || !profile.onboardingCompleted) {
        AppRoutes.goToOnboarding(context);
      } else {
        AppRoutes.goToHome(context);
      }
    } catch (_) {
      if (mounted) AppRoutes.goToHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.appLogoPath,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'CONOCEMEX',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _darkBlue,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: _primaryGreen),
          ],
        ),
      ),
    );
  }
}
