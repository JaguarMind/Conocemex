import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/constants/app_constants.dart';
import '/core/config/env.dart';
import '/core/routes/app_routes.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginForm extends StatefulWidget {
  final LoginViewModel viewModel;

  const LoginForm({super.key, required this.viewModel});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late FocusNode emailFocus;
  late FocusNode passwordFocus;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await widget.viewModel.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (mounted) {
        AppRoutes.goToHome(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.viewModel.error ?? 'Error al iniciar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await widget.viewModel.googleLogin();

      if (mounted) {
        AppRoutes.goToHome(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.viewModel.error ?? 'Error al iniciar sesión con Google',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      await widget.viewModel.biometricLogin();

      if (mounted) {
        AppRoutes.goToHome(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.viewModel.error ?? 'Error en autenticación biométrica',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Header
          const SizedBox(height: 40),
          Image.asset(
            AppConstants.appLogoPath,
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Bienvenido a Conocemex',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 32),

          // Email Field
          TextFormField(
            controller: emailController,
            focusNode: emailFocus,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              hintText: 'usuario@ejemplo.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'El correo es requerido';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              passwordFocus.requestFocus();
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'La contraseña es requerida';
              }
              if ((value?.length ?? 0) < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              _handleLogin();
            },
          ),
          const SizedBox(height: 24),

          // Error Message
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.error != null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),

          // Login Button
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              return ElevatedButton(
                onPressed: viewModel.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  viewModel.isLoading
                      ? 'Iniciando sesión...'
                      : 'Iniciar Sesión',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Google Login Button
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              final googleConfigured = Env.hasGoogleWebClientId;
              return OutlinedButton.icon(
                onPressed:
                    viewModel.isLoading || !googleConfigured
                        ? null
                        : _handleGoogleLogin,
                icon: const Icon(Icons.g_mobiledata),
                label: Text(
                  googleConfigured
                      ? 'Iniciar con Google'
                      : 'Google no configurado',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          if (!Env.hasGoogleWebClientId) ...[
            const SizedBox(height: 8),
            Text(
              'El login con Google se activará cuando configures GOOGLE_WEB_CLIENT_ID.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
            ),
          ],
          const SizedBox(height: 16),

          // Biometric Login Button
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              if (!viewModel.biometricAvailable) {
                return const SizedBox.shrink();
              }
              return OutlinedButton.icon(
                onPressed: viewModel.isLoading ? null : _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Iniciar con Biometría'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta? '),
              TextButton(
                onPressed: () {
                  // TODO: Navegar a registro
                },
                child: const Text(
                  'Regístrate aquí',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
