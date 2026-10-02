import 'package:flutter/foundation.dart';

import '../../../customers/data/api/customer_repository.dart';
import '../../../inventory/data/api/inventory_repository.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/api/order_repository.dart';
import '../../data/models/order_response_model.dart';

class OrdersProvider extends ChangeNotifier {
  final _repository = OrderRepository();
  List<OrderResponseModel> items = [];
  bool isLoading = false;
  String? error;
  String query = '', status = 'all';
  int currentPage = 0;
  final int pageSize = 15;
  List<OrderResponseModel> get filtered => items
      .where(
        (r) =>
            (status == 'all' || r.status == status) &&
            '${r.code} ${r.customerName} ${r.recipientPhone}'
                .toLowerCase()
                .contains(query.trim().toLowerCase()),
      )
      .toList();
  List<OrderResponseModel> get pageItems =>
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

  Future<OrderResponseModel> loadDetail(int id) => _repository.getById(id);
  // BEGIN TEMP_ORDER_PAYMENT_SIMULATION
  Future<bool> paymentSimulationEnabled() =>
      _repository.paymentSimulationEnabled();
  Future<void> simulatePayment(int id) async {
    await _repository.simulatePayment(id);
    await loadItems();
  }

  // END TEMP_ORDER_PAYMENT_SIMULATION
  Future<
    ({
      List<Map<String, dynamic>> customers,
      List<InventoryResponseModel> variants,
    })
  >
  options() async {
    final customers = (await CustomerRepository().getAll())
        .cast<Map<String, dynamic>>()
        .where((c) => c['isActive'] == true)
        .toList();
    final variants = (await InventoryRepository().getAll())
        .where((v) => v.isActive && v.availableQuantity > 0)
        .toList();
    return (customers: customers, variants: variants);
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _repository.create(data);
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

  Future<List<ReturnResponseModel>> returns(int orderId) =>
      _repository.returns(orderId);
  Future<void> createReturn(Map<String, dynamic> data) async {
    await _repository.createReturn(data);
    await loadItems();
  }

  Future<void> returnAction(
    int id,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    await _repository.returnAction(id, action, data: data);
    await loadItems();
  }
}
