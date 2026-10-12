import '../models/analytics_models.dart';

class AnalyticsRepository {
  final DateTime today;
  late final List<AnalyticsOrder> orders;
  late final List<AnalyticsReturn> returns;
  late final List<AnalyticsReceipt> receipts;
  static const products = [
    AnalyticsProduct(
      1,
      'Áo sơ mi nữ lụa cổ nơ',
      'Áo nữ',
      'SMN-BLK-M',
      'May Việt',
      490000,
      220000,
      35,
      6,
    ),
    AnalyticsProduct(
      2,
      'Áo sơ mi nam Oxford',
      'Áo nam',
      'OXF-WHT-L',
      'May Việt',
      499000,
      230000,
      60,
      8,
    ),
    AnalyticsProduct(
      3,
      'Váy midi xếp ly',
      'Váy nữ',
      'MIDI-BEG-S',
      'Thời trang An',
      650000,
      310000,
      7,
      4,
    ),
    AnalyticsProduct(
      4,
      'Quần jeans nữ',
      'Quần nữ',
      'JEAN-BLU-M',
      'Thời trang An',
      550000,
      270000,
      0,
      0,
    ),
    AnalyticsProduct(
      5,
      'Áo thun nam basic',
      'Áo nam',
      'TEE-WHT-L',
      'Dệt Thành Công',
      250000,
      110000,
      120,
      10,
    ),
    AnalyticsProduct(
      6,
      'Quần tây nam',
      'Quần nam',
      'PANT-BLK-L',
      'Dệt Thành Công',
      590000,
      280000,
      5,
      2,
    ),
  ];
  AnalyticsRepository({DateTime? now})
    : today = DateTime(
        (now ?? DateTime.now()).year,
        (now ?? DateTime.now()).month,
        (now ?? DateTime.now()).day,
      ) {
    orders = [];
    for (var day = 89; day >= 0; day--) {
      for (var j = 0; j < 3; j++) {
        final id = (89 - day) * 3 + j + 1;
        final product = products[id % products.length];
        final created = today
            .subtract(Duration(days: day))
            .add(Duration(hours: 8 + j * 3));
        final cancelled = id % 9 == 0;
        final status = cancelled
            ? 'CANCELLED'
            : day == 0 && j == 0
            ? 'PENDING'
            : day < 2
            ? 'CONFIRMED'
            : day < 4
            ? 'SHIPPED'
            : 'DELIVERED';
        final paid = status != 'PENDING' && (!cancelled || id % 18 == 0);
        final quantity = id % 3 + 1;
        final promotion = id % 4 == 0;
        final voucher = id % 5 == 0;
        final guest = id % 4 == 0;
        orders.add(
          AnalyticsOrder(
            id: id,
            productId: product.id,
            quantity: quantity,
            listPrice: product.price,
            soldPrice: promotion ? product.price * 9 ~/ 10 : product.price,
            unitCost: product.cost,
            voucherDiscount: voucher ? 10000 * quantity : 0,
            shipping: 30000,
            code: 'ORD-DEMO-${id.toString().padLeft(4, '0')}',
            status: status,
            paymentStatus: cancelled
                ? paid
                      ? 'REFUNDED'
                      : 'EXPIRED'
                : paid
                ? 'PAID'
                : 'PENDING',
            buyerKey: '${guest ? 'guest' : 'member'}-${id % 17}',
            buyerName: guest
                ? 'Khách vãng lai ${id % 17 + 1}'
                : 'Khách hàng ${id % 17 + 1}',
            guest: guest,
            createdAt: created,
            voucher: voucher ? 'SAVE10K' : null,
            paidAt: paid ? created.add(const Duration(minutes: 2)) : null,
            deliveredAt: status == 'DELIVERED'
                ? created.add(const Duration(days: 2))
                : null,
            cancelRefundAt: cancelled && paid
                ? created.add(const Duration(hours: 1))
                : null,
          ),
        );
      }
    }
    returns = [
      for (final order in orders)
        if (order.deliveredAt != null &&
            order.id % 11 == 0 &&
            order.deliveredAt!
                .add(const Duration(days: 2))
                .isBefore(today.add(const Duration(days: 1))))
          AnalyticsReturn(
            order.id,
            order.productId,
            1,
            order.goods ~/ order.quantity,
            order.id.isEven ? order.unitCost : 0,
            order.deliveredAt!.add(const Duration(days: 2)),
            order.id % 3 == 0
                ? null
                : order.deliveredAt!.add(const Duration(days: 2, hours: 1)),
          ),
    ];
    receipts = List.generate(30, (i) {
      final total = 2000000 + i % 5 * 500000;
      final credit = i % 6 == 0 ? 200000 : 0;
      return AnalyticsReceipt(
        'GR-DEMO-${i + 1}',
        products[i % products.length].supplier,
        i % 10 == 0
            ? 'CANCELLED'
            : i % 7 == 0
            ? 'DRAFT'
            : 'POSTED',
        10 + i % 10,
        total,
        credit,
        (total - credit) * (i % 3 + 1) ~/ 3,
        today.subtract(Duration(days: i * 3)),
      );
    });
  }
}
