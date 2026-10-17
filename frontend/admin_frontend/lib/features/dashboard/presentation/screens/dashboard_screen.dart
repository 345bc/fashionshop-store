import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../data/models/analytics_models.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/analytics_filters.dart';
import '../widgets/revenue_chart.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<String>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<DashboardProvider>();
      // Reports share this provider: always clear their filters on returning.
      if (p.section != AnalyticsSection.overview ||
          p.query.isNotEmpty ||
          p.category != null ||
          p.orderStatus != null) {
        p.setSection(AnalyticsSection.overview);
      } else {
        p.load();
      }
    });
  }

  Widget _panel({required Widget child}) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppTheme.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  );

  Widget _title(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final s = p.summary, old = p.previous;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          key: const PageStorageKey('dashboard-overview'),
          padding: EdgeInsets.all(constraints.maxWidth < 700 ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng quan kinh doanh',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.isDemo
                            ? 'Dữ liệu mẫu • Không phải số liệu vận hành thực tế'
                            : 'Kết quả kinh doanh và những việc cần theo dõi trong cửa hàng.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: p.loading ? null : p.load,
                        icon: const Icon(Symbols.refresh, size: 18),
                        label: const Text('Làm mới'),
                      ),
                      FilledButton.icon(
                        onPressed: widget.onNavigate == null
                            ? null
                            : () => widget.onNavigate!('/reports'),
                        icon: const Icon(Symbols.analytics, size: 18),
                        label: const Text('Xem báo cáo'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _panel(child: AnalyticsFilters(provider: p)),
              const SizedBox(height: 24),
              if (p.loading) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 20),
                const Text(
                  'Đang cập nhật số liệu…',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ] else if (p.error != null)
                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title('Chưa tải được tổng quan', p.error!),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: p.load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              if (p.ready && p.section == AnalyticsSection.overview) ...[
                LayoutBuilder(
                  builder: (context, box) {
                    final columns = box.maxWidth >= 1100
                        ? 4
                        : box.maxWidth >= 580
                        ? 2
                        : 1;
                    final cards = [
                      (
                        label: 'Doanh thu thuần',
                        value: reportMoney(s.netRevenue),
                        note: p.compare
                            ? p.growth(s.netRevenue, old.netRevenue)
                            : 'Theo ngày giao / nhận trả',
                        help: 'Tiền hàng đã giao trừ giảm giá và hàng trả nhận trong kỳ. Không gồm vận chuyển.',
                        accent: true,
                      ),
                      (
                        label: 'Lợi nhuận gộp',
                        value: reportMoney(s.grossProfit),
                        note: p.compare
                            ? p.growth(s.grossProfit, old.grossProfit)
                            : 'Chưa trừ chi phí vận hành',
                        help: 'Doanh thu thuần trừ giá vốn; chưa phải lợi nhuận ròng.',
                        accent: false,
                      ),
                      (
                        label: 'Đơn giao thành công',
                        value: '${s.deliveredOrders}',
                        note: p.compare
                            ? p.growth(s.deliveredOrders, old.deliveredOrders)
                            : 'Theo ngày giao thành công',
                        help: 'Đơn giao thành công trong kỳ, có thể được đặt ở kỳ trước.',
                        accent: false,
                      ),
                      (
                        label: 'Giá trị đơn giao TB',
                        value: reportMoney(s.averageOrder),
                        note: 'Tiền hàng sau giảm giá, trước trả hàng',
                        help: 'Tiền hàng của đơn giao trong kỳ / số đơn giao; không gồm phí vận chuyển.',
                        accent: false,
                      ),
                    ];
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final card in cards)
                          SizedBox(
                            width:
                                (box.maxWidth - (columns - 1) * 16) / columns,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: card.accent
                                    ? const Color(0xFF243E39)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: card.accent
                                      ? const Color(0xFF243E39)
                                      : AppTheme.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          card.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: card.accent
                                                ? Colors.white70
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Tooltip(
                                        message: card.help,
                                        child: Icon(
                                          Symbols.info,
                                          size: 16,
                                          color: card.accent
                                              ? Colors.white70
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      card.value,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: card.accent
                                            ? Colors.white
                                            : AppTheme.text,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    card.note,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: card.accent
                                          ? Colors.white70
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                RevenueChart(provider: p),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, box) {
                    final operations = _operations(p);
                    final orders = _orders(p);
                    return box.maxWidth >= 960
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: operations),
                              const SizedBox(width: 24),
                              Expanded(flex: 4, child: orders),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              operations,
                              const SizedBox(height: 24),
                              orders,
                            ],
                          );
                  },
                ),
                if (p.warnings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _panel(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Lưu ý chất lượng dữ liệu',
                        style: TextStyle(fontSize: 14),
                      ),
                      leading: const Icon(
                        Symbols.info,
                        color: AppTheme.warning,
                      ),
                      children: [
                        for (final warning in p.warnings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              warning,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Doanh thu ghi nhận khi giao hàng; hoàn trả ghi nhận khi nhận hàng trả. Múi giờ Việt Nam.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _operations(DashboardProvider p) => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'Cần theo dõi',
          'Trạng thái hiện tại • Không phụ thuộc khoảng ngày',
        ),
        const SizedBox(height: 20),
        for (final item in [
          (
            title: 'Đơn chờ xuất giao',
            detail: 'Đơn đã xác nhận, chưa bàn giao vận chuyển',
            value: '${p.awaitingShipment}',
            route: '/orders',
            icon: Symbols.local_shipping,
            urgent: p.awaitingShipment > 0,
          ),
          (
            title: 'Phiếu trả chờ hoàn tiền',
            detail: 'Đã nhận hàng trả và có số tiền cần hoàn',
            value: '${p.pendingRefunds}',
            route: '/orders',
            icon: Symbols.assignment_return,
            urgent: p.pendingRefunds > 0,
          ),
          (
            title: 'SKU sắp hết / hết hàng',
            detail: 'Số lượng có thể bán ≤ 5, gồm SKU tạm ngừng',
            value: '${p.lowStock}',
            route: '/inventory',
            icon: Symbols.inventory_2,
            urgent: p.lowStock > 0,
          ),
          (
            title: 'Công nợ nhà cung cấp',
            detail: 'Số tiền còn nợ trên phiếu nhập đã ghi sổ',
            value: reportMoney(p.currentDebt),
            route: '/purchases',
            icon: Symbols.account_balance_wallet,
            urgent: false,
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.urgent
                      ? const Color(0xFFFFF4E5)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.urgent
                      ? AppTheme.warning
                      : AppTheme.textSecondary,
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: item.urgent ? AppTheme.warning : AppTheme.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Symbols.chevron_right,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              onTap: widget.onNavigate == null
                  ? null
                  : () => widget.onNavigate!(item.route),
            ),
          ),
      ],
    ),
  );

  Widget _orders(DashboardProvider p) {
    final distribution = p.distribution;
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    const colors = {
      'PENDING': Color(0xFFD4A24C),
      'CONFIRMED': Color(0xFF6489A5),
      'SHIPPED': Color(0xFF8E82AE),
      'DELIVERED': Color(0xFF508876),
      'CANCELLED': Color(0xFFB77A78),
      'RETURNED': Color(0xFF9299A3),
    };
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(
            'Đơn đặt trong kỳ',
            'Trạng thái hiện tại của nhóm đơn tạo trong kỳ',
          ),
          const SizedBox(height: 20),
          Text(
            '$total đơn',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Chưa có đơn đặt trong khoảng thời gian này.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  for (final status in colors.keys)
                    if ((distribution[status] ?? 0) > 0)
                      Expanded(
                        flex: distribution[status]!,
                        child: Container(height: 9, color: colors[status]),
                      ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          for (final status in colors.keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[status],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      orderStatusLabel(status),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${distribution[status] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
