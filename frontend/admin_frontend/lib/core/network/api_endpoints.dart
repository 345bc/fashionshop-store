import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  // Lấy baseUrl từ file .env. Nếu không có, mặc định dùng localhost
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';

  // Auth Feature
  static const String login = '/auth/login';
  static const String getProfile = '/auth/me';
  static const String logout = '/auth/logout';
}
