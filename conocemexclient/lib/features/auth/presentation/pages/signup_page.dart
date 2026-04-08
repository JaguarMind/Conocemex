import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '../viewmodels/login_viewmodel.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return SafeArea(child: _SignUpForm(viewModel: viewModel));
        },
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  final LoginViewModel viewModel;
  const _SignUpForm({required this.viewModel});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.viewModel.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) AppRoutes.goToOnboarding(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.viewModel.error ?? 'Error al registrarse'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      await widget.viewModel.googleLogin();
      if (mounted) AppRoutes.goToOnboarding(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.viewModel.error ?? 'Error con Google'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: _darkBlue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'CONOCEMEX',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _darkBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ─── Titulo ───
          const SizedBox(height: 28),
          const Text(
            'Create your\naccount',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: _darkBlue,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registrate como vendedor para dar a conocer tu negocio.',
            style: TextStyle(
              fontSize: 15,
              color: _darkBlue.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          // ─── Google Sign Up ───
          Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: viewModel.isLoading ? null : _handleGoogleSignUp,
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
                        'Sign up with Google',
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

          // ─── Divider ───
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(
                    child: Divider(color: _darkBlue.withValues(alpha: 0.1))),
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
                Expanded(
                    child: Divider(color: _darkBlue.withValues(alpha: 0.1))),
              ],
            ),
          ),

          // ─── Formulario ───
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('FULL NAME'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Juan Perez',
                  keyboardType: TextInputType.name,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es requerido'
                      : null,
                ),
                const SizedBox(height: 18),

                _buildLabel('EMAIL'),
                _buildTextField(
                  controller: _emailController,
                  hint: 'vendedor@correo.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El correo es requerido';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Correo invalido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                _buildLabel('PASSWORD'),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Minimo 6 caracteres',
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _darkBlue.withValues(alpha: 0.4),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Contrasena requerida';
                    if (v.length < 6) return 'Minimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                _buildLabel('CONFIRM PASSWORD'),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: 'Repite tu contrasena',
                  obscure: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _darkBlue.withValues(alpha: 0.4),
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contrasena';
                    if (v != _passwordController.text) {
                      return 'Las contrasenas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ─── Sign Up button ───
                Consumer<LoginViewModel>(
                  builder: (context, viewModel, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _handleSignUp,
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
                                'Sign Up',
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
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => viewModel.clearError(),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 18),
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
          const SizedBox(height: 24),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  color: const Color(0xFF476083),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Log In',
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: _darkBlue.withValues(alpha: 0.5),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue),
      decoration: InputDecoration(
        hintText: hint,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
