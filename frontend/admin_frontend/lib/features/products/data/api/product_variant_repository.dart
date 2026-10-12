import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ProductVariantRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getAll({
    required int productId,
    int page = 0,
    int size = 15,
    String? query,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.productVariants,
        queryParameters: {
          'productId': productId,
          'page': page,
          'size': size,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.productVariants,
        data: data,
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> getById(int id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.productVariants}/$id',
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.productVariants}/$id',
        data: data,
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<List<Map<String, dynamic>>> getSizes() async {
    final response = await _apiClient.get(ApiEndpoints.sizes);
    return (response.data['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getColors() async {
    final items = <Map<String, dynamic>>[];
    var page = 0;
    while (true) {
      final response = await _apiClient.get(
        ApiEndpoints.colors,
        queryParameters: {'page': page, 'size': 100},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      items.addAll((data['content'] as List).cast<Map<String, dynamic>>());
      page++;
      if (page >= (data['totalPages'] as num).toInt()) break;
    }
    return items;
  }

  Never _throwMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      throw Exception(data['message'] ?? data['error'] ?? error.message);
    }
    throw error;
  }
}
