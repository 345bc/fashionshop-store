import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');
    final String? refresh = prefs.getString('refresh_token');

    final cookies = [
      if (token != null && token.isNotEmpty) 'ACCESS_TOKEN=$token',
      if (refresh != null && refresh.isNotEmpty) 'REFRESH_TOKEN=$refresh',
    ];
    if (cookies.isNotEmpty) options.headers['Cookie'] = cookies.join('; ');

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
