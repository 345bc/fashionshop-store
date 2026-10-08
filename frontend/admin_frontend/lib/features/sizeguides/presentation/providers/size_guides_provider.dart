import 'package:flutter/foundation.dart';

import '../../data/api/size_guide_repository.dart';
import '../../data/models/size_guide_response_model.dart';

class SizeGuidesProvider extends ChangeNotifier {
  final SizeGuideRepository _repository = SizeGuideRepository();

  bool _isLoading = false;
  String? _error;
  List<SizeGuideResponseModel> _items = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SizeGuideResponseModel> get items => _items;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getOptions();
      _items = data.map(SizeGuideResponseModel.fromJson).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
