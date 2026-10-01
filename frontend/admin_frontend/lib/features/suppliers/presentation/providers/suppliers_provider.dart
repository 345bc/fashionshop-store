import 'package:flutter/foundation.dart';

import '../../data/api/supplier_repository.dart';
import '../../data/models/supplier_response_model.dart';

class SuppliersProvider extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();
  bool _isLoading = false;
  String? _error;
  List<SupplierResponseModel> _items = [];
  String _query = '';
  String _status = 'all';
  int _page = 0;
  final int _pageSize = 15;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SupplierResponseModel> get items => _items;
  String get currentQuery => _query;
  int get currentPage => _page;
  int get pageSize => _pageSize;
  List<SupplierResponseModel> get _filtered => _items.where((item) {
    final q = _query.trim().toLowerCase();
    final matchesQuery =
        q.isEmpty ||
        [
          item.name,
          item.code,
          item.phone,
          item.contactEmail,
          item.contactPerson,
        ].any((v) => v?.toLowerCase().contains(q) ?? false);
    return matchesQuery &&
        (_status == 'all' || item.isActive == (_status == 'active'));
  }).toList();
  int get totalElements => _filtered.length;
  List<SupplierResponseModel> get pageItems {
    final data = _filtered;
    final start = _page * _pageSize;
    if (start >= data.length) return [];
    return data.sublist(start, (start + _pageSize).clamp(0, data.length));
  }

  void setQuery(String query) {
    _query = query;
    _page = 0;
    notifyListeners();
  }

  void setStatus(String status) {
    _status = status;
    _page = 0;
    notifyListeners();
  }

  void setPage(int page) {
    _page = page;
    notifyListeners();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = (await _repository.getAll())
          .map(
            (json) =>
                SupplierResponseModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      final lastPage = totalElements == 0
          ? 0
          : (totalElements - 1) ~/ _pageSize;
      _page = _page.clamp(0, lastPage);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplierResponseModel> loadDetail(int id) async =>
      SupplierResponseModel.fromJson(await _repository.getById(id));
  Future<void> createItem(Map<String, dynamic> data) async {
    await _repository.create(data);
    await loadItems();
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await _repository.update(id, data);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _repository.delete(id);
    await loadItems();
  }
}
