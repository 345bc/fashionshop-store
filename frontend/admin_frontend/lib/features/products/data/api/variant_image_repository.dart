import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class VariantImageRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getByVariantId(int variantId) async {
    final response = await _apiClient.get(
      ApiEndpoints.variantImages,
      queryParameters: {'variantId': variantId},
    );
    return (response.data['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upload({
    required int variantId,
    required String fileName,
    required Uint8List bytes,
    required bool isPrimary,
    required int displayOrder,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.variantImageUpload,
        data: FormData.fromMap({
          'variantId': variantId,
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
          'isPrimary': isPrimary,
          'displayOrder': displayOrder,
        }),
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> update({
    required int id,
    required int variantId,
    required String imageUrl,
    required bool isPrimary,
    required int displayOrder,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.variantImages}/$id',
        data: {
          'variantId': variantId,
          'imageUrl': imageUrl,
          'isPrimary': isPrimary,
          'displayOrder': displayOrder,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.variantImages}/$id');
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Never _throwMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      throw Exception(data['message'] ?? data['error'] ?? error.message);
    }
    throw error;
  }
}
