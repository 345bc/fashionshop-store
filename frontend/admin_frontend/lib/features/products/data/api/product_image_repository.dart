import 'package:dio/dio.dart';

import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ProductImageRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getByProductId(int productId) async {
    final response = await _apiClient.get(
      ApiEndpoints.productImages,
      queryParameters: {'productId': productId},
    );
    final images = response.data['data'] as List<dynamic>;
    return images.cast<Map<String, dynamic>>();
  }

  Future<void> create({
    required int productId,
    required String imageUrl,
    required bool isPrimary,
    required int displayOrder,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.productImages,
        data: {
          'productId': productId,
          'imageUrl': imageUrl,
          'isPrimary': isPrimary,
          'displayOrder': displayOrder,
        },
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null) throw Exception(message);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upload({
    required int productId,
    required String fileName,
    required Uint8List bytes,
    required bool isPrimary,
    required int displayOrder,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.productImageUpload,
        data: FormData.fromMap({
          'productId': productId,
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
          'isPrimary': isPrimary,
          'displayOrder': displayOrder,
        }),
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null) throw Exception(message);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update({
    required int id,
    required int productId,
    required String imageUrl,
    required bool isPrimary,
    required int displayOrder,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.productImages}/$id',
        data: {
          'productId': productId,
          'imageUrl': imageUrl,
          'isPrimary': isPrimary,
          'displayOrder': displayOrder,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null) throw Exception(message);
      }
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.productImages}/$id');
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null) throw Exception(message);
      }
      rethrow;
    }
  }
}
