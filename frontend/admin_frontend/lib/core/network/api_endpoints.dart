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
  static const String productImages = '/product-image';
  static const String productImageUpload = '/product-image/upload';
  static const String productVariants = '/product-variant';
  static const String variantImages = '/variant-image';
  static const String variantImageUpload = '/variant-image/upload';
  static const String sizes = '/size';
  static const String colors = '/color';

  // Categories Feature
  static const String categories = '/category';

  // Suppliers Feature
  static const String suppliers = '/supplier';
  static const String customers = '/customers';
  static const String inventory = '/inventory';
  static const String orders = '/order';
  static const String orderReturns = '/order-return';
  static const String goodsReceipts = '/goods-receipt';

  // Size Guides Feature
  static const String sizeGuides = '/sizeguide';
}
