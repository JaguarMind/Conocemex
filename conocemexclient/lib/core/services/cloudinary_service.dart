import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum CloudinaryFolder { avatars, businesses, offerings }

enum ThumbSize { card, detail, avatar }

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;
  final Dio _dio;

  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// Sube bytes de imagen a Cloudinary y devuelve la secure_url.
  Future<String> uploadImage(
    Uint8List bytes, {
    CloudinaryFolder folder = CloudinaryFolder.businesses,
    String filename = 'image.jpg',
  }) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('La imagen no puede pesar mas de 5 MB');
    }

    final folderName = folder.name;
    final uri = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'upload_preset': uploadPreset,
      'folder': 'conocemex/$folderName',
    });

    try {
      final response = await _dio.post(uri, data: formData);
      final data = response.data as Map<String, dynamic>;
      return data['secure_url'] as String;
    } on DioException catch (e) {
      debugPrint('[Cloudinary] Upload error: ${e.response?.data}');
      throw Exception('Error al subir imagen: ${e.message}');
    }
  }

  /// Genera URL transformada para el tamano correcto.
  static String thumb(String url, {ThumbSize size = ThumbSize.card}) {
    const transforms = {
      ThumbSize.card: 'c_fill,g_auto,w_400,h_300,q_auto,f_auto',
      ThumbSize.detail: 'c_fill,g_auto,w_800,h_600,q_auto,f_auto',
      ThumbSize.avatar: 'c_fill,g_face,w_120,h_120,r_max,q_auto,f_auto',
    };
    return url.replaceFirst('/upload/', '/upload/${transforms[size]}/');
  }
}
