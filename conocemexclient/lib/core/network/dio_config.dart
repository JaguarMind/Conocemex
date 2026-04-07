import 'package:dio/dio.dart';
import '/core/constants/app_constants.dart';

class DioConfig {
  static Dio createDio({String? token}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(
          milliseconds: int.parse(AppConstants.connectTimeout),
        ),
        receiveTimeout: Duration(
          milliseconds: int.parse(AppConstants.receiveTimeout),
        ),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // Interceptor para agregar token
    if (token != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            return handler.next(options);
          },
        ),
      );
    }

    // Interceptor para logging
    dio.interceptors.add(LoggingInterceptor());

    return dio;
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('>>> REQUEST[${options.method}] => PATH: ${options.path}');
    print('>>> HEADERS: ${options.headers}');
    if (options.data != null) {
      print('>>> BODY: ${options.data}');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
      '<<< RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    print('<<< BODY: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
      '<<< ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    print('<<< BODY: ${err.response?.data}');
    return super.onError(err, handler);
  }
}
