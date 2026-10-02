import 'package:flutter/foundation.dart';

import '../../data/models/product_review_model.dart';
import '../../data/repositories/feedback_repository.dart';

enum ReviewFilter {
  all('Tất cả'),
  unanswered('Chưa trả lời'),
  replied('Đã trả lời'),
  visible('Đang hiển thị'),
  hidden('Đã ẩn');

  const ReviewFilter(this.label);
  final String label;
}

enum FeedbackView { inbox, products }

class FeedbackFilters {
  String query = '';
  int? rating, parentId, categoryId, selectedReviewId;
  ReviewFilter filter;
  int page = 0;
  FeedbackFilters(this.filter);
}

class FeedbackProvider extends ChangeNotifier {
  FeedbackProvider({FeedbackRepository? repository})
    : _repository = repository ?? FeedbackRepository();
  final FeedbackRepository _repository;
  FeedbackView view = FeedbackView.inbox;
  int? selectedProductId;
  final _inbox = FeedbackFilters(ReviewFilter.unanswered);
  final _productReviews = <int, FeedbackFilters>{};
  final catalogFilters = FeedbackFilters(ReviewFilter.all);
  final Map<int, String> drafts = {};
  FeedbackFilters get filters =>
      view == FeedbackView.products && selectedProductId != null
      ? _productReviews.putIfAbsent(
          selectedProductId!,
          () => FeedbackFilters(ReviewFilter.all),
        )
      : _inbox;
  String get query => filters.query;
  int? get rating => filters.rating;
  ReviewFilter get filter => filters.filter;
  int get currentPage => filters.page;
  final int pageSize = 10;

