enum ReviewVisibility {
  visible('Đang hiển thị'),
  hidden('Đã ẩn');

  const ReviewVisibility(this.label);
  final String label;
}

class ReviewHistoryModel {
  final String action, actor, note;
  final DateTime createdAt;
  const ReviewHistoryModel({
    required this.action,
    required this.actor,
    required this.note,
    required this.createdAt,
  });
}

/// Review response shared by the live API and explicit demo fixtures.
class ProductReviewModel {
  final int id, productId, orderId, orderItemId, rating;
  final int? customerId;
  final String customerName,
      customerEmail,
      productName,
      sku,
      orderCode,
      comment;
  final DateTime createdAt;
  final ReviewVisibility visibility;
  final String? adminReply, moderationReason;
  final DateTime? repliedAt;
  final int parentId, categoryId;
  final String parent, category;
  final List<ReviewHistoryModel> history;

  const ProductReviewModel({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.orderItemId,
    this.customerId,
    required this.rating,
    required this.customerName,
    required this.customerEmail,
    required this.productName,
    required this.sku,
    required this.orderCode,
    required this.comment,
    required this.createdAt,
    this.visibility = ReviewVisibility.visible,
    this.adminReply,
    this.moderationReason,
    this.repliedAt,
    this.parentId = 0,
    this.categoryId = 0,
    this.parent = '',
    this.category = '',
    this.history = const [],
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> j) =>
      ProductReviewModel(
        id: j['id'],
        productId: j['productId'],
        orderId: j['orderId'],
        orderItemId: j['orderItemId'],
        customerId: j['customerId'],
        rating: j['rating'],
        customerName: j['customerName'] ?? 'Khách hàng',
        customerEmail: j['customerEmail'] ?? '',
        productName: j['productName'] ?? '',
        sku: j['sku'] ?? '',
        orderCode: j['orderCode'] ?? '',
        comment: j['comment'] ?? '',
        createdAt: DateTime.parse(j['createdAt']),
        visibility: j['hidden'] == true
            ? ReviewVisibility.hidden
            : ReviewVisibility.visible,
        adminReply: j['adminReply'],
        moderationReason: j['moderationReason'],
        repliedAt: j['repliedAt'] == null
            ? null
            : DateTime.parse(j['repliedAt']),
        parentId: j['parentId'],
        categoryId: j['categoryId'],
        parent: j['parent'] ?? '',
        category: j['category'] ?? '',
        history: (j['history'] as List? ?? [])
            .map(
              (h) => ReviewHistoryModel(
                action: h['action'],
                actor: h['actor'],
                note: h['note'],
                createdAt: DateTime.parse(h['createdAt']),
              ),
            )
            .toList(),
      );

  ProductReviewModel reply(String text, String actor) {
    final now = DateTime.now();
    return _copy(
      adminReply: text,
      repliedAt: now,
      history: [
        ...history,
        ReviewHistoryModel(
          action: adminReply == null
              ? 'Trả lời khách hàng'
              : 'Cập nhật câu trả lời',
          actor: actor,
          note: text,
          createdAt: now,
        ),
      ],
    );
  }

  ProductReviewModel moderate(
    ReviewVisibility value,
    String reason,
    String actor,
  ) => _copy(
    visibility: value,
    moderationReason: reason,
    history: [
      ...history,
      ReviewHistoryModel(
        action: value == ReviewVisibility.hidden
            ? 'Ẩn đánh giá'
            : 'Hiển thị lại đánh giá',
        actor: actor,
        note: reason,
        createdAt: DateTime.now(),
      ),
    ],
  );

  ProductReviewModel _copy({
    String? adminReply,
    DateTime? repliedAt,
    ReviewVisibility? visibility,
    String? moderationReason,
    required List<ReviewHistoryModel> history,
  }) => ProductReviewModel(
    parentId: parentId,
    categoryId: categoryId,
    parent: parent,
    category: category,
    id: id,
    productId: productId,
    orderId: orderId,
    orderItemId: orderItemId,
    customerId: customerId,
    rating: rating,
    customerName: customerName,
    customerEmail: customerEmail,
    productName: productName,
    sku: sku,
    orderCode: orderCode,
    comment: comment,
    createdAt: createdAt,
    visibility: visibility ?? this.visibility,
    adminReply: adminReply ?? this.adminReply,
    repliedAt: repliedAt ?? this.repliedAt,
    moderationReason: moderationReason ?? this.moderationReason,
    history: history,
  );
}
