import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token != null && token.isNotEmpty) {
      // Backend (JwtCookieAuthenticationFilter) yêu cầu JWT Token nằm trong Cookie
      options.headers['Cookie'] = 'ACCESS_TOKEN=$token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Logic xử lý khi token hết hạn
    }
    super.onError(err, handler);
  }
}
