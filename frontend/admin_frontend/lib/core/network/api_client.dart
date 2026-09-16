import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'api_interceptors.dart';

class ApiClientError implements Exception {
  final String message;
  final int? status;
  final String? code;
  final List<dynamic> details;
  final bool isUnauthorized;
  final bool isForbidden;

  ApiClientError({
    required this.message,
    this.status,
    this.code,
    this.details = const [],
  }) : isUnauthorized = status == 401,
       isForbidden = status == 403;

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio dio;

  // Pattern Singleton để gọi ApiClient ở bất kỳ đâu
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  String? _csrfToken;
  String? _csrfHeaderName;

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
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Thêm CSRF token cho các method không an toàn (POST, PUT, DELETE, PATCH)
          final method = options.method.toUpperCase();
          if (!['GET', 'HEAD', 'OPTIONS'].contains(method)) {
            try {
              await _ensureCsrfToken();
              if (_csrfHeaderName != null && _csrfToken != null) {
                options.headers[_csrfHeaderName!] = _csrfToken!;

                // Spring Security yêu cầu CẢ header X-XSRF-TOKEN VÀ cookie XSRF-TOKEN phải khớp nhau.
                // Do Desktop app không tự quản lý Cookie, ta phải nhét thêm XSRF-TOKEN vào header Cookie.
                final currentCookie = options.headers['Cookie'] as String? ?? '';
                options.headers['Cookie'] = currentCookie.isEmpty
                    ? 'XSRF-TOKEN=$_csrfToken'
                    : '$currentCookie; XSRF-TOKEN=$_csrfToken';
              }
            } catch (e) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: e,
                  message: 'Không thể khởi tạo phiên bảo mật (CSRF)',
                ),
              );
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Cập nhật CSRF token từ mỗi response.
          // Server có thể rotate token sau mỗi request → phải luôn lấy token mới nhất.
          _updateCsrfFromResponseCookies(response.headers['set-cookie']);
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response != null) {
            _updateCsrfFromResponseCookies(e.response!.headers['set-cookie']);
          }
          if (e.response?.statusCode == 401) {
            clearCsrfToken();
          }
          return handler.next(e);
        },
      ),
      // LogInterceptor giúp bạn xem log request/response ở màn hình console (chỉ bật lúc dev)
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Future<void> _ensureCsrfToken() async {
    if (_csrfToken != null && _csrfHeaderName != null) return;

    try {
      final csrfDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {'Accept': 'application/json'},
        ),
      );

      final response = await csrfDio.get('/auth/csrf');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null &&
            data['headerName'] != null &&
            data['token'] != null) {
          _csrfHeaderName = data['headerName'];
          _csrfToken = data['token'];
        }
      }
    } catch (e) {
      print('Lỗi khởi tạo CSRF Token: $e');
      rethrow;
    }
  }

  void clearCsrfToken() {
    _csrfToken = null;
    _csrfHeaderName = null;
  }

  /// Parse XSRF-TOKEN từ danh sách Set-Cookie header của response.
  /// Gọi sau mỗi request để đảm bảo luôn dùng token mới nhất từ server.
  void _updateCsrfFromResponseCookies(List<String>? setCookies) {
    if (setCookies == null) return;
    for (final cookie in setCookies) {
      if (cookie.startsWith('XSRF-TOKEN=')) {
        final value = cookie.split(';').first.substring('XSRF-TOKEN='.length);
        if (value.isNotEmpty) {
          _csrfToken = value;
          _csrfHeaderName ??= 'X-XSRF-TOKEN'; // mặc định header name của Spring
        }
        break;
      }
    }
  }

  // Các hàm tiện ích
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    return await dio.put(path, data: data, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    return await dio.delete(path, data: data, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return await dio.patch(path, data: data, options: options);
  }

  // Tải tệp (thay thế cho apiDownload)
  Future<List<int>> downloadBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? <int>[];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        clearCsrfToken();
      }
      throw ApiClientError(
        message: e.response?.statusCode == 401
            ? "Phiên đăng nhập đã hết hạn"
            : e.response?.statusCode == 403
            ? "Bạn không có quyền tải tệp này"
            : "Không thể tải tệp",
        status: e.response?.statusCode,
        code: e.response?.statusCode == 401
            ? "AUTHENTICATION_REQUIRED"
            : e.response?.statusCode == 403
            ? "ACCESS_DENIED"
            : "DOWNLOAD_FAILED",
      );
    }
  }
}
