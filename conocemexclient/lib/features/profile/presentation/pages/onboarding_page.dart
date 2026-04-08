import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/profile/domain/usecases/update_profile_usecase.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedNationality;
  String? _selectedLanguageId;
  bool _isLoading = false;

  // Idiomas cargados de Supabase
  List<Map<String, dynamic>> _languages = [];
  bool _loadingLanguages = true;

  static const _nationalities = [
    'Mexico',
    'Estados Unidos',
    'Canada',
    'Francia',
    'Espana',
    'Brasil',
    'Portugal',
    'Alemania',
    'Reino Unido',
    'Italia',
    'Japon',
    'China',
    'Colombia',
    'Argentina',
    'Chile',
    'Peru',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    try {
      final rows = await Supabase.instance.client
          .from('languages')
          .select('id, code, name_native, flag_emoji')
          .eq('is_active', true)
          .order('code');

      if (mounted) {
        setState(() {
          _languages = List<Map<String, dynamic>>.from(rows);
          _loadingLanguages = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingLanguages = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Actualizar perfil
      final updateProfile = getIt<UpdateProfileUseCase>();
      await updateProfile({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'nationality': _selectedNationality,
        'role': 'microempresario',
        'onboarding_completed': true,
      });

      // 2. Insertar idioma preferido en profile_languages
      if (_selectedLanguageId != null) {
        // Borrar idiomas previos por si acaso
        await supabase
            .from('profile_languages')
            .delete()
            .eq('profile_id', userId);

        await supabase.from('profile_languages').insert({
          'profile_id': userId,
          'language_id': _selectedLanguageId,
          'is_preferred': true,
          'proficiency': 'native',
        });
      }

      if (mounted) AppRoutes.goToHome(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'CONOCEMEX',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _darkBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Completa tu\nperfil',
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
                  'Necesitamos algunos datos para personalizar tu experiencia como vendedor.',
                  style: TextStyle(
                    fontSize: 15,
                    color: _darkBlue.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Nombre ───
                _buildLabel('NOMBRE COMPLETO'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Juan Perez',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Tu nombre es requerido' : null,
                ),
                const SizedBox(height: 20),

                // ─── Telefono ───
                _buildLabel('TELEFONO'),
                _buildTextField(
                  controller: _phoneController,
                  hint: '+52 55 1234 5678',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // ─── Nacionalidad ───
                _buildLabel('NACIONALIDAD'),
                DropdownButtonFormField<String>(
                  value: _selectedNationality,
                  decoration: _dropdownDecoration('Selecciona tu pais'),
                  items: _nationalities
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedNationality = v),
                  validator: (v) => v == null ? 'Selecciona tu nacionalidad' : null,
                ),
                const SizedBox(height: 20),

                // ─── Idioma (desde Supabase) ───
                _buildLabel('IDIOMA DE PREFERENCIA'),
                _loadingLanguages
                    ? Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _bgGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 16, width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _darkBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cargando idiomas...',
                              style: TextStyle(
                                color: _darkBlue.withValues(alpha: 0.3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedLanguageId,
                        decoration: _dropdownDecoration('Selecciona tu idioma'),
                        items: _languages.map((lang) {
                          final flag = lang['flag_emoji'] as String? ?? '';
                          final name = lang['name_native'] as String? ?? '';
                          return DropdownMenuItem<String>(
                            value: lang['id'] as String,
                            child: Text(
                              '$flag  $name'.trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _darkBlue,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedLanguageId = v),
                        validator: (v) => v == null ? 'Selecciona un idioma' : null,
                      ),
                const SizedBox(height: 32),

                // ─── Boton ───
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                    child: _isLoading
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue),
                          )
                        : const Text(
                            'Continuar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => AppRoutes.goToHome(context),
                    child: Text(
                      'Completar despues',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _darkBlue.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.3), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: _bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: validator,
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.3), fontWeight: FontWeight.w600),
      filled: true,
      fillColor: _bgGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
