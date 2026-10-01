import 'package:flutter/foundation.dart';

import '../../data/attribute_kind.dart';
import '../../data/attribute_repository.dart';

class AttributeProvider extends ChangeNotifier {
  AttributeProvider(this.kind);
  final AttributeKind kind;
  final AttributeRepository _repository = AttributeRepository();

  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get items => _items.where((item) {
    final term = _query.trim().toLowerCase();
    return term.isEmpty ||
        item.values.any(
          (value) => value?.toString().toLowerCase().contains(term) == true,
        );
  }).toList();

  void search(String query) {
    if (_disposed) return;
    _query = query;
    notifyListeners();
  }

  Future<void> load() async {
    if (_disposed) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final loaded = await _repository.getAll(kind);
      if (!_disposed) _items = loaded;
    } catch (error) {
      if (!_disposed) _error = error.toString();
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final created = await _repository.create(kind, data);
    await load();
    return created;
  }

  Future<Map<String, dynamic>> loadDetail(int id) =>
      _repository.getById(kind, id);

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _repository.update(kind, id, data);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.delete(kind, id);
    await load();
  }

  Future<Map<String, dynamic>> uploadSizeGuideImage(
    int id,
    String fileName,
    Uint8List bytes,
  ) => _repository.uploadSizeGuideImage(id, fileName, bytes);

  Future<Map<String, dynamic>> removeSizeGuideImage(int id) =>
      _repository.removeSizeGuideImage(id);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
