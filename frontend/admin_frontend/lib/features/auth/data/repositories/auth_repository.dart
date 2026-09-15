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
        data: {
          'email': email,
          'password': password,
        },
      );

      // Backend ApiResponse<CurrentUser> format: { "data": { "id": 1, ... }, "message": "..." }
      final userJson = response.data['data'];

      // Lấy token từ header Set-Cookie trả về
      String? token;
      final setCookies = response.headers['set-cookie'];
      if (setCookies != null) {
        for (final cookie in setCookies) {
          if (cookie.startsWith('ACCESS_TOKEN=')) {
            token = cookie.split(';').first.split('=').last;
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
      final errorMessage = e.response?.data?['message'] ?? 'Lỗi kết nối đến máy chủ';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getProfile);
      return UserModel.fromJson(response.data['data']);
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
}
