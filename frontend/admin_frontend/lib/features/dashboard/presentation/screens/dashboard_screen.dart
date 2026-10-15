import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../data/models/analytics_models.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<DashboardProvider>();
      if (widget.initialSection != null) {
        p.setSection(widget.initialSection!);
      } else if (!p.initialized) {
        p.load();
      }
    });
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
                  onPressed: !p.ready || p.exporting
                      ? null
                      : () async {
                          try {
                            final csv = await p.exportCsv();
                            await Clipboard.setData(ClipboardData(text: csv));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã sao chép CSV của toàn bộ dòng trong bộ lọc hiện tại',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không thể xuất báo cáo. Vui lòng thử lại.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Symbols.content_copy, size: 18),
                  label: const Text('Sao chép CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (p.isDemo)
              const Text(
                'Dữ liệu mẫu',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            if (p.loading) const LinearProgressIndicator(),
            if (p.error != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(onPressed: p.load, child: const Text('Thử lại')),
                ],
              ),
            for (final warning in p.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  warning,
                  style: const TextStyle(color: AppTheme.textSecondary),
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
            if (p.ready) ...[
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
                  maxSearchLength: 200,
                  key: ValueKey(p.section),
                  searchHint: 'Tìm trong bảng ${p.section.label.toLowerCase()}',
                  initialSearchText: p.query,
                  onSearchChanged: p.setQuery,
                  filterWidget: _filter(p),
                ),
                const SizedBox(height: 16),
                AnalyticsTable(provider: p),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget? _filter(DashboardProvider p) {
    if (p.section == AnalyticsSection.products ||
        p.section == AnalyticsSection.inventory) {
      return FilterDropdown<String?>(
        label: 'Danh mục',
        searchHint: 'Tìm danh mục',
        value: p.category,
        defaultValue: null,
        options: [
          for (final category in p.categories)
            FilterOption(value: category, label: category),
        ],
        onChanged: p.setCategory,
      );
    }
    if (p.section == AnalyticsSection.orders ||
        p.section == AnalyticsSection.overview) {
      return FilterDropdown<String?>(
        label: 'Trạng thái',
        searchHint: 'Tìm trạng thái',
        value: p.orderStatus,
        defaultValue: null,
        options: [
          for (final status in [
            'PENDING',
            'CONFIRMED',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED',
            'RETURNED',
          ])
            FilterOption(value: status, label: orderStatusLabel(status)),
        ],
        onChanged: p.setOrderStatus,
      );
    }
    return null;
  }
}
