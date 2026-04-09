import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/locale_service.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import '/features/profile/domain/usecases/update_profile_usecase.dart';
import '/l10n/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedNationality;
  String? _selectedLanguageId;
  String? _currentLanguageCode;
  bool _isLoading = false;

  List<Map<String, dynamic>> _languages = [];
  bool _loadingLanguages = true;

  static const _nationalities = [
    'Mexico', 'Estados Unidos', 'Canada', 'Francia', 'Espana',
    'Brasil', 'Portugal', 'Alemania', 'Reino Unido', 'Italia',
    'Japon', 'China', 'Colombia', 'Argentina', 'Chile', 'Peru', 'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
    _loadLanguages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadCurrentData() {
    final profile = getIt<DashboardViewModel>().profile;
    if (profile != null) {
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phone ?? '';
      _selectedNationality = profile.nationality;
    } else {
      // Fallback a datos de Google
      final metadata = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
      _nameController.text = metadata['full_name'] as String? ?? metadata['name'] as String? ?? '';
    }
  }

  Future<void> _loadLanguages() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Cargar idiomas disponibles
      final rows = await supabase
          .from('languages')
          .select('id, code, name_native, flag_emoji')
          .eq('is_active', true)
          .order('code');

      // Cargar idioma actual del usuario
      if (userId != null) {
        final prefRow = await supabase
            .from('profile_languages')
            .select('language_id, languages(code)')
            .eq('profile_id', userId)
            .eq('is_preferred', true)
            .maybeSingle();

        if (prefRow != null) {
          _selectedLanguageId = prefRow['language_id'] as String?;
          final lang = prefRow['languages'] as Map<String, dynamic>?;
          _currentLanguageCode = lang?['code'] as String?;
        }
      }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l = AppLocalizations.of(context)!;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Actualizar perfil
      await getIt<UpdateProfileUseCase>()({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'nationality': _selectedNationality,
      });

      // 2. Actualizar idioma preferido
      if (_selectedLanguageId != null) {
        await supabase.from('profile_languages').delete().eq('profile_id', userId);
        await supabase.from('profile_languages').insert({
          'profile_id': userId,
          'language_id': _selectedLanguageId,
          'is_preferred': true,
          'proficiency': 'native',
        });

        // Obtener el code del idioma seleccionado
        final selectedLang = _languages.firstWhere(
          (lang) => lang['id'] == _selectedLanguageId,
          orElse: () => {},
        );
        final newCode = selectedLang['code'] as String?;

        if (newCode != null && newCode != _currentLanguageCode) {
          await getIt<LocaleService>().setLocale(newCode);
        }
      }

      // 3. Recargar perfil en el dashboard
      await getIt<DashboardViewModel>().loadDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profileUpdated), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.errorUpdateProfile}: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.editProfile, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Nombre ───
              _buildLabel(l.fullNameLabel),
              _buildTextField(
                controller: _nameController,
                hint: l.fullNameHint,
                validator: (v) => (v == null || v.trim().isEmpty) ? l.nameRequired : null,
              ),
              const SizedBox(height: 20),

              // ─── Telefono ───
              _buildLabel(l.phoneLabel),
              _buildTextField(
                controller: _phoneController,
                hint: l.phoneHint,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // ─── Nacionalidad ───
              _buildLabel(l.nationalityLabel),
              DropdownButtonFormField<String>(
                value: _selectedNationality,
                decoration: _dropdownDecoration(l.nationalityHint),
                items: _nationalities
                    .map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedNationality = v),
              ),
              const SizedBox(height: 20),

              // ─── Idioma ───
              _buildLabel(l.appLanguage),
              _loadingLanguages
                  ? Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue.withValues(alpha: 0.3))),
                        const SizedBox(width: 12),
                        Text(l.loadingLanguages, style: TextStyle(color: _darkBlue.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                      ]),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedLanguageId,
                      decoration: _dropdownDecoration(l.languageHint),
                      items: _languages.map((lang) {
                        final flag = lang['flag_emoji'] as String? ?? '';
                        final name = lang['name_native'] as String? ?? '';
                        return DropdownMenuItem<String>(
                          value: lang['id'] as String,
                          child: Text('$flag  $name'.trim(), style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedLanguageId = v),
                    ),
              const SizedBox(height: 36),

              // ─── Guardar ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: _darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 8,
                    shadowColor: _primaryGreen.withValues(alpha: 0.45),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue))
                      : Text(l.saveChanges, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _darkBlue.withValues(alpha: 0.5), letterSpacing: 2)),
  );

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
        filled: true, fillColor: _bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: validator,
    );
  }

  InputDecoration _dropdownDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.3), fontWeight: FontWeight.w600),
    filled: true, fillColor: _bgGrey,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  );
}
