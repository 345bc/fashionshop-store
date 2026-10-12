import '../models/product_review_model.dart';

/// In-memory demo only. Replace this repository when review APIs are available.
class FeedbackRepository {
  // Product/category display data for the demo, using existing catalog concepts.
  static const products = [
    (
      id: 1,
      name: 'Áo sơ mi nữ lụa cổ nơ',
      parentId: 1,
      parent: 'Nữ',
      categoryId: 11,
      category: 'Áo nữ',
    ),
    (
      id: 2,
      name: 'Áo sơ mi nam Oxford trắng',
      parentId: 2,
      parent: 'Nam',
      categoryId: 21,
      category: 'Áo nam',
    ),
    (
      id: 3,
      name: 'Váy nữ midi xếp ly',
      parentId: 1,
      parent: 'Nữ',
      categoryId: 12,
      category: 'Váy nữ',
    ),
  ];
  final List<ProductReviewModel> _items = _seed();
  List<ProductReviewModel> get items => List.unmodifiable(_items);

  void save(ProductReviewModel review) {
    final index = _items.indexWhere((item) => item.id == review.id);
    if (index < 0) throw StateError('Không tìm thấy đánh giá');
    _items[index] = review;
  }

  static List<ProductReviewModel> _seed() {
    const names = [
      'Nguyễn Lan Phương',
      'Trần Hải Đăng',
      'Hoàng Mai Ly',
      'Lê Gia Bảo',
      'Phạm Minh Anh',
      'Trần Thu Hà',
    ];
    const products = [
      'Áo sơ mi nữ lụa cổ nơ',
      'Áo sơ mi nam Oxford trắng',
      'Váy nữ midi xếp ly',
    ];
    const comments = [
      'Vải mềm, đường may đẹp. Sẽ mua thêm màu khác.',
      'Giao hàng nhanh, size M vừa người.',
      'Màu thực tế đậm hơn ảnh, shop tư vấn giúp cách đổi màu nhé.',
      'Sản phẩm đúng mô tả, đóng gói cẩn thận.',
      'Chờ giao hàng lâu, mong shop cải thiện.',
      'Nội dung quảng cáo và đường dẫn không liên quan đến sản phẩm.',
    ];
    return List.generate(18, (i) {
      final date = DateTime(2026, 10, 1, 9).subtract(Duration(hours: i * 7));
      final hidden = i % 6 == 5;
      final replied = i % 6 == 1;
      return ProductReviewModel(
        id: i + 1,
        productId: i % 3 + 1,
        orderId: 100 + i,
        orderItemId: 200 + i,
        customerId: i % 4 == 0 ? null : i + 1,
        rating: [5, 4, 2, 5, 1, 3][i % 6],
        customerName: names[i % 6],
        customerEmail: 'khach${i + 1}@example.com',
        productName: products[i % 3],
        sku: 'SP-${i % 3 + 1}-M-BLK',
        orderCode: 'ORD-DEMO-${100 + i}',
        comment: comments[i % 6],
        createdAt: date,
        visibility: hidden ? ReviewVisibility.hidden : ReviewVisibility.visible,
        moderationReason: hidden ? 'Quảng cáo không liên quan' : null,
        adminReply: replied ? 'Cảm ơn bạn đã tin tưởng Zella!' : null,
        repliedAt: replied ? date.add(const Duration(hours: 1)) : null,
        history: [
          ReviewHistoryModel(
            action: 'Khách gửi đánh giá',
            actor: names[i % 6],
            note: 'Đã mua sản phẩm',
            createdAt: date,
          ),
          if (hidden)
            ReviewHistoryModel(
              action: 'Ẩn đánh giá',
              actor: 'CSKH mẫu',
              note: 'Quảng cáo không liên quan',
              createdAt: date.add(const Duration(hours: 1)),
            ),
          if (replied)
            ReviewHistoryModel(
              action: 'Trả lời khách hàng',
              actor: 'CSKH mẫu',
              note: 'Cảm ơn bạn đã tin tưởng Zella!',
              createdAt: date.add(const Duration(hours: 1)),
            ),
        ],
      );
    });
  }
}
