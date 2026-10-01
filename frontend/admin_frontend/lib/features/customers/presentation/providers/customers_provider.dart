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
  List<CustomerResponseModel> get _filtered => _items.where((c) {
    final q = _query.trim().toLowerCase();
    final matches =
        q.isEmpty ||
        [
          c.fullName,
          c.email,
          c.phone,
          c.username,
        ].any((v) => v?.toLowerCase().contains(q) ?? false);
    return matches && (_filter == 'all' || c.membershipTier == _filter);
  }).toList();
  int get totalElements => _filtered.length;
  List<CustomerResponseModel> get pageItems {
    final list = _filtered;
    final start = _page * _pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + _pageSize).clamp(0, list.length));
  }

  void setQuery(String q) {
    _query = q;
    _page = 0;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    _page = 0;
    notifyListeners();
  }

  void setPage(int page) {
    _page = page;
    notifyListeners();
  }

  Future<void> loadItems() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = (await _repository.getAll())
          .map(
            (json) =>
                CustomerResponseModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      _page = _page.clamp(
        0,
        totalElements == 0 ? 0 : (totalElements - 1) ~/ _pageSize,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
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