  List<ProductReviewModel> get items => _repository.items;
  List<ProductReviewModel> get filteredItems =>
      items
          .where(
            (r) =>
                (rating == null || r.rating == rating) &&
                (view != FeedbackView.products ||
                    selectedProductId == null ||
                    r.productId == selectedProductId) &&
                _inCategory(r.productId, filters) &&
                '${r.customerName} ${r.customerEmail} ${r.productName} ${r.sku} ${r.orderCode} ${r.comment}'
                    .toLowerCase()
                    .contains(query.toLowerCase().trim()) &&
                matches(r, filter),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<ProductReviewModel> get pageItems =>
      filteredItems.skip(currentPage * pageSize).take(pageSize).toList();
  int count(ReviewFilter value) => items.where((r) => matches(r, value)).length;
  double get averageRating => items.isEmpty
      ? 0
      : items.fold<int>(0, (sum, r) => sum + r.rating) / items.length;
  static bool matches(ProductReviewModel r, ReviewFilter value) =>
      switch (value) {
        ReviewFilter.all => true,
        ReviewFilter.unanswered =>
          r.adminReply == null && r.visibility == ReviewVisibility.visible,
        ReviewFilter.replied => r.adminReply != null,
        ReviewFilter.visible => r.visibility == ReviewVisibility.visible,
        ReviewFilter.hidden => r.visibility == ReviewVisibility.hidden,
      };
  ProductReviewModel detail(int id) => items.firstWhere((r) => r.id == id);
  void setQuery(String value) {
    filters.query = value;
    _reset();
  }

  void setRating(int? value) {
    filters.rating = value;
    _reset();
  }

  void setFilter(ReviewFilter value) {
    filters.filter = value;
    _reset();
  }

  void _reset() {
    filters.page = 0;
    filters.selectedReviewId = null;
    notifyListeners();
  }

  void setPage(int value) {
    filters.page = value.clamp(
      0,
      ((filteredItems.length - 1) ~/ pageSize).clamp(0, 999999),
    );
    if (pageItems.isNotEmpty &&
        !pageItems.any((r) => r.id == filters.selectedReviewId)) {
      filters.selectedReviewId = pageItems.first.id;
    }
    notifyListeners();
  }

  bool _inCategory(int productId, FeedbackFilters f) {
    final product = FeedbackRepository.products.firstWhere(
      (p) => p.id == productId,
    );
    return (f.parentId == null || product.parentId == f.parentId) &&
        (f.categoryId == null || product.categoryId == f.categoryId);
  }

  List<ProductReviewModel> reviewsFor(int productId) =>
      items.where((r) => r.productId == productId).toList();
  int unansweredFor(int productId) => reviewsFor(productId)
      .where(
        (r) => r.adminReply == null && r.visibility == ReviewVisibility.visible,
      )
      .length;
  double averageFor(int productId) {
    final reviews = reviewsFor(productId)
        .where((r) => r.visibility == ReviewVisibility.visible)
        .toList();
    return reviews.isEmpty
        ? 0
        : reviews.fold<int>(0, (n, r) => n + r.rating) / reviews.length;
  }

  List<int> get catalogIds {
    final ids = FeedbackRepository.products
        .where(
          (p) =>
              _inCategory(p.id, catalogFilters) &&
              reviewsFor(p.id).isNotEmpty &&
              '${p.name} ${reviewsFor(p.id).map((r) => r.sku).join(' ')}'
                  .toLowerCase()
                  .contains(catalogFilters.query.trim().toLowerCase()),
        )
        .map((p) => p.id)
        .toList();
    ids.sort((a, b) {
      final pending = (unansweredFor(b) > 0 ? 1 : 0).compareTo(
        unansweredFor(a) > 0 ? 1 : 0,
      );
      if (pending != 0) return pending;
      final latestA = reviewsFor(a)
          .map((r) => r.createdAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);
      final latestB = reviewsFor(b)
          .map((r) => r.createdAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);
      return latestB.compareTo(latestA);
    });
    return ids;
  }

  List<int> get catalogPage =>
      catalogIds.skip(catalogFilters.page * pageSize).take(pageSize).toList();
  ProductReviewModel? get selectedReview {
    final reviews = filteredItems;
    if (reviews.isEmpty) return null;
    return reviews.firstWhere(
      (r) => r.id == filters.selectedReviewId,
      orElse: () => reviews.first,
    );
  }

  void selectReview(int id) {
    filters.selectedReviewId = id;
    notifyListeners();
  }

  void setView(FeedbackView value) {
    view = value;
    notifyListeners();
  }

  void openProduct(int id) {
    selectedProductId = id;
    view = FeedbackView.products;
    notifyListeners();
  }

  void backToCatalog() {
    selectedProductId = null;
    notifyListeners();
  }

  void setCategory(int? id, {required bool parent, bool catalog = false}) {
    final f = catalog ? catalogFilters : filters;
    if (parent) {
      f.parentId = id;
      f.categoryId = null;
    } else {
      f.categoryId = id;
    }
    f.page = 0;
    notifyListeners();
  }

  void setCatalogQuery(String value) {
    catalogFilters.query = value;
    catalogFilters.page = 0;
    notifyListeners();
  }

  void setCatalogPage(int page) {
    catalogFilters.page = page.clamp(
      0,
      ((catalogIds.length - 1) ~/ pageSize).clamp(0, 999999),
    );
    notifyListeners();
  }

  void replyAndNext(int id, String text) {
    final before = filteredItems;
    final index = before.indexWhere((r) => r.id == id);
    reply(id, text, 'CSKH (mẫu)');
    drafts.remove(id);
    final remaining = filteredItems;
    if (remaining.isNotEmpty) {
      final nextIds = [
        ...before.skip(index + 1),
        ...before.take(index),
      ].map((r) => r.id);
      filters.selectedReviewId = nextIds.firstWhere(
        (candidate) => remaining.any((r) => r.id == candidate),
        orElse: () => remaining.first.id,
      );
      filters.page =
          remaining.indexWhere((r) => r.id == filters.selectedReviewId) ~/
          pageSize;
    } else {
      filters.selectedReviewId = null;
    }
    notifyListeners();
  }

  void reply(int id, String text, String actor) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) {
      throw ArgumentError('Câu trả lời cần từ 1 đến 1000 ký tự');
    }
    _save(detail(id).reply(trimmed, actor));
  }

  void moderate(int id, ReviewVisibility value, String reason, String actor) {
    if (reason.trim().isEmpty || reason.trim().length > 500) {
      throw ArgumentError('Lý do cần từ 1 đến 500 ký tự');
    }
    if (detail(id).visibility == value) return;
    _save(detail(id).moderate(value, reason.trim(), actor));
  }

  void _save(ProductReviewModel r) {
    _repository.save(r);
    setPage(currentPage);
  }
}
