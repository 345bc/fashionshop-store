import 'package:flutter/foundation.dart';

import '../../data/api/category_repository.dart';
import '../../data/models/category_response_model.dart';

class CategoriesProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  bool _isLoading = false;
  String? _error;
  List<CategoryResponseModel> _items = [];
  List<CategoryResponseModel> _options = [];
  String? optionsError;
  int _totalElements = 0;
  int _requestId = 0;
  String _currentQuery = '';
  String _status = 'all';
  int _currentPage = 0;
  final int _pageSize = 15;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CategoryResponseModel> get options => _options;
  List<CategoryResponseModel> get pageItems => _items;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalElements => _totalElements;
  String get currentQuery => _currentQuery;

  void setStatus(String status) {
    _status = status;
    loadItems();
  }

  Future<void> loadItems({int page = 0, String? query}) async {
    if (query != null) _currentQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _currentPage = page;
    final requestId = ++_requestId;
    try {
      final data = await _repository.getAll(
        page: page,
        size: _pageSize,
        query: _currentQuery,
        active: _status == 'all' ? null : _status == 'active',
      );
      if (requestId != _requestId) return;
      _items = (data['content'] as List)
          .map(
            (json) =>
                CategoryResponseModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      _totalElements = (data['totalElements'] as num).toInt();
      final lastPage = _totalElements == 0
          ? 0
          : (_totalElements - 1) ~/ _pageSize;
      if (_currentPage > lastPage) await loadItems(page: lastPage);
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

  Future<void> loadOptions() async {
    optionsError = null;
    try {
      _options = (await _repository.getOptions())
          .map(CategoryResponseModel.fromJson)
          .toList();
    } catch (error) {
      optionsError = error.toString();
    }
    notifyListeners();
  }

  Future<CategoryResponseModel> loadDetail(int id) async =>
      CategoryResponseModel.fromJson(await _repository.getById(id));

  Future<List<CategoryResponseModel>> loadParentOptions() async =>
      (await _repository.getParents())
          .map(CategoryResponseModel.fromJson)
          .toList();

  Future<CategoryResponseModel> createItem(Map<String, dynamic> data) async {
    final item = CategoryResponseModel.fromJson(await _repository.create(data));
    await loadItems(page: _currentPage);
    return item;
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await _repository.update(id, data);
    await loadItems(page: _currentPage);
  }

  Future<CategoryResponseModel> uploadImage(
    int id,
    String fileName,
    Uint8List bytes,
  ) async {
    final item = CategoryResponseModel.fromJson(
      await _repository.uploadImage(id, fileName, bytes),
    );
    await loadItems(page: _currentPage);
    return item;
  }

  Future<void> deleteItem(int id) async {
    await _repository.delete(id);
    await loadItems(page: _currentPage);
  }
}
