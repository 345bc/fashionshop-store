import 'package:flutter/foundation.dart';
import '../../data/api/category_repository.dart';
import '../../data/models/category_response_model.dart';

class CategoriesProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  bool _isLoading = false;
  String? _error;
  List<CategoryResponseModel> _items = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CategoryResponseModel> get items => _items;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getAll(size: 100);
      if (data is List) {
        _items = data.map((json) => CategoryResponseModel.fromJson(json)).toList();
      } else if (data is Map && data['content'] != null) {
        final List<dynamic> content = data['content'];
        _items = content.map((json) => CategoryResponseModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
