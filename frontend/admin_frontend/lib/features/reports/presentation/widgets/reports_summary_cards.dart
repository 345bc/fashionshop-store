import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ReportsSummaryCards extends StatelessWidget {
  const ReportsSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> kpis = [
      {'label': 'Tổng doanh thu', 'value': '145.000.000 ₫', 'change': '+8.5%', 'trend': 'up', 'icon': Icons.trending_up},
      {'label': 'Đơn hoàn thành', 'value': '38', 'change': '+12%', 'trend': 'up', 'icon': Icons.shopping_bag_outlined},
      {'label': 'Khách mới', 'value': '5', 'change': '-2', 'trend': 'down', 'icon': Icons.group_outlined},
      {'label': 'Giá trị ĐH bình quân', 'value': '3.815.000 ₫', 'change': '+3.2%', 'trend': 'up', 'icon': Icons.inventory_2_outlined},
    ];

    return Row(
      children: kpis.map((kpi) {
        final isUp = kpi['trend'] == 'up';
        final changeColor = isUp ? AppTheme.success : AppTheme.danger;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: kpi == kpis.last ? 0 : 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      kpi['label'],
                      style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    Icon(kpi['icon'], size: 20, color: AppTheme.textMuted),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  kpi['value'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: changeColor),
                    const SizedBox(width: 4),
                    Text(
                      kpi['change'],
                      style: TextStyle(color: changeColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Text(' so với kỳ trước', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
