import 'package:flutter/foundation.dart';

import '../../data/api/inventory_repository.dart';
import '../../data/models/inventory_response_model.dart';

class InventoryProvider extends ChangeNotifier {
  final _repository = InventoryRepository();
  List<InventoryResponseModel> items = [];
  bool isLoading = false;
  String? error;
  String query = '', status = 'all';
  int currentPage = 0;
  final int pageSize = 15;
  int totalElements = 0;
  int _requestId = 0;
  List<InventoryResponseModel> get pageItems => items;
  void search(String value) {
    query = value;
    currentPage = 0;
    loadItems();
  }

  void filter(String value) {
    status = value;
    currentPage = 0;
    loadItems();
  }

  void page(int value) {
    currentPage = value;
    loadItems();
  }

  Future<void> loadItems() async {
    isLoading = true;
    error = null;
    notifyListeners();
    final requestId = ++_requestId;
    try {
      final data = await _repository.getAll(
        page: currentPage,
        size: pageSize,
        query: query,
        status: status,
      );
      if (requestId != _requestId) return;
      items = (data['content'] as List)
          .map(
            (json) =>
                InventoryResponseModel(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
      totalElements = (data['totalElements'] as num).toInt();
      final lastPage = totalElements == 0 ? 0 : (totalElements - 1) ~/ pageSize;
      if (currentPage > lastPage) {
        currentPage = lastPage;
        await loadItems();
      }
    } catch (e) {
      if (requestId != _requestId) return;
      error = e.toString();
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> history(int id, {int page = 0}) =>
      _repository.history(id, page: page);
  Future<void> adjust(Map<String, dynamic> data) async {
    await _repository.adjust(data);
    await loadItems();
  }
}
