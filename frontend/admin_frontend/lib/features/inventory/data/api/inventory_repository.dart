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
  Future<List<InventoryResponseModel>> getOptions({int? supplierId}) async {
    final items = <InventoryResponseModel>[];
    var page = 0;
    while (true) {
      final data = await getAll(page: page, size: 100, supplierId: supplierId);
      final content = data['content'] as List;
      items.addAll(
        content.map(
          (json) => InventoryResponseModel(json as Map<String, dynamic>),
        ),
      );
      page++;
      if (page >= (data['totalPages'] as num).toInt()) break;
    }
    return items;
  }

  Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 15,
    String? query,
    String? status,
    int? supplierId,
  }) => warehouseRequest(() async {
    final response = await _api.get(
      ApiEndpoints.inventory,
      queryParameters: {
        'page': page,
        'size': size,
        'q': ?query,
        'status': ?status,
        'supplierId': ?supplierId,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  });

  final _api = ApiClient();
  Future<Map<String, dynamic>> history(int id, {int page = 0, int size = 15}) =>
      warehouseRequest(() async {
        final response = await _api.get(
          '${ApiEndpoints.inventory}/movements',
          queryParameters: {'variantId': id, 'page': page, 'size': size},
        );
        return Map<String, dynamic>.from(response.data['data'] as Map);
      });
  Future<void> adjust(Map<String, dynamic> data) => warehouseRequest(() async {
    await _api.post('${ApiEndpoints.inventory}/adjustments', data: data);
  });
}
