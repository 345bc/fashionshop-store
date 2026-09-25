// GENERATED FROM TEMPLATE: templates/feature_provider.dart.template
import 'package:flutter/foundation.dart';
import 'package:zella_admin_flutter/features/products/data/api/product_repository.dart';
import 'package:zella_admin_flutter/features/products/data/models/product_response_model.dart';

class ProductsProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  bool _isLoading = false;
  String? _error;
  List<ProductResponseModel> _items = [];
  int _totalElements = 0;
  int _currentPage = 0;
  final int _pageSize = 15;

  String? _currentQuery;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductResponseModel> get items => _items;
  int get totalElements => _totalElements;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String? get currentQuery => _currentQuery;

  Future<void> loadItems({int page = 0, String? query}) async {
    try {
      _isLoading = true;
      _error = null;
      if (query != null) _currentQuery = query;
      notifyListeners();

      final result = await _repository.getAll(
        page: page,
        size: _pageSize,
        query: _currentQuery,
      );

      _items = (result['content'] as List)
          .map((e) => ProductResponseModel.fromJson(e))
          .toList();
      _totalElements = result['totalElements'] ?? 0;
      _currentPage = result['number'] ?? 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.create(data);
      await loadItems(page: _currentPage);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.update(id, data);
      await loadItems(page: _currentPage);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> deleteItem(int id) async {
  //   try {
  //     _isLoading = true;
  //     notifyListeners();
  //     await _repository.delete(id);
  //     await loadItems(page: _currentPage);
  //   } catch (e) {
  //     rethrow;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
}
