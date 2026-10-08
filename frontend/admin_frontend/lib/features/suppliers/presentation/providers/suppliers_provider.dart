import 'package:flutter/foundation.dart';

import '../../data/api/supplier_repository.dart';
import '../../data/models/supplier_response_model.dart';

class SuppliersProvider extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();
  bool _isLoading = false;
  String? _error;
  List<SupplierResponseModel> _items = [];
  List<SupplierResponseModel> _options = [];
  String? optionsError;
  List<SupplierResponseModel> get options => _options;
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
  int _totalElements = 0;
  int _requestId = 0;
  int get totalElements => _totalElements;
  List<SupplierResponseModel> get pageItems => _items;

  void setQuery(String query) {
    _query = query;
    _page = 0;
    loadItems();
  }

  void setStatus(String status) {
    _status = status;
    _page = 0;
    loadItems();
  }

  void setPage(int page) {
    _page = page;
    loadItems();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final requestId = ++_requestId;
    try {
      final data = await _repository.getAll(
        page: _page,
        size: _pageSize,
        query: _query,
        status: _status,
      );
      if (requestId != _requestId) return;
      _items = (data['content'] as List)
          .map(
            (json) => SupplierResponseModel.fromJson(
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
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<SupplierResponseModel> loadDetail(int id) async =>
      SupplierResponseModel.fromJson(await _repository.getById(id));

  Future<void> loadOptions() async {
    optionsError = null;
    try {
      _options = (await _repository.getOptions())
          .map(
            (json) =>
                SupplierResponseModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      optionsError = error.toString();
    }
    notifyListeners();
  }

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
