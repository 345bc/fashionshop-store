// GENERATED FROM TEMPLATE: templates/feature_provider.dart.template
import 'package:flutter/foundation.dart';
import 'package:zella_admin_flutter/features/products/data/api/product_repository.dart';
import 'package:zella_admin_flutter/features/products/data/api/product_image_repository.dart';
import 'package:zella_admin_flutter/features/products/data/models/product_response_model.dart';

typedef ProductDetails = ({
  Map<String, dynamic> product,
  List<Map<String, dynamic>> images,
});

class ProductsProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final ProductImageRepository _imageRepository = ProductImageRepository();

  bool _isLoading = false;
  String? _error;
  List<ProductResponseModel> _items = [];
  int _totalElements = 0;
  int _currentPage = 0;
  final int _pageSize = 15;

  String? _currentQuery;
  int? _categoryId;
  int _requestId = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductResponseModel> get items => _items;
  int get totalElements => _totalElements;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String? get currentQuery => _currentQuery;
  int? get categoryId => _categoryId;

  Future<void> setCategory(int? categoryId) async {
    _categoryId = categoryId;
    await loadItems();
  }

  Future<void> loadItems({int page = 0, String? query}) async {
    final requestId = ++_requestId;
    try {
      _isLoading = true;
      _error = null;
      if (query != null) _currentQuery = query;
      notifyListeners();

      final result = await _repository.getAll(
        page: page,
        size: _pageSize,
        query: _currentQuery,
        categoryId: _categoryId,
      );

      if (requestId != _requestId) return;
      _items = (result['content'] as List)
          .map((e) => ProductResponseModel.fromJson(e))
          .toList();
      _totalElements = result['totalElements'] ?? 0;
      _currentPage = result['number'] ?? 0;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = e.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<ProductDetails> loadDetail(int productId) async {
    final product = await _repository.getById(productId);
    List<Map<String, dynamic>> images = [];
    try {
      images = await _imageRepository.getByProductId(productId);
    } catch (_) {
      // Still show product details when its images are unavailable.
    }
    return (product: product, images: images);
  }

  Future<List<Map<String, dynamic>>> loadImages(int productId) =>
      _imageRepository.getByProductId(productId);

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();
      final product = await _repository.create(data);
      await loadItems(page: _currentPage);
      return product;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createImage({
    required int productId,
    required String imageUrl,
    required bool isPrimary,
    required int displayOrder,
  }) => _imageRepository.create(
    productId: productId,
    imageUrl: imageUrl,
    isPrimary: isPrimary,
    displayOrder: displayOrder,
  );

  Future<Map<String, dynamic>> uploadImage({
    required int productId,
    required String fileName,
    required Uint8List bytes,
    required bool isPrimary,
    required int displayOrder,
  }) => _imageRepository.upload(
    productId: productId,
    fileName: fileName,
    bytes: bytes,
    isPrimary: isPrimary,
    displayOrder: displayOrder,
  );

  Future<Map<String, dynamic>> updateImage({
    required int id,
    required int productId,
    required String imageUrl,
    required bool isPrimary,
    required int displayOrder,
  }) => _imageRepository.update(
    id: id,
    productId: productId,
    imageUrl: imageUrl,
    isPrimary: isPrimary,
    displayOrder: displayOrder,
  );

  Future<void> deleteImage(int id) => _imageRepository.delete(id);

  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.update(id, data);
      await loadItems(page: _currentPage);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> deleteItem(int id) async {
  //   try {
  //     _isLoading = true;
  //     notifyListeners();
  //     await _repository.delete(id);
  //     await loadItems(page: _currentPage);
  //   } catch (e) {
  //     rethrow;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
}
