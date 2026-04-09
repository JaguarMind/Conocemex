import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Servicio de traduccion usando DeepL API Free.
/// Cachea traducciones en memoria para no repetir llamadas.
class DeepLService {
  final String apiKey;
  final Dio _dio;

  // Cache: "text|targetLang" → traduccion
  final Map<String, String> _cache = {};

  static const _baseUrl = 'https://api-free.deepl.com/v2/translate';

  // Mapeo de codigos de idioma de la app a codigos DeepL
  static const _langMap = {
    'es': 'ES',
    'en': 'EN',
    'fr': 'FR',
    'pt': 'PT-BR',
  };

  DeepLService(this.apiKey)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  /// Traduce [text] al idioma [targetLangCode] (es, en, fr, pt).
  /// Si el texto ya esta en el idioma destino, lo retorna sin traducir.
  /// Cachea resultados para no repetir llamadas.
  Future<String> translate(String text, String targetLangCode) async {
    if (text.trim().isEmpty) return text;

    final deeplLang = _langMap[targetLangCode] ?? 'ES';
    final cacheKey = '$text|$deeplLang';

    // Revisar cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {'Authorization': 'DeepL-Auth-Key $apiKey'},
          contentType: Headers.jsonContentType,
        ),
        data: {
          'text': [text],
          'target_lang': deeplLang,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final translations = data['translations'] as List<dynamic>;

      if (translations.isNotEmpty) {
        final translated = translations[0]['text'] as String;
        _cache[cacheKey] = translated;
        return translated;
      }

      return text;
    } catch (e) {
      debugPrint('[DeepL] Translation error: $e');
      // Si falla la traduccion, retorna el texto original
      return text;
    }
  }

  /// Traduce multiples textos de una sola vez (mas eficiente).
  Future<List<String>> translateBatch(List<String> texts, String targetLangCode) async {
    if (texts.isEmpty) return texts;

    final deeplLang = _langMap[targetLangCode] ?? 'ES';
    final results = List<String>.from(texts);
    final toTranslate = <int, String>{}; // index → text (solo los no cacheados)

    for (var i = 0; i < texts.length; i++) {
      final cacheKey = '${texts[i]}|$deeplLang';
      if (_cache.containsKey(cacheKey)) {
        results[i] = _cache[cacheKey]!;
      } else if (texts[i].trim().isNotEmpty) {
        toTranslate[i] = texts[i];
      }
    }

    if (toTranslate.isEmpty) return results;

    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {'Authorization': 'DeepL-Auth-Key $apiKey'},
          contentType: Headers.jsonContentType,
        ),
        data: {
          'text': toTranslate.values.toList(),
          'target_lang': deeplLang,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final translations = data['translations'] as List<dynamic>;
      final indices = toTranslate.keys.toList();

      for (var i = 0; i < translations.length && i < indices.length; i++) {
        final translated = translations[i]['text'] as String;
        final idx = indices[i];
        results[idx] = translated;
        _cache['${texts[idx]}|$deeplLang'] = translated;
      }
    } catch (e) {
      debugPrint('[DeepL] Batch translation error: $e');
    }

    return results;
  }
}
