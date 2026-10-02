import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/analytics_calculations.dart';
import '../../data/models/analytics_models.dart';
import '../providers/dashboard_provider.dart';

class AnalyticsPanels extends StatelessWidget {
  final DashboardProvider provider;
  const AnalyticsPanels({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final p = provider, s = p.summary;
    return switch (p.section) {
      AnalyticsSection.overview => const SizedBox.shrink(),
      AnalyticsSection.revenue => _card(
        'Đối chiếu doanh thu & thu tiền',
        Column(
          children: [
            _amount('Tiền hàng trước giảm giá', s.grossGoods),
            _amount('− Khuyến mãi sản phẩm', s.promotionDiscount),
            _amount('− Voucher', s.voucherDiscount),
            _amount('− Hàng trả đã nhận', s.returnedGoods),
            const Divider(),
            _amount('= Doanh thu thuần hàng', s.netRevenue),
            _amount('− Giá vốn ròng', s.cogs),
            _amount('= Lợi nhuận gộp', s.grossProfit),
            const Divider(),
            _amount('Phí vận chuyển trên đơn giao (tách riêng)', s.shipping),
            _amount('Tiền thu khách − tiền đã hoàn', s.cashIn - s.cashOut),
          ],
        ),
        note: 'Tiền thu sau hoàn không phải lợi nhuận hoặc số dư quỹ: chưa trừ thanh toán NCC và chi phí vận hành.',
      ),
      AnalyticsSection.orders => _orderDistribution(p),
      AnalyticsSection.products => _card(
        'Đọc báo cáo sản phẩm',
        const Text(
          'Xếp hạng theo doanh thu thuần. Bảng phản ánh số lượng giao trừ hàng trả nhận trong kỳ. '
          'Danh mục lọc bảng; các thẻ phía trên vẫn là tổng toàn cửa hàng. Nhấp một dòng để xem các số đầy đủ.',
        ),
      ),
      AnalyticsSection.returns => _card(
        'Trả hàng & hoàn tiền',
        const Text(
          'Nhận hàng trả và hoàn tiền là hai thời điểm khác nhau. Hàng nguyên vẹn tăng kho và đảo giá vốn; '
          'hàng hỏng không vào kho có thể bán. Hoàn theo tiền thực trả đã phân bổ giảm giá, không theo giá gốc.',
        ),
      ),
      AnalyticsSection.inventory => _card(
        'Tồn kho & khả năng bán',
        const Text(
          'Có thể bán = tồn vật lý − hàng đã giữ. SKU có thể bán bằng 0 là hết hàng; từ 1 đến 5 cần cân nhắc nhập thêm. '
          'Giá trị tồn dùng giá vốn hiện tại. Chưa có báo cáo tồn theo ngày hoặc vòng quay kho vì cần dữ liệu lịch sử đầy đủ.',
        ),
      ),
      AnalyticsSection.customers => _card(
        'Nhận diện người mua',
        const Text(
          'Khách vãng lai vẫn được thống kê. Không coi mỗi đơn vãng lai là một người mới. '
          'Bộ mẫu dùng khóa người mua ổn định; khi nối BE cần nhận diện người mua hợp lệ và toàn bộ lịch sử để phân loại mới/quay lại.',
        ),
      ),
      AnalyticsSection.purchases => _card(
        'Công nợ & nhập hàng',
        Column(
          children: [
            _amount('Công nợ toàn bộ NCC hiện tại', p.currentDebt),
            const Text(
              'Phiếu nháp/hủy không tăng kho hoặc công nợ. Trả NCC giảm giá trị phải trả. '
              'Số đã thanh toán trên phiếu là số lũy kế hiện tại; không dùng làm chi tiền trong khoảng ngày chọn.',
            ),
          ],
        ),
      ),
      AnalyticsSection.promotions => _card(
        'Đánh giá ưu đãi',
        const Text(
          'Theo dõi mức giảm trên đơn đã giao và lượt mã trên đơn trả tiền. Một đơn có thể dùng voucher cùng khuyến mãi sản phẩm. '
          'Các số này không chứng minh chương trình làm tăng doanh thu; muốn đo hiệu quả cần nhóm so sánh phù hợp.',
        ),
      ),
    };
  }

  Widget _amount(String title, int amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 24,
      runSpacing: 6,
      children: [
        Text(title),
        Text(
          reportMoney(amount),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
  Widget _card(String title, Widget child, {String? note}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppTheme.borderLight),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        child,
        if (note != null) ...[
          const SizedBox(height: 12),
          Text(
            note,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    ),
  );
  Widget _orderDistribution(DashboardProvider p) {
    final orders = p.data.orders.where(
      (o) => AnalyticsCalculations.inside(o.createdAt, p.start, p.end),
    );
    return _card(
      'Đơn tạo trong kỳ theo trạng thái hiện tại',
      Column(
        children: [
          for (final state in [
            'PENDING',
            'CONFIRMED',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => p.setOrderStatus(state),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${orderStatusLabel(state)} • ${orders.where((o) => o.status == state).length} đơn',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      value: orders.isEmpty
                          ? 0
                          : orders.where((o) => o.status == state).length /
                                orders.length,
                      backgroundColor: AppTheme.surface,
                      color: state == 'CANCELLED'
                          ? AppTheme.danger
                          : AppTheme.info,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      note: 'Nhấp trạng thái để lọc bảng. Đơn giao trong kỳ ở thẻ KPI là nhóm theo ngày giao nên có thể khác nhóm này.',
    );
  }
}
