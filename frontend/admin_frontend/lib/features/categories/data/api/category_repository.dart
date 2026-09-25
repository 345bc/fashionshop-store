// GENERATED FROM TEMPLATE: templates/feature_repository.dart.template
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class CategoryRepository {
  final ApiClient _apiClient = ApiClient();

  Future<dynamic> getAll({
    int page = 0,
    int size = 15,
    String? query,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'size': size};
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final response = await _apiClient.get(
        ApiEndpoints.categories,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Fetch failed');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getById(int id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.categories}/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Fetch failed');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.categories, data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Create failed');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.categories}/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Update failed');
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Future<void> delete(int id) async {
  //   try {
  //     final response = await _apiClient.delete('${ApiEndpoints.categories}/$id');
  //     if (response.statusCode != 200 && response.statusCode != 204) {
  //       throw Exception('Delete failed');
  //     }
  //   } catch (e) {
  //     _handleError(e);
  //     rethrow;
  //   }
  // }

  void _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          // If the backend returns ApiResponse with a message field
          if (data.containsKey('message') && data['message'] != null) {
            throw Exception(data['message']);
          }
          // If the backend returns validation errors or standard Spring errors
          if (data.containsKey('error') && data['error'] != null) {
            throw Exception(data['error']);
          }
        }
      }
      // If no response body, throw the default Dio message
      throw Exception(e.message);
    }
  }
}
