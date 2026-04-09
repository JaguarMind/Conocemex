import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String get googleAndroidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');

  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static String get geminiApiKey =>
      dotenv.env['OPENROUTER_API_KEY'] ??
      dotenv.env['GEMINI_API_KEY'] ??
      const String.fromEnvironment('OPENROUTER_API_KEY');

  static bool get hasGeminiApiKey =>
      geminiApiKey.isNotEmpty;

  static String get deeplApiKey =>
      dotenv.env['DEEPL_API_KEY'] ??
      const String.fromEnvironment('DEEPL_API_KEY');

  static bool get hasDeeplApiKey => deeplApiKey.isNotEmpty;

  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dmcrt5aoi';

  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'conocemex_unsigned';

    static bool get hasGoogleWebClientId =>
      googleWebClientId.isNotEmpty && !googleWebClientId.startsWith('your_');

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback to dart-define when .env is not available.
    }
  }

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan variables de entorno de Supabase. '
        'Define SUPABASE_URL y SUPABASE_ANON_KEY con --dart-define.',
      );
    }

  }
}
