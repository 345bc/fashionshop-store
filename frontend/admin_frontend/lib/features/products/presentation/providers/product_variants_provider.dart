import 'package:flutter/foundation.dart';

import '../../data/api/product_variant_repository.dart';
import '../../data/api/variant_image_repository.dart';

typedef ProductVariantDetails = ({
  Map<String, dynamic> variant,
  List<Map<String, dynamic>> images,
});

class ProductVariantsProvider extends ChangeNotifier {
  final ProductVariantRepository _repository = ProductVariantRepository();
  final VariantImageRepository _imageRepository = VariantImageRepository();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;
  int _productId = 0;
  int _currentPage = 0;
  int _totalElements = 0;
  final int _pageSize = 15;
  String _query = '';

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalElements => _totalElements;
  int get pageSize => _pageSize;
  String get query => _query;

  Future<void> loadItems({
    required int productId,
    int page = 0,
    String? query,
  }) async {
    if (_productId != productId) {
      _items = [];
      _totalElements = 0;
      _currentPage = 0;
      _query = '';
    }
    if (query != null) _query = query;
    _productId = productId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.getAll(
        productId: productId,
        page: page,
        size: _pageSize,
        query: _query,
      );
      _items = (data['content'] as List<dynamic>).cast<Map<String, dynamic>>();
      _totalElements = (data['totalElements'] as num).toInt();
      _currentPage = (data['number'] as num).toInt();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) async {
    final variant = await _repository.create(data);
    await loadItems(productId: _productId, page: _currentPage);
    return variant;
  }

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    await _repository.update(id, data);
    await loadItems(productId: _productId, page: _currentPage);
  }

  Future<
    ({List<Map<String, dynamic>> sizes, List<Map<String, dynamic>> colors})
  >
  loadOptions() async {
    final results = await Future.wait([
      _repository.getSizes(),
      _repository.getColors(),
    ]);
    return (sizes: results[0], colors: results[1]);
  }

  Future<List<Map<String, dynamic>>> loadImages(int variantId) =>
      _imageRepository.getByVariantId(variantId);

  Future<ProductVariantDetails> loadDetail(int variantId) async {
    final variant = await _repository.getById(variantId);
    List<Map<String, dynamic>> images = [];
    try {
      images = await _imageRepository.getByVariantId(variantId);
    } catch (_) {
      // Show variant fields even when images are temporarily unavailable.
    }
    return (variant: variant, images: images);
  }

  Future<Map<String, dynamic>> uploadImage({
    required int variantId,
    required String fileName,
    required Uint8List bytes,
    required bool isPrimary,
    required int displayOrder,
  }) => _imageRepository.upload(
    variantId: variantId,
    fileName: fileName,
    bytes: bytes,
    isPrimary: isPrimary,
    displayOrder: displayOrder,
  );

  Future<Map<String, dynamic>> updateImage({
    required int id,
    required int variantId,
    required String imageUrl,
    required bool isPrimary,
    required int displayOrder,
  }) => _imageRepository.update(
    id: id,
    variantId: variantId,
    imageUrl: imageUrl,
    isPrimary: isPrimary,
    displayOrder: displayOrder,
  );

  Future<void> deleteImage(int id) => _imageRepository.delete(id);
}
