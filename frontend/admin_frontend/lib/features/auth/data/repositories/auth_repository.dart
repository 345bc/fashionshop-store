import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      // Hỗ trợ cả 2 định dạng trả về từ backend: 
      // 1. Trực tiếp là User object
      // 2. Nằm trong Map { "user": {...}, "access_token": "..." }
      dynamic userJson = response.data['data'];
      if (userJson is Map<String, dynamic> && userJson.containsKey('user')) {
        userJson = userJson['user'];
      }

      // Lấy token từ header Set-Cookie trả về
      String? token;
      final setCookies = response.headers['set-cookie'];
      if (setCookies != null) {
        for (final cookie in setCookies) {
          if (cookie.startsWith('ACCESS_TOKEN=')) {
            // Dùng substring để tránh bị cắt mất dấu '=' trong JWT (base64 padding)
            final cookiePart = cookie.split(';').first;
            token = cookiePart.substring('ACCESS_TOKEN='.length);
            break;
          }
        }
      }

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
      }

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getProfile);
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('Không thể lấy thông tin người dùng');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  void _handleError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message') &&
            data['message'] != null &&
            data['message'].toString().isNotEmpty) {
          throw Exception(data['message']);
        }
        if (data.containsKey('error') &&
            data['error'] != null &&
            data['error'].toString().isNotEmpty) {
          throw Exception(data['error']);
        }
      } else if (data is String && data.isNotEmpty) {
        throw Exception(data);
      }
    }

    if (e.response?.statusCode == 401) {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác');
    } else if (e.response?.statusCode == 403) {
      throw Exception('Tài khoản đã bị khóa hoặc không có quyền');
    }

    throw Exception(e.message ?? 'Lỗi kết nối đến máy chủ');
  }
}
