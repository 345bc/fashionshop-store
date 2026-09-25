import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';

  // Auth Feature
  static const String login = '/auth/login';
  static const String getProfile = '/auth/me';
  static const String logout = '/auth/logout';

  // Users Feature
  static const String users = '/user';

  // Products Feature
  static const String products = '/product';

  // Categories Feature
  static const String categories = '/category';
  
  // Suppliers Feature
  static const String suppliers = '/supplier';
  
  // Size Guides Feature
  static const String sizeGuides = '/sizeguide';
}
