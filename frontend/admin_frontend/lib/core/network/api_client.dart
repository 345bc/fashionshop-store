import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'api_interceptors.dart';

class ApiClient {
  late final Dio dio;

  // Pattern Singleton để gọi ApiClient ở bất kỳ đâu
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Đăng ký các Interceptors
    dio.interceptors.addAll([
      AuthInterceptor(),
      // LogInterceptor giúp bạn xem log request/response ở màn hình console (chỉ bật lúc dev)
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);
  }

  // Các hàm tiện ích
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}
