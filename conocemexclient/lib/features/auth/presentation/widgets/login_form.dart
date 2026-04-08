import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/profile/domain/usecases/get_current_profile_usecase.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginForm extends StatefulWidget {
  final LoginViewModel viewModel;

  const LoginForm({super.key, required this.viewModel});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Colores del diseno Stitch
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await widget.viewModel.googleLogin();
      if (mounted) await _navigateAfterLogin();
    } catch (e) {
      _showError(widget.viewModel.error ?? 'Error al iniciar sesion con Google');
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.viewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) await _navigateAfterLogin();
    } catch (e) {
      _showError(widget.viewModel.error ?? 'Error al iniciar sesion');
    }
  }

  Future<void> _navigateAfterLogin() async {
    if (!mounted) return;
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONOCEMEX',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _darkBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () => AppRoutes.goToHome(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF476083),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // ─── Titulo ───
          const SizedBox(height: 32),
          const Text(
            'Welcome to\nMexico',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: _darkBlue,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),

          // ─── Boton Google ───
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: viewModel.isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: _darkBlue, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ─── Divider OR ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Row(
              children: [
                Expanded(child: Divider(color: _darkBlue.withValues(alpha: 0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _darkBlue.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: _darkBlue.withValues(alpha: 0.1))),
              ],
            ),
          ),

          // ─── Formulario Email/Password ───
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email label
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _darkBlue.withValues(alpha: 0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                  decoration: InputDecoration(
                    hintText: 'example@conocemex.com',
                    hintStyle: TextStyle(
                      color: _darkBlue.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: _bgGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El correo es requerido';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Ingresa un correo valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password label + forgot
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASSWORD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _darkBlue.withValues(alpha: 0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: forgot password
                        },
                        child: const Text(
                          'FORGOT?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _primaryGreen,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                      color: _darkBlue.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: _bgGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: _darkBlue.withValues(alpha: 0.4),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La contrasena es requerida';
                    if (v.length < 6) return 'Minimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login button
                Consumer<LoginViewModel>(
                  builder: (context, viewModel, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _handleEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: _darkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: _primaryGreen.withValues(alpha: 0.45),
                        ),
                        child: viewModel.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _darkBlue,
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ─── Error ───
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.error != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.error!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => viewModel.clearError(),
                          child: const Icon(Icons.close, color: Colors.red, size: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ─── Footer ───
          const SizedBox(height: 32),
          Center(
            child: Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(
                  color: const Color(0xFF476083),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppConstants.signUpRoute,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => AppRoutes.goToHome(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SKIP & CONTINUE AS GUEST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _darkBlue.withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: _darkBlue.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
