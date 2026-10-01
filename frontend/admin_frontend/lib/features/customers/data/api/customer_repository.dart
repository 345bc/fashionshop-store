import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class CustomerRepository {
  final ApiClient _api = ApiClient();
  Future<List<dynamic>> getAll() async {
    final response = await _api.get(ApiEndpoints.customers);
    return response.data['data'] as List<dynamic>;
  }

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
