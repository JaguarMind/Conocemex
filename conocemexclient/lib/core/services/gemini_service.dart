import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Servicio de vision AI usando OpenRouter (modelos gratuitos).
/// Mantiene el nombre GeminiService para no romper imports existentes.
class GeminiService {
  final String _apiKey;
  final Dio _dio;

  // Modelo gratuito con vision en OpenRouter
  static const String _model = 'google/gemini-2.0-flash-001';

  GeminiService(this._apiKey)
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://openrouter.ai/api/v1',
          headers: {
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// Analiza imagen de un negocio y extrae informacion.
  Future<Map<String, dynamic>> analyzeBusinessImage(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final prompt = '''
Analiza esta imagen de un negocio o local comercial mexicano.
Extrae toda la informacion visible y responde SOLO con un JSON valido (sin markdown, sin backticks):

{
  "name": "nombre del negocio",
  "phone": "telefono si es visible o null",
  "address": "direccion si es visible o null",
  "category_slug": "una de estas opciones: gastronomia, artesanias, hospedaje, entretenimiento, transporte, tours, compras, bienestar",
  "description": "descripcion breve del negocio en espanol"
}

Reglas:
- Si no puedes determinar un campo, usa null
- category_slug DEBE ser uno de los valores listados
- Infiere la categoria por el tipo de negocio visible en la imagen
- La descripcion debe ser breve (1-2 oraciones)
- Responde SOLO el JSON, nada mas
''';

    return _sendRequest(prompt, base64Image);
  }

  /// Analiza imagen de un producto o servicio y extrae informacion.
  Future<Map<String, dynamic>> analyzeOfferingImage(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final prompt = '''
Analiza esta imagen de un producto o servicio de un negocio mexicano.
Extrae toda la informacion visible y responde SOLO con un JSON valido (sin markdown, sin backticks):

{
  "name": "nombre del producto o servicio",
  "description": "descripcion breve en espanol",
  "type": "product o service",
  "price_mxn": 0.0,
  "price_type": "una de estas opciones: fixed, from, hourly, per_person, quote"
}

Reglas:
- Si ves un precio visible, ponlo en price_mxn como numero
- Si no hay precio visible, usa 0 y price_type "quote"
- type debe ser "product" si es un objeto fisico, "service" si es algo que se presta
- price_type: "fixed" precio fijo, "from" desde, "hourly" por hora, "per_person" por persona, "quote" cotizar
- Responde SOLO el JSON, nada mas
''';

    return _sendRequest(prompt, base64Image);
  }

  Future<Map<String, dynamic>> _sendRequest(String prompt, String base64Image) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://conocemex.app',
            'X-Title': 'Conocemex',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
          'temperature': 0.1,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) return {};

      final message = choices[0]['message'] as Map<String, dynamic>;
      final text = message['content'] as String?;

      if (text == null) return {};

      return _parseJson(text);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] ?? e.message ?? 'Error de red';
      debugPrint('[VisionAI] DioException: $msg');
      throw Exception(msg);
    } catch (e) {
      debugPrint('[VisionAI] Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[VisionAI] Failed to parse JSON: $cleaned');
      return {};
    }
  }
}
