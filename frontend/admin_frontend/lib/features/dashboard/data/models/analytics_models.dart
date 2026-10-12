import 'package:intl/intl.dart';

enum AnalyticsSection {
  overview('Tổng quan'),
  revenue('Doanh thu'),
  orders('Đơn hàng'),
  returns('Trả hàng'),
  products('Sản phẩm'),
  inventory('Kho'),
  customers('Khách hàng'),
  purchases('Nhập hàng'),
  promotions('Ưu đãi');

  const AnalyticsSection(this.label);
  final String label;
}

enum AnalyticsPeriod {
  today('Hôm nay'),
  week('7 ngày'),
  month('30 ngày'),
  quarter('90 ngày'),
  custom('Tùy chọn');

  const AnalyticsPeriod(this.label);
  final String label;
}

String reportMoney(int value) =>
    '${NumberFormat.decimalPattern('vi').format(value)} đ';
String reportDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
String orderStatusLabel(String status) =>
    const {
      'PENDING': 'Chờ thanh toán',
      'CONFIRMED': 'Đã thanh toán',
      'SHIPPED': 'Đang giao',
      'DELIVERED': 'Đã giao',
      'CANCELLED': 'Đã hủy',
    }[status] ??
    status;

/// Read models over existing business entities. No new backend entities implied.
class AnalyticsProduct {
  final int id, price, cost, stock, reserved;
  final String name, category, sku, supplier;
  const AnalyticsProduct(
    this.id,
    this.name,
    this.category,
    this.sku,
    this.supplier,
    this.price,
    this.cost,
    this.stock,
    this.reserved,
  );
  int get available => stock - reserved;
}

class AnalyticsOrder {
  final int id,
      productId,
      quantity,
      listPrice,
      soldPrice,
      unitCost,
      voucherDiscount,
      shipping;
  final String code, status, paymentStatus, buyerKey, buyerName;
  final String? voucher;
  final bool guest;
  final DateTime createdAt;
  final DateTime? paidAt, deliveredAt, cancelRefundAt;
  const AnalyticsOrder({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.listPrice,
    required this.soldPrice,
    required this.unitCost,
    required this.voucherDiscount,
    required this.shipping,
    required this.code,
    required this.status,
    required this.paymentStatus,
    required this.buyerKey,
    required this.buyerName,
    required this.guest,
    required this.createdAt,
    this.voucher,
    this.paidAt,
    this.deliveredAt,
    this.cancelRefundAt,
  });
  int get grossGoods => listPrice * quantity;
  int get promotionDiscount => (listPrice - soldPrice) * quantity;
  int get goods => soldPrice * quantity - voucherDiscount;
  int get total => goods + shipping;
}

class AnalyticsReturn {
  final int orderId, productId, quantity, goodsRefund, costReversal;
  final DateTime receivedAt;
  final DateTime? refundedAt;
  const AnalyticsReturn(
    this.orderId,
    this.productId,
    this.quantity,
    this.goodsRefund,
    this.costReversal,
    this.receivedAt,
    this.refundedAt,
  );
}

class AnalyticsReceipt {
  final String code, supplier, status;
  final int quantity, total, credit, paid;
  final DateTime postedAt;
  const AnalyticsReceipt(
    this.code,
    this.supplier,
    this.status,
    this.quantity,
    this.total,
    this.credit,
    this.paid,
    this.postedAt,
  );
  int get debt =>
      status == 'POSTED' ? (total - credit - paid).clamp(0, total) : 0;
}

class AnalyticsSummary {
  final int grossGoods,
      promotionDiscount,
      voucherDiscount,
      returnedGoods,
      cogs,
      shipping,
      cashIn,
      cashOut,
      createdOrders,
      deliveredOrders,
      cancelledOrders,
      soldQuantity;
  const AnalyticsSummary({
    required this.grossGoods,
    required this.promotionDiscount,
    required this.voucherDiscount,
    required this.returnedGoods,
    required this.cogs,
    required this.shipping,
    required this.cashIn,
    required this.cashOut,
    required this.createdOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.soldQuantity,
  });
  int get netRevenue =>
      grossGoods - promotionDiscount - voucherDiscount - returnedGoods;
  int get grossProfit => netRevenue - cogs;
  double get cancelRate =>
      createdOrders == 0 ? 0 : cancelledOrders * 100 / createdOrders;
  int get averageOrder => deliveredOrders == 0
      ? 0
      : ((grossGoods - promotionDiscount - voucherDiscount) / deliveredOrders)
            .round();
}

class AnalyticsTableData {
  final List<String> columns;
  final List<List<String>> rows;
  final String note;
  const AnalyticsTableData(this.columns, this.rows, this.note);
}
