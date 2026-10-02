import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/models/analytics_models.dart';
import '../../data/repositories/analytics_repository.dart';
import '../providers/dashboard_provider.dart';

class AnalyticsCards extends StatelessWidget {
  final DashboardProvider provider;
  const AnalyticsCards({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final p = provider, s = provider.summary;
    final old = p.previous;
    final cards = switch (p.section) {
      AnalyticsSection.overview => [
        (
          label: 'Doanh thu thuần',
          value: reportMoney(s.netRevenue),
          help: 'Tiền hàng đã giao trừ giảm giá và hàng trả nhận trong kỳ; không gồm vận chuyển.',
          footer: p.compare
              ? p.growth(s.netRevenue, old.netRevenue)
              : 'Theo ngày giao / nhận trả',
          target: AnalyticsSection.revenue,
        ),
        (
          label: 'Đơn đặt trong kỳ',
          value: '${s.createdOrders}',
          help: 'Tất cả đơn tạo trong kỳ, gồm cả đơn chưa trả tiền và đã hủy.',
          footer: '${s.cancelRate.toStringAsFixed(1)}% đã hủy',
          target: AnalyticsSection.orders,
        ),
        (
          label: 'Lợi nhuận gộp',
          value: reportMoney(s.grossProfit),
          help: 'Doanh thu thuần hàng trừ giá vốn. Chưa trừ vận hành, thuế và chi phí vận chuyển.',
          footer: p.compare
              ? p.growth(s.grossProfit, old.grossProfit)
              : 'Chưa phải lợi nhuận ròng',
          target: AnalyticsSection.revenue,
        ),
        (
          label: 'Người mua trả tiền',
          value: '${p.purchasingBuyers}',
          help: 'Người mua có thanh toán trong kỳ, gồm khách vãng lai; đơn đã hoàn vẫn là giao dịch trả tiền.',
          footer: '${p.newBuyers} người mua mới trong bộ mẫu',
          target: AnalyticsSection.customers,
        ),
      ],
      AnalyticsSection.revenue => [
        (
          label: 'Doanh thu thuần hàng',
          value: reportMoney(s.netRevenue),
          help: 'Ghi nhận theo ngày giao/nhận trả, không theo ngày thanh toán.',
          footer: p.compare ? p.growth(s.netRevenue, old.netRevenue) : '',
          target: AnalyticsSection.revenue,
        ),
        (
          label: 'Thực thu từ khách',
          value: reportMoney(s.cashIn),
          help: 'Tổng tiền đã thu trong kỳ, gồm vận chuyển; có thể gồm đơn chưa giao hoặc sau đó hủy.',
          footer: 'Theo ngày thanh toán',
          target: AnalyticsSection.revenue,
        ),
        (
          label: 'Đã hoàn tiền',
          value: reportMoney(s.cashOut),
          help: 'Hoàn đơn hủy và hàng trả đã chi tiền trong kỳ; không tính yêu cầu hoàn chưa thực hiện.',
          footer: 'Theo ngày thực hoàn',
          target: AnalyticsSection.revenue,
        ),
        (
          label: 'Lợi nhuận gộp',
          value: reportMoney(s.grossProfit),
          help: 'Doanh thu thuần hàng − giá vốn; hàng trả nguyên vẹn đảo giá vốn, hàng hỏng không đảo.',
          footer: 'Chưa trừ chi phí vận hành',
          target: AnalyticsSection.revenue,
        ),
      ],
      AnalyticsSection.orders => [
        (
          label: 'Đơn đặt',
          value: '${s.createdOrders}',
          help: 'Đơn được tạo trong khoảng ngày đã chọn.',
          footer: 'Theo ngày đặt',
          target: AnalyticsSection.orders,
        ),
        (
          label: 'Đơn giao trong kỳ',
          value: '${s.deliveredOrders}',
          help: 'Giao thành công trong kỳ; có thể được tạo từ kỳ trước.',
          footer: 'Theo ngày giao',
          target: AnalyticsSection.orders,
        ),
        (
          label: 'Tỷ lệ hủy',
          value: '${s.cancelRate.toStringAsFixed(1)}%',
          help: 'Số đơn đã hủy trong nhóm đơn tạo trong kỳ / số đơn tạo trong kỳ. Trạng thái hiện tại.',
          footer: '${s.cancelledOrders} đơn đã hủy',
          target: AnalyticsSection.orders,
        ),
        (
          label: 'Giá trị đơn giao TB',
          value: reportMoney(s.averageOrder),
          help: 'Tiền hàng sau giảm giá / số đơn giao trong kỳ; trước hàng trả, không gồm vận chuyển.',
          footer: 'Trước giảm trừ hàng trả',
          target: AnalyticsSection.orders,
        ),
      ],
      AnalyticsSection.products => [
        (
          label: 'Doanh thu thuần hàng',
          value: reportMoney(s.netRevenue),
          help: 'Tổng toàn cửa hàng trong kỳ; bộ lọc danh mục chỉ tác động bảng bên dưới.',
          footer: 'Toàn cửa hàng',
          target: AnalyticsSection.products,
        ),
        (
          label: 'Số lượng bán ròng',
          value: '${s.soldQuantity}',
          help: 'SL đã giao trong kỳ − SL hàng trả nhận trong kỳ.',
          footer: 'Toàn cửa hàng',
          target: AnalyticsSection.products,
        ),
      ],
      AnalyticsSection.returns => [
        (
          label: 'Hàng trả đã nhận',
          value: reportMoney(s.returnedGoods),
          help: 'Giá trị tiền hàng trả nhận trong kỳ theo giá thực trả, không theo giá niêm yết.',
          footer: 'Theo ngày nhận trả',
          target: AnalyticsSection.returns,
        ),
        (
          label: 'Đảo giá vốn',
          value: reportMoney(
            p.data.returns
                .where(
                  (r) =>
                      !r.receivedAt.isBefore(p.start) &&
                      r.receivedAt.isBefore(p.end.add(const Duration(days: 1))),
                )
                .fold<int>(0, (n, r) => n + r.costReversal),
          ),
          help: 'Chỉ hàng nguyên vẹn nhập lại kho mới đảo giá vốn bán hàng.',
          footer: 'Hàng hỏng không đảo',
          target: AnalyticsSection.returns,
        ),
        (
          label: 'Phiếu chờ hoàn hiện tại',
          value: '${p.pendingRefunds}',
          help: 'Phiếu trả đã nhận nhưng chưa thực hoàn, trên toàn bộ bộ mẫu.',
          footer: 'Không lọc theo ngày',
          target: AnalyticsSection.returns,
        ),
      ],
      AnalyticsSection.inventory => [
        (
          label: 'Tồn vật lý',
          value:
              '${AnalyticsRepository.products.fold<int>(0, (n, r) => n + r.stock)}',
          help: 'Tồn hiện tại gồm cả hàng đang giữ.',
          footer: 'Hiện tại • Không lọc theo ngày',
          target: AnalyticsSection.inventory,
        ),
        (
          label: 'Đang giữ',
          value:
              '${AnalyticsRepository.products.fold<int>(0, (n, r) => n + r.reserved)}',
          help: 'Hàng giữ cho đơn đang chờ thanh toán/chuẩn bị giao.',
          footer: 'Hiện tại',
          target: AnalyticsSection.inventory,
        ),
        (
          label: 'Giá trị tồn kho',
          value: reportMoney(p.stockValue),
          help: 'Tồn vật lý × giá vốn bình quân hiện tại. Không dùng giá bán.',
          footer: 'Toàn bộ SKU mẫu',
          target: AnalyticsSection.inventory,
        ),
        (
          label: 'SKU cần nhập thêm',
          value: '${p.lowStock}',
          help: 'Có thể bán ≤ 5, bao gồm SKU hết hàng.',
          footer: 'Ngưỡng cảnh báo mẫu: 5',
          target: AnalyticsSection.inventory,
        ),
      ],
      AnalyticsSection.customers => [
        (
          label: 'Người mua trong kỳ',
          value: '${p.purchasingBuyers}',
          help: 'Người mua duy nhất có giao dịch thanh toán trong kỳ.',
          footer: 'Gồm khách vãng lai',
          target: AnalyticsSection.customers,
        ),
        (
          label: 'Người mua mới',
          value: '${p.newBuyers}',
          help:
              'Lần thanh toán đầu tiên thuộc kỳ chọn trong bộ dữ liệu 90 ngày.',
          footer: 'Chưa phải lịch sử trọn đời',
          target: AnalyticsSection.customers,
        ),
        (
          label: 'Người mua quay lại',
          value: '${p.purchasingBuyers - p.newBuyers}',
          help:
              'Người mua trong kỳ đã có lần thanh toán trước kỳ trong bộ mẫu.',
          footer: 'Không phải số tài khoản đăng ký',
          target: AnalyticsSection.customers,
        ),
      ],
      AnalyticsSection.purchases => [
        (
          label: 'Nhập ròng trong kỳ',
          value: reportMoney(p.postedValue),
          help: 'Giá trị phiếu POSTED trong kỳ trừ khoản trả NCC hiện tại của các phiếu đó. Không tính nháp/hủy.',
          footer: 'Giá trị ròng của nhóm phiếu',
          target: AnalyticsSection.purchases,
        ),
        (
          label: 'Công nợ NCC hiện tại',
          value: reportMoney(p.currentDebt),
          help: 'Toàn bộ phiếu nhập đã ghi sổ: tổng − trả NCC − đã thanh toán, tối thiểu 0.',
          footer: 'Không phụ thuộc khoảng ngày',
          target: AnalyticsSection.purchases,
        ),
      ],
      AnalyticsSection.promotions => [
        (
          label: 'Giảm bằng voucher',
          value: reportMoney(s.voucherDiscount),
          help: 'Giảm voucher trên các đơn giao trong kỳ, trước đảo hàng trả.',
          footer: 'Theo ngày giao',
          target: AnalyticsSection.promotions,
        ),
        (
          label: 'Giảm giá sản phẩm',
          value: reportMoney(s.promotionDiscount),
          help: 'Chênh lệch giá niêm yết và giá bán sau khuyến mãi của các đơn giao.',
          footer: 'Theo snapshot giá lúc đặt',
          target: AnalyticsSection.promotions,
        ),
      ],
    };
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 1200
            ? 4
            : c.maxWidth >= 650
            ? 2
            : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: (c.maxWidth - (columns - 1) * 16) / columns,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => p.setSection(card.target),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  card.label,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: card.help,
                                child: const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            card.value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            card.footer,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
