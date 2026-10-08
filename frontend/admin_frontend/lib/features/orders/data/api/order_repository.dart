import '../../../../core/network/api_client.dart';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../inventory/data/api/inventory_repository.dart';
import '../models/order_response_model.dart';

class OrderRepository {
  Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 15,
    String? query,
    String? status,
  }) => warehouseRequest(() async {
    final response = await _api.get(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        'size': size,
        'q': ?query,
        'status': ?status,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  });

  final _api = ApiClient();
  // BEGIN TEMP_ORDER_PAYMENT_SIMULATION: remove when integrating the real gateway.
  Future<bool> paymentSimulationEnabled() async {
    try {
      final r = await _api.get('/order-test/enabled');
      return r.data['data'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> simulatePayment(int id) => warehouseRequest(() async {
    await _api.post('/order-test/$id/confirm');
  });
  // END TEMP_ORDER_PAYMENT_SIMULATION
  Future<OrderResponseModel> getById(int id) => warehouseRequest(() async {
    final r = await _api.get('${ApiEndpoints.orders}/$id');
    return OrderResponseModel(r.data['data'] as Map<String, dynamic>);
  });
  Future<void> create(Map<String, dynamic> data) => warehouseRequest(() async {
    await _api.post(ApiEndpoints.orders, data: data);
  });
  Future<void> action(int id, String action, {Map<String, dynamic>? data}) =>
      warehouseRequest(() async {
        await _api.post('${ApiEndpoints.orders}/$id/$action', data: data);
      });
  Future<List<ReturnResponseModel>> returns(int orderId) =>
      warehouseRequest(() async {
        final r = await _api.get(
          ApiEndpoints.orderReturns,
          queryParameters: {'orderId': orderId},
        );
        return (r.data['data'] as List)
            .map((j) => ReturnResponseModel(j as Map<String, dynamic>))
            .toList();
      });
  Future<void> createReturn(Map<String, dynamic> data) =>
      warehouseRequest(() async {
        await _api.post(ApiEndpoints.orderReturns, data: data);
      });
  Future<void> returnAction(
    int id,
    String action, {
    Map<String, dynamic>? data,
  }) => warehouseRequest(() async {
    await _api.post('${ApiEndpoints.orderReturns}/$id/$action', data: data);
  });
}
