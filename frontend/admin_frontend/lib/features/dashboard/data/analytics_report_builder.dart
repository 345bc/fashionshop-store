import 'analytics_calculations.dart';
import 'models/analytics_models.dart';
import 'repositories/analytics_repository.dart';

class AnalyticsReportBuilder {
  final AnalyticsRepository data;
  final DateTime start, end;
  final String query;
  final String? category, status;
  const AnalyticsReportBuilder(
    this.data,
    this.start,
    this.end, {
    this.query = '',
    this.category,
    this.status,
  });
  bool _inside(DateTime? date) =>
      AnalyticsCalculations.inside(date, start, end);
  AnalyticsTableData build(AnalyticsSection section) {
    final table = switch (section) {
      AnalyticsSection.overview => _overview(),
      AnalyticsSection.orders => _orders(),
      AnalyticsSection.revenue => _revenue(),
      AnalyticsSection.returns => _returns(),
      AnalyticsSection.products => _products(),
      AnalyticsSection.inventory => _inventory(),
      AnalyticsSection.customers => _customers(),
      AnalyticsSection.purchases => _purchases(),
      AnalyticsSection.promotions => _promotions(),
    };
    return AnalyticsTableData(
      table.columns,
      table.rows
          .where(
            (row) => row
                .join(' ')
                .toLowerCase()
                .contains(query.trim().toLowerCase()),
          )
          .toList(),
      table.note,
    );
  }

