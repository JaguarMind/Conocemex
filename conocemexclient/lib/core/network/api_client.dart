import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<Response<Map<String, dynamic>>> login(
    Map<String, dynamic> credentials,
  ) {
    return _dio.post<Map<String, dynamic>>('/auth/login', data: credentials);
  }

  Future<Response<Map<String, dynamic>>> googleLogin(
    Map<String, dynamic> googleToken,
  ) {
    return _dio.post<Map<String, dynamic>>('/auth/google', data: googleToken);
  }

  Future<Response<Map<String, dynamic>>> refreshToken(
    Map<String, dynamic> refreshTokenBody,
  ) {
    return _dio.post<Map<String, dynamic>>(
      '/auth/refresh-token',
      data: refreshTokenBody,
    );
  }

  Future<Response<Map<String, dynamic>>> logout({String? token}) {
    final options = Options(
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );

    return _dio.post<Map<String, dynamic>>('/auth/logout', options: options);
  }

  Future<Response<Map<String, dynamic>>> getCurrentUser({String? token}) {
    final options = Options(
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );

    return _dio.get<Map<String, dynamic>>('/users/me', options: options);
  }
}
