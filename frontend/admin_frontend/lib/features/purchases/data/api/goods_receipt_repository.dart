import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../inventory/data/api/inventory_repository.dart';
import '../models/goods_receipt_response_model.dart';

class GoodsReceiptRepository {
  Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 15,
    String? query,
    String? status,
  }) => warehouseRequest(() async {
    final response = await _api.get(
      ApiEndpoints.goodsReceipts,
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
  Future<GoodsReceiptResponseModel> getById(int id) =>
      warehouseRequest(() async {
        final response = await _api.get('${ApiEndpoints.goodsReceipts}/$id');
        return GoodsReceiptResponseModel(
          response.data['data'] as Map<String, dynamic>,
        );
      });
  Future<void> save(Map<String, dynamic> data, {int? id}) =>
      warehouseRequest(() async {
        if (id == null) {
          await _api.post(ApiEndpoints.goodsReceipts, data: data);
        } else {
          await _api.put('${ApiEndpoints.goodsReceipts}/$id', data: data);
        }
      });
  Future<void> action(int id, String action, {Map<String, dynamic>? data}) =>
      warehouseRequest(() async {
        await _api.post(
          '${ApiEndpoints.goodsReceipts}/$id/$action',
          data: data,
        );
      });
}
