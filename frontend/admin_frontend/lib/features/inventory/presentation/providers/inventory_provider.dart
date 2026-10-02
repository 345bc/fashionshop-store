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
  List<InventoryResponseModel> get filtered => items.where((i) {
    final q = query.trim().toLowerCase();
    return (q.isEmpty ||
            i.label.toLowerCase().contains(q) ||
            i.categoryName.toLowerCase().contains(q)) &&
        (status == 'all' ||
            (status == 'out'
                ? i.availableQuantity == 0
                : i.availableQuantity > 0));
  }).toList();
  List<InventoryResponseModel> get pageItems =>
      filtered.skip(currentPage * pageSize).take(pageSize).toList();
  void search(String value) {
    query = value;
    currentPage = 0;
    notifyListeners();
  }

  void filter(String value) {
    status = value;
    currentPage = 0;
    notifyListeners();
  }

  void page(int value) {
    currentPage = value;
    notifyListeners();
  }

  Future<void> loadItems() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repository.getAll();
      final lastPage = filtered.isEmpty ? 0 : (filtered.length - 1) ~/ pageSize;
      if (currentPage > lastPage) currentPage = lastPage;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> history(int id) => _repository.history(id);
  Future<void> adjust(Map<String, dynamic> data) async {
    await _repository.adjust(data);
    await loadItems();
  }
}
