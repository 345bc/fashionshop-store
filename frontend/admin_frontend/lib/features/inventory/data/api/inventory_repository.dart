import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/inventory_response_model.dart';

Future<T> warehouseRequest<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    final body = e.response?.data;
    throw ApiClientError(
      message: body is Map
          ? body['message']?.toString() ?? 'Không thể thực hiện thao tác'
          : 'Không kết nối được máy chủ',
      status: e.response?.statusCode,
    );
  }
}

class InventoryRepository {
  final _api = ApiClient();
  Future<List<InventoryResponseModel>> getAll({int? supplierId}) =>
      warehouseRequest(() async {
        final response = await _api.get(
          ApiEndpoints.inventory,
          queryParameters: {'supplierId': ?supplierId},
        );
        return (response.data['data'] as List)
            .map((j) => InventoryResponseModel(j as Map<String, dynamic>))
            .toList();
      });
  Future<List<Map<String, dynamic>>> history(int id) =>
      warehouseRequest(() async {
        final response = await _api.get(
          '${ApiEndpoints.inventory}/$id/movements',
        );
        return (response.data['data'] as List).cast<Map<String, dynamic>>();
      });
  Future<void> adjust(Map<String, dynamic> data) => warehouseRequest(() async {
    await _api.post('${ApiEndpoints.inventory}/adjustments', data: data);
  });
}
