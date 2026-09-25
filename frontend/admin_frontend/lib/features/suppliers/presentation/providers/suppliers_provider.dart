import 'package:flutter/foundation.dart';
import '../../data/api/supplier_repository.dart';
import '../../data/models/supplier_response_model.dart';

class SuppliersProvider extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();

  bool _isLoading = false;
  String? _error;
  List<SupplierResponseModel> _items = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SupplierResponseModel> get items => _items;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getAll(size: 100);
      if (data is List) {
        _items = data.map((json) => SupplierResponseModel.fromJson(json)).toList();
      } else if (data is Map && data['content'] != null) {
        final List<dynamic> content = data['content'];
        _items = content.map((json) => SupplierResponseModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
