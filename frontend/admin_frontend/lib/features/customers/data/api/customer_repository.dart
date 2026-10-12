import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class CustomerRepository {
  Future<List<dynamic>> getOptions() async {
    final items = <dynamic>[];
    var page = 0;
    while (true) {
      final data = await getAll(page: page, size: 100);
      final content = data['content'] as List;
      items.addAll(content);
      page++;
      if (page >= (data['totalPages'] as num).toInt()) break;
    }
    return items;
  }

  Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 15,
    String? query,
    String? tier,
  }) async {
    final response = await _api.get(
      ApiEndpoints.customers,
      queryParameters: {'page': page, 'size': size, 'q': ?query, 'tier': ?tier},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  final ApiClient _api = ApiClient();
  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _api.get('${ApiEndpoints.customers}/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post(ApiEndpoints.customers, data: data);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('${ApiEndpoints.customers}/$id', data: data);
  }
}
