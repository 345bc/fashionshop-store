import 'package:flutter/foundation.dart';

import '../../data/api/customer_repository.dart';
import '../../data/models/customer_response_model.dart';

class CustomersProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();
  List<CustomerResponseModel> _items = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  String _filter = 'all';
  int _page = 0;
  final int _pageSize = 15;

  bool get isLoading => _loading;
  String? get error => _error;
  List<CustomerResponseModel> get items => _items;
  int get currentPage => _page;
  int get pageSize => _pageSize;
  int _totalElements = 0;
  int _requestId = 0;
  int get totalElements => _totalElements;
  List<CustomerResponseModel> get pageItems => _items;

  void setQuery(String q) {
    _query = q;
    _page = 0;
    loadItems();
  }

  void setFilter(String filter) {
    _filter = filter;
    _page = 0;
    loadItems();
  }

  void setPage(int page) {
    _page = page;
    loadItems();
  }

  Future<void> loadItems() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final requestId = ++_requestId;
    try {
      final data = await _repository.getAll(
        page: _page,
        size: _pageSize,
        query: _query,
        tier: _filter,
      );
      if (requestId != _requestId) return;
      _items = (data['content'] as List)
          .map(
            (json) => CustomerResponseModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
      _totalElements = (data['totalElements'] as num).toInt();
      final lastPage = _totalElements == 0
          ? 0
          : (_totalElements - 1) ~/ _pageSize;
      if (_page > lastPage) {
        _page = lastPage;
        await loadItems();
      }
    } catch (e) {
      if (requestId != _requestId) return;
      _error = e.toString();
    } finally {
      if (requestId == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<CustomerResponseModel> loadDetail(int id) async =>
      CustomerResponseModel.fromJson(await _repository.getById(id));
  Future<void> createItem(Map<String, dynamic> data) async {
    await _repository.create(data);
    await loadItems();
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await _repository.update(id, data);
    await loadItems();
  }
}
