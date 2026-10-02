import 'package:flutter/material.dart';

import '../../data/models/analytics_models.dart';
import '../providers/dashboard_provider.dart';

class AnalyticsFilters extends StatelessWidget {
  final DashboardProvider provider;
  const AnalyticsFilters({super.key, required this.provider});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      DropdownButton<AnalyticsPeriod>(
        value: provider.period,
        items: [
          for (final period in AnalyticsPeriod.values)
            DropdownMenuItem(value: period, child: Text(period.label)),
        ],
        onChanged: (period) {
          if (period == null) return;
          if (period == AnalyticsPeriod.custom) {
            _pickRange(context);
          } else {
            provider.setPeriod(period);
          }
        },
      ),
      OutlinedButton.icon(
        onPressed: () => _pickRange(context),
        icon: const Icon(Icons.date_range_outlined, size: 18),
        label: Text(
          '${reportDate(provider.start)} – ${reportDate(provider.end)}',
        ),
      ),
      Tooltip(
        message:
            'Kỳ trước: ${reportDate(provider.previousStart)} – ${reportDate(provider.previousEnd)}.'
            '${provider.previousCovered ? '' : ' Kỳ trước chưa đủ dữ liệu mẫu.'}',
        child: FilterChip(
          label: const Text('So sánh kỳ trước'),
          selected: provider.compare,
          onSelected: provider.setCompare,
        ),
      ),
    ],
  );
  Future<void> _pickRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: provider.data.today.subtract(const Duration(days: 365)),
      lastDate: provider.data.today,
      initialDateRange: DateTimeRange(start: provider.start, end: provider.end),
      helpText: 'Chọn khoảng thời gian báo cáo',
      saveText: 'Áp dụng',
    );
    if (range != null && context.mounted) provider.setRange(range);
  }
}