  AnalyticsTableData _orders() {
    final orders =
        data.orders
            .where(
              (o) =>
                  _inside(o.createdAt) &&
                  (status == null || o.status == status),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AnalyticsTableData(
      [
        'Mã đơn',
        'Khách hàng',
        'Ngày đặt',
        'Tổng tiền',
        'Trạng thái',
        'Thanh toán',
      ],
      [
        for (final o in orders)
          [
            o.code,
            o.buyerName,
            reportDate(o.createdAt),
            reportMoney(o.total),
            orderStatusLabel(o.status),
            const {
                  'PAID': 'Đã thu tiền',
                  'PENDING': 'Chưa thanh toán',
                  'EXPIRED': 'Hết hạn thanh toán',
                  'REFUNDED': 'Đã hoàn tiền',
                }[o.paymentStatus] ??
                o.paymentStatus,
          ],
      ],
      'Đơn tạo trong kỳ, hiển thị trạng thái hiện tại. Đơn chưa thanh toán/đã hủy không được tính doanh thu.',
    );
  }

  AnalyticsTableData _overview() {
    final s = AnalyticsCalculations.summary(data, start, end);
    final buyers = data.orders
        .where((o) => _inside(o.paidAt))
        .map((o) => o.buyerKey)
        .toSet()
        .length;
    return AnalyticsTableData(
      ['Chỉ số', 'Giá trị'],
      [
        ['Doanh thu thuần hàng', reportMoney(s.netRevenue)],
        ['Đơn đặt trong kỳ', '${s.createdOrders}'],
        ['Lợi nhuận gộp', reportMoney(s.grossProfit)],
        ['Người mua trả tiền', '$buyers'],
      ],
      'Tổng quan trong kỳ; doanh thu/lợi nhuận không gồm vận chuyển. Xem các tab để có chi tiết.',
    );
  }

  AnalyticsTableData _revenue() => AnalyticsTableData(
    [
      'Ngày',
      'Doanh thu thuần hàng',
      'Giá vốn',
      'Lợi nhuận gộp',
      'Thu từ khách',
      'Đã hoàn tiền',
    ],
    [
      for (var i = end.difference(start).inDays; i >= 0; i--)
        _daily(start.add(Duration(days: i))),
    ],
    'Doanh thu theo ngày giao; giảm trừ hàng trả theo ngày nhận trả. Thu/hoàn theo ngày tiền thực thu/hoàn. Phí vận chuyển tách riêng.',
  );
  List<String> _daily(DateTime day) {
    final s = AnalyticsCalculations.summary(data, day, day);
    return [
      reportDate(day),
      reportMoney(s.netRevenue),
      reportMoney(s.cogs),
      reportMoney(s.grossProfit),
      reportMoney(s.cashIn),
      reportMoney(s.cashOut),
    ];
  }

  AnalyticsTableData _products() {
    final rows = <({int revenue, List<String> cells})>[];
    for (final product in AnalyticsRepository.products) {
      if (category != null && product.category != category) continue;
      final sold = data.orders.where(
        (o) => o.productId == product.id && _inside(o.deliveredAt),
      );
      final returns = data.returns.where(
        (r) => r.productId == product.id && _inside(r.receivedAt),
      );
      if (sold.isEmpty && returns.isEmpty) continue;
      final revenue =
          AnalyticsCalculations.sum(sold, (o) => o.goods) -
          AnalyticsCalculations.sum(returns, (r) => r.goodsRefund);
      final cost =
          AnalyticsCalculations.sum(sold, (o) => o.unitCost * o.quantity) -
          AnalyticsCalculations.sum(returns, (r) => r.costReversal);
      rows.add((
        revenue: revenue,
        cells: [
          product.name,
          product.sku,
          product.category,
          '${AnalyticsCalculations.sum(sold, (o) => o.quantity) - AnalyticsCalculations.sum(returns, (r) => r.quantity)}',
          reportMoney(revenue),
          reportMoney(cost),
          reportMoney(revenue - cost),
          '${AnalyticsCalculations.sum(returns, (r) => r.quantity)}',
        ],
      ));
    }
    rows.sort((a, b) => b.revenue.compareTo(a.revenue));
    return AnalyticsTableData(
      [
        'Sản phẩm',
        'SKU',
        'Danh mục',
        'SL bán ròng',
        'Doanh thu thuần',
        'Giá vốn',
        'Lợi nhuận gộp',
        'SL trả',
      ],
      rows.map((r) => r.cells).toList(),
      'Xếp theo doanh thu thuần. Hàng trả nhận trong kỳ có thể thuộc đơn giao ở kỳ trước; số ròng có thể âm.',
    );
  }

  AnalyticsTableData _returns() {
    final returns = data.returns.where((r) => _inside(r.receivedAt)).toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return AnalyticsTableData(
      [
        'Đơn gốc',
        'Sản phẩm',
        'Ngày nhận trả',
        'SL trả',
        'Tình trạng',
        'Tiền hoàn hàng',
        'Hoàn tiền',
      ],
      [
        for (final r in returns)
          [
            data.orders.firstWhere((o) => o.id == r.orderId).code,
            AnalyticsRepository.products
                .firstWhere((p) => p.id == r.productId)
                .name,
            reportDate(r.receivedAt),
            '${r.quantity}',
            r.costReversal > 0
                ? 'Nguyên vẹn / nhập lại kho'
                : 'Hỏng / không nhập kho bán',
            reportMoney(r.goodsRefund),
            r.refundedAt == null
                ? 'Chờ hoàn'
                : 'Đã hoàn ${reportDate(r.refundedAt!)}',
          ],
      ],
      'Hàng trả đã nhận trong kỳ. Trạng thái hoàn tiền hiện tại; thẻ Đã hoàn tiền của Doanh thu tính theo ngày thực hoàn, không theo ngày nhận trả.',
    );
  }

  AnalyticsTableData _inventory() {
    final products =
        AnalyticsRepository.products
            .where((p) => category == null || p.category == category)
            .toList()
          ..sort((a, b) => a.available.compareTo(b.available));
    return AnalyticsTableData(
      [
        'Sản phẩm / SKU',
        'Tồn',
        'Đã giữ',
        'Có thể bán',
        'Giá vốn / đơn vị',
        'Giá trị tồn',
        'Cảnh báo',
      ],
      [
        for (final p in products)
          [
            '${p.name}\n${p.sku}',
            '${p.stock}',
            '${p.reserved}',
            '${p.available}',
            reportMoney(p.cost),
            reportMoney(p.cost * p.stock),
            p.available == 0
                ? 'Hết hàng'
                : p.available <= 5
                ? 'Sắp hết (≤ 5)'
                : 'Đủ hàng',
          ],
      ],
      'Ảnh chụp tồn kho hiện tại, không phụ thuộc khoảng ngày. Giá trị tồn = tồn vật lý × giá vốn bình quân; hàng giữ vẫn thuộc tồn vật lý.',
    );
  }

  AnalyticsTableData _customers() {
    final rows = <({int revenue, List<String> cells})>[];
    for (final key in data.orders.map((o) => o.buyerKey).toSet()) {
      final buyerOrders = data.orders.where((o) => o.buyerKey == key);
      final paid = buyerOrders.where((o) => _inside(o.paidAt));
      final delivered = buyerOrders.where((o) => _inside(o.deliveredAt));
      final ids = buyerOrders.map((o) => o.id).toSet();
      final returns = data.returns.where(
        (r) => ids.contains(r.orderId) && _inside(r.receivedAt),
      );
      if (paid.isEmpty && delivered.isEmpty && returns.isEmpty) continue;
      final revenue =
          AnalyticsCalculations.sum(delivered, (o) => o.goods) -
          AnalyticsCalculations.sum(returns, (r) => r.goodsRefund);
      final first = buyerOrders
          .where((o) => o.paidAt != null)
          .map((o) => o.paidAt!)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      rows.add((
        revenue: revenue,
        cells: [
          buyerOrders.first.buyerName,
          buyerOrders.first.guest ? 'Vãng lai' : 'Có tài khoản',
          _inside(first) ? 'Mới trong kỳ' : 'Đã mua trước kỳ',
          '${paid.length}',
          '${delivered.length}',
          reportMoney(revenue),
        ],
      ));
    }
    rows.sort((a, b) => b.revenue.compareTo(a.revenue));
    return AnalyticsTableData(
      [
        'Người mua',
        'Loại khách',
        'Nhóm khách',
        'Đơn đã trả tiền',
        'Đơn đã giao',
        'Doanh thu thuần',
      ],
      rows.map((r) => r.cells).toList(),
      'Người mua gồm khách vãng lai; khách mới theo lần trả tiền đầu tiên trong bộ mẫu 90 ngày, chưa phải lịch sử trọn đời.',
    );
  }

  AnalyticsTableData _purchases() {
    final receipts = data.receipts.where((r) => _inside(r.postedAt)).toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return AnalyticsTableData(
      [
        'Phiếu nhập',
        'Nhà cung cấp',
        'Ngày phiếu',
        'Trạng thái',
        'Giá trị phiếu',
        'Trả NCC',
        'Đã trả tiền',
        'Còn nợ',
      ],
      [
        for (final r in receipts)
          [
            r.code,
            r.supplier,
            reportDate(r.postedAt),
            const {
              'POSTED': 'Đã nhập kho',
              'DRAFT': 'Nháp',
              'CANCELLED': 'Đã hủy',
            }[r.status]!,
            reportMoney(r.total),
            reportMoney(r.credit),
            reportMoney(r.paid),
            reportMoney(r.debt),
          ],
      ],
      'Chỉ phiếu POSTED tính vào tổng nhập. Khoản đã trả/còn nợ là số hiện tại của phiếu, không phải dòng tiền chi trong kỳ.',
    );
  }

  AnalyticsTableData _promotions() {
    final delivered = data.orders.where((o) => _inside(o.deliveredAt));
    return AnalyticsTableData(
      [
        'Ưu đãi',
        'Loại',
        'Đơn đã giao áp dụng',
        'Tiền giảm trên đơn giao',
        'Đơn trả tiền dùng mã',
      ],
      [
        [
          'SAVE10K',
          'Voucher',
          '${delivered.where((o) => o.voucher != null).length}',
          reportMoney(
            AnalyticsCalculations.sum(delivered, (o) => o.voucherDiscount),
          ),
          '${data.orders.where((o) => o.voucher != null && _inside(o.paidAt)).length}',
        ],
        [
          'Ưu đãi sản phẩm 10%',
          'Khuyến mãi sản phẩm',
          '${delivered.where((o) => o.promotionDiscount > 0).length}',
          reportMoney(
            AnalyticsCalculations.sum(delivered, (o) => o.promotionDiscount),
          ),
          '—',
        ],
      ],
      'Đếm từng loại ưu đãi riêng; một đơn có thể dùng cả hai nên không cộng số đơn giữa các dòng. Tiền giảm là snapshot trên đơn giao, chưa đảo giảm theo hàng trả.',
    );
  }
}
