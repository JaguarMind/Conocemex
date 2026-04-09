import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que gestiona el idioma de la app.
/// Carga el idioma preferido del usuario desde profile_languages,
/// lo guarda en shared_preferences para acceso offline,
/// y notifica cambios para que la UI se actualice en caliente.
class LocaleService extends ChangeNotifier {
  static const _key = 'preferred_locale';
  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  /// Carga el idioma guardado localmente (rapido, para el startup)
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Carga el idioma preferido desde Supabase (profile_languages)
  /// y lo guarda localmente.
  Future<void> loadFromSupabase() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final row = await Supabase.instance.client
          .from('profile_languages')
          .select('language_id, languages(code)')
          .eq('profile_id', userId)
          .eq('is_preferred', true)
          .maybeSingle();

      if (row != null) {
        final lang = row['languages'] as Map<String, dynamic>?;
        final code = lang?['code'] as String?;
        if (code != null) {
          await setLocale(code);
        }
      }
    } catch (e) {
      debugPrint('[LocaleService] Error loading from Supabase: $e');
    }
  }

  /// Cambia el idioma activo y lo persiste.
  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }
}
