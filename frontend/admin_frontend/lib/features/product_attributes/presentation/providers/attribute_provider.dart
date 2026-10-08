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
  int currentPage = 0, totalElements = 0;
  final int pageSize = 15;
  int _requestId = 0;
  List<Map<String, dynamic>> get items => _items;

  void search(String query) {
    if (_disposed) return;
    _query = query;
    currentPage = 0;
    load();
  }

  void setPage(int page) {
    currentPage = page;
    load();
  }

  Future<void> load() async {
    if (_disposed) return;
    _loading = true;
    _error = null;
    notifyListeners();
    final requestId = ++_requestId;
    try {
      if (kind == AttributeKind.size) {
        final loaded = (await _repository.getAll(kind) as List)
            .cast<Map<String, dynamic>>();
        if (_disposed || requestId != _requestId) return;
        final term = _query.trim().toLowerCase();
        _items = loaded
            .where(
              (item) => item.values.any(
                (v) => v?.toString().toLowerCase().contains(term) ?? false,
              ),
            )
            .toList();
        totalElements = _items.length;
      } else {
        final data = await _repository.getAll(
          kind,
          page: currentPage,
          size: pageSize,
          query: _query,
        );
        if (_disposed || requestId != _requestId) return;
        _items = (data['content'] as List).cast<Map<String, dynamic>>();
        totalElements = (data['totalElements'] as num).toInt();
        final last = totalElements == 0 ? 0 : (totalElements - 1) ~/ pageSize;
        if (currentPage > last) {
          currentPage = last;
          await load();
        }
      }
    } catch (error) {
      if (!_disposed && requestId == _requestId) _error = error.toString();
    } finally {
      if (!_disposed && requestId == _requestId) {
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
