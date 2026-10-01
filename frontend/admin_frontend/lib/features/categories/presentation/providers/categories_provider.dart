import 'package:flutter/foundation.dart';

import '../../data/api/category_repository.dart';
import '../../data/models/category_response_model.dart';

class CategoriesProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  bool _isLoading = false;
  String? _error;
  List<CategoryResponseModel> _sourceItems = [];
  List<CategoryResponseModel> _allItems = [];
  String _currentQuery = '';
  String _status = 'all';
  int _currentPage = 0;
  final int _pageSize = 15;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CategoryResponseModel> get allItems => _allItems;
  List<CategoryResponseModel> get items => _sourceItems;
  List<CategoryResponseModel> get _filteredItems => _allItems
      .where(
        (item) => _status == 'all' || item.isActive == (_status == 'active'),
      )
      .toList();
  List<CategoryResponseModel> get pageItems {
    final filtered = _filteredItems;
    final start = _currentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalElements => _filteredItems.length;
  String get currentQuery => _currentQuery;

  void setStatus(String status) {
    _status = status;
    _currentPage = 0;
    notifyListeners();
  }

  Future<void> loadItems({int page = 0, String? query}) async {
    if (query != null) _currentQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getAll();
      _sourceItems = data.map(CategoryResponseModel.fromJson).toList();
      final term = _currentQuery.trim().toLowerCase();
      _allItems = _sourceItems
          .where(
            (item) =>
                term.isEmpty ||
                item.name.toLowerCase().contains(term) ||
                item.slug.toLowerCase().contains(term),
          )
          .toList();
      final lastPage = totalElements == 0
          ? 0
          : (totalElements - 1) ~/ _pageSize;
      _currentPage = page.clamp(0, lastPage);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CategoryResponseModel> loadDetail(int id) async =>
      CategoryResponseModel.fromJson(await _repository.getById(id));

  Future<List<CategoryResponseModel>> loadParentOptions() async =>
      (await _repository.getParents())
          .map(CategoryResponseModel.fromJson)
          .toList();

  Future<void> createItem(Map<String, dynamic> data) async {
    await _repository.create(data);
    await loadItems(page: _currentPage);
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await _repository.update(id, data);
    await loadItems(page: _currentPage);
  }

  Future<void> deleteItem(int id) async {
    await _repository.delete(id);
    await loadItems(page: _currentPage);
  }
}
