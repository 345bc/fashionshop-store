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
  int totalElements = 0;
  int _requestId = 0;
  List<OrderResponseModel> get pageItems => items;
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
                OrderResponseModel(Map<String, dynamic>.from(json as Map)),
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
    final customers = (await CustomerRepository().getOptions())
        .cast<Map<String, dynamic>>()
        .where((c) => c['isActive'] == true)
        .toList();
    final variants = (await InventoryRepository().getOptions())
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
