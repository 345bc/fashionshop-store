import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../data/models/analytics_models.dart';
import '../../data/repositories/analytics_repository.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/analytics_filters.dart';
import '../widgets/analytics_cards.dart';
import '../widgets/analytics_panels.dart';
import '../widgets/analytics_table.dart';
import '../widgets/revenue_chart.dart';

class DashboardScreen extends StatefulWidget {
  final AnalyticsSection? initialSection;
  const DashboardScreen({super.key, this.initialSection});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardProvider>().setSection(widget.initialSection!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final chart =
        p.section == AnalyticsSection.overview ||
        p.section == AnalyticsSection.revenue;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        key: PageStorageKey('analytics-${p.section.name}'),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 24,
              runSpacing: 16,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard & Báo cáo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Theo dõi kinh doanh, vận hành và đi sâu vào từng báo cáo.',
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: p.csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã sao chép CSV của toàn bộ dòng trong bộ lọc hiện tại',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Sao chép CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Tooltip(
              message:
                  'Dữ liệu mẫu • ${reportDate(p.data.today.subtract(const Duration(days: 89)))} – ${reportDate(p.data.today)}. '
                  'Chưa kết nối backend; các số liệu không phải hoạt động thực tế.',
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dữ liệu mẫu',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnalyticsFilters(provider: p),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final section in AnalyticsSection.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(section.label),
                        selected: p.section == section,
                        onSelected: (_) => p.setSection(section),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (p.section == AnalyticsSection.overview) ...[
              AnalyticsCards(provider: p),
              const SizedBox(height: 24),
            ],
            if (chart) ...[
              RevenueChart(provider: p),
              const SizedBox(height: 24),
            ],
            if (p.section != AnalyticsSection.overview) ...[
              ExpansionTile(
                key: PageStorageKey('analytics-summary-${p.section.name}'),
                title: const Text('Xem chỉ số tổng hợp & cách tính'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  AnalyticsCards(provider: p),
                  const SizedBox(height: 16),
                  AnalyticsPanels(provider: p),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Chi tiết ${p.section.label.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FeatureToolbar(
                searchHint:
                    'Tìm trong bảng ${p.section.label.toLowerCase()}...',
                initialSearchText: p.query,
                onSearchChanged: p.setQuery,
                filterWidget: _filter(p),
              ),
              const SizedBox(height: 16),
              AnalyticsTable(provider: p),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _filter(DashboardProvider p) {
    if (p.section == AnalyticsSection.products ||
        p.section == AnalyticsSection.inventory) {
      return DropdownButton<String>(
        value: p.category,
        hint: const Text('Tất cả danh mục'),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Tất cả danh mục'),
          ),
          for (final category
              in AnalyticsRepository.products.map((r) => r.category).toSet())
            DropdownMenuItem(value: category, child: Text(category)),
        ],
        onChanged: p.setCategory,
      );
    }
    if (p.section == AnalyticsSection.orders ||
        p.section == AnalyticsSection.overview) {
      return DropdownButton<String>(
        value: p.orderStatus,
        hint: const Text('Tất cả trạng thái'),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Tất cả trạng thái'),
          ),
          for (final status in [
            'PENDING',
            'CONFIRMED',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED',
          ])
            DropdownMenuItem(
              value: status,
              child: Text(orderStatusLabel(status)),
            ),
        ],
        onChanged: p.setOrderStatus,
      );
    }
    return null;
  }
}
