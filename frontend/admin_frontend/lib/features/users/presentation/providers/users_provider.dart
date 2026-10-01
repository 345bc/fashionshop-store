// GENERATED FROM TEMPLATE: templates/feature_provider.dart.template
import 'package:flutter/foundation.dart';

import '../../data/models/user_response_model.dart';
import '../../data/api/users_repository.dart';

class UsersProvider extends ChangeNotifier {
  final UsersRepository _repository = UsersRepository();

  bool _isLoading = false;
  String? _error;
  List<UserResponseModel> _items = [];
  int _totalElements = 0;
  int _currentPage = 0;
  final int _pageSize = 15;

  String? _currentQuery;
  String? _currentRole;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserResponseModel> get items => _items;
  int get totalElements => _totalElements;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String? get currentQuery => _currentQuery;
  String? get currentRole => _currentRole;

  Future<void> loadItems({int page = 0, String? query, String? role}) async {
    try {
      _isLoading = true;
      _error = null;
      if (query != null) _currentQuery = query;
      if (role != null) _currentRole = role;
      notifyListeners();

      final result = await _repository.getAll(
        page: page,
        size: _pageSize,
        query: _currentQuery,
        role: _currentRole == 'ALL' ? null : _currentRole,
      );

      _items = (result['content'] as List)
          .map((e) => UserResponseModel.fromJson(e))
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

  Future<void> deleteItem(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.delete(id);
      await loadItems(page: _currentPage);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
