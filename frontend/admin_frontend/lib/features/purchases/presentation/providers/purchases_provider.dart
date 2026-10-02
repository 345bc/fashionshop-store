import 'package:flutter/foundation.dart';

import '../../../inventory/data/api/inventory_repository.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../suppliers/data/api/supplier_repository.dart';
import '../../../suppliers/data/models/supplier_response_model.dart';
import '../../data/api/goods_receipt_repository.dart';
import '../../data/models/goods_receipt_response_model.dart';

class PurchasesProvider extends ChangeNotifier {
  final _repository = GoodsReceiptRepository();
  List<GoodsReceiptResponseModel> items = [];
  bool isLoading = false;
  String? error;
  String query = '', status = 'all';
  int currentPage = 0;
  final int pageSize = 15;
  List<GoodsReceiptResponseModel> get filtered => items
      .where(
        (r) =>
            (status == 'all' || r.status == status) &&
            ('${r.code} ${r.supplierName}'.toLowerCase().contains(
              query.trim().toLowerCase(),
            )),
      )
      .toList();
  List<GoodsReceiptResponseModel> get pageItems =>
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

  Future<GoodsReceiptResponseModel> loadDetail(int id) =>
      _repository.getById(id);
  Future<
    ({
      List<SupplierResponseModel> suppliers,
      List<InventoryResponseModel> variants,
    })
  >
  options() async {
    final suppliers = (await SupplierRepository().getAll())
        .map((j) => SupplierResponseModel.fromJson(j as Map<String, dynamic>))
        .where((s) => s.isActive)
        .toList();
    final variants = await InventoryRepository().getAll();
    return (
      suppliers: suppliers,
      variants: variants.where((v) => v.isActive).toList(),
    );
  }

  Future<void> save(Map<String, dynamic> data, {int? id}) async {
    await _repository.save(data, id: id);
    await loadItems();
  }

  Future<void> action(
    int id,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    await _repository.action(id, action, data: data);
    await loadItems();
  }
}
