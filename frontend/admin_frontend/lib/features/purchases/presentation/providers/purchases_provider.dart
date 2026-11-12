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
  String paymentStatus = 'all';
  int? supplierId;
  int currentPage = 0;
  final int pageSize = 15;
  int totalElements = 0;
  int _requestId = 0;
  List<GoodsReceiptResponseModel> get pageItems => items;
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

  void filterPaymentStatus(String value) {
    paymentStatus = value;
    page(0);
  }

  void filterSupplier(int? value) {
    supplierId = value;
    page(0);
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
        paymentStatus: paymentStatus,
        supplierId: supplierId,
      );
      if (requestId != _requestId) return;
      items = (data['content'] as List)
          .map(
            (json) => GoodsReceiptResponseModel(
              Map<String, dynamic>.from(json as Map),
            ),
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

  Future<GoodsReceiptResponseModel> loadDetail(int id) =>
      _repository.getById(id);
  Future<
    ({
      List<SupplierResponseModel> suppliers,
      List<InventoryResponseModel> variants,
    })
  >
  options() async {
    final suppliers = (await supplierOptions())
        .where((s) => s.isActive)
        .toList();
    final variants = await InventoryRepository().getOptions();
    return (suppliers: suppliers, variants: variants);
  }

  Future<List<SupplierResponseModel>> supplierOptions() async =>
      (await SupplierRepository().getOptions())
          .map(
            (json) =>
                SupplierResponseModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

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
