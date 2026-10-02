import 'models/analytics_models.dart';
import 'repositories/analytics_repository.dart';

class AnalyticsCalculations {
  static bool inside(DateTime? date, DateTime start, DateTime end) =>
      date != null &&
      !date.isBefore(start) &&
      date.isBefore(end.add(const Duration(days: 1)));
  static int sum<T>(Iterable<T> rows, int Function(T) value) =>
      rows.fold(0, (n, row) => n + value(row));
  static AnalyticsSummary summary(
    AnalyticsRepository data,
    DateTime start,
    DateTime end,
  ) {
    final created = data.orders.where((o) => inside(o.createdAt, start, end));
    final delivered = data.orders.where(
      (o) => inside(o.deliveredAt, start, end),
    );
    final received = data.returns.where(
      (r) => inside(r.receivedAt, start, end),
    );
    return AnalyticsSummary(
      grossGoods: sum(delivered, (o) => o.grossGoods),
      promotionDiscount: sum(delivered, (o) => o.promotionDiscount),
      voucherDiscount: sum(delivered, (o) => o.voucherDiscount),
      returnedGoods: sum(received, (r) => r.goodsRefund),
      cogs:
          sum(delivered, (o) => o.unitCost * o.quantity) -
          sum(received, (r) => r.costReversal),
      shipping: sum(delivered, (o) => o.shipping),
      cashIn: sum(
        data.orders.where((o) => inside(o.paidAt, start, end)),
        (o) => o.total,
      ),
      cashOut:
          sum(
            data.orders.where((o) => inside(o.cancelRefundAt, start, end)),
            (o) => o.total,
          ) +
          sum(
            data.returns.where((r) => inside(r.refundedAt, start, end)),
            (r) => r.goodsRefund,
          ),
      createdOrders: created.length,
      deliveredOrders: delivered.length,
      cancelledOrders: created.where((o) => o.status == 'CANCELLED').length,
      soldQuantity:
          sum(delivered, (o) => o.quantity) - sum(received, (r) => r.quantity),
    );
  }
}
