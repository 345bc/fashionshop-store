import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/analytics_models.dart';

class RevenueChart extends StatelessWidget {
  final DashboardProvider provider;
  const RevenueChart({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final rows = provider.trend;
    final values = [
      0,
      ...rows.map((r) => r.current),
      if (provider.compare && provider.previousCovered)
        ...rows.map((r) => r.previous),
    ];
    final minValue = values.reduce(math.min) / 1000000;
    final maxValue = math.max(1.0, values.reduce(math.max) / 1000000);
    LineChartBarData line(bool previous) => LineChartBarData(
      isCurved: false,
      spots: [
        for (var i = 0; i < rows.length; i++)
          FlSpot(
            i.toDouble(),
            (previous ? rows[i].previous : rows[i].current) / 1000000,
          ),
      ],
      color: previous ? AppTheme.textMuted : AppTheme.info,
      barWidth: previous ? 2 : 3,
      dashArray: previous ? [6, 4] : null,
      dotData: FlDotData(show: rows.length == 1),
      belowBarData: BarAreaData(
        show: !previous,
        color: AppTheme.info.withAlpha(15),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu thuần theo ngày',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              const Text(
                '● Kỳ hiện tại',
                style: TextStyle(color: AppTheme.info),
              ),
              if (provider.compare && provider.previousCovered)
                const Text(
                  '┄ Kỳ trước (cùng số ngày)',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              if (provider.compare && !provider.previousCovered)
                const Text('Kỳ trước chưa đủ dữ liệu'),
              const Text('Đơn vị: triệu đồng'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, rows.length - 1).toDouble(),
                minY: minValue < 0 ? minValue * 1.15 : 0,
                maxY: maxValue * 1.15,
                lineBarsData: [
                  line(false),
                  if (provider.compare && provider.previousCovered) line(true),
                ],
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: math
                          .max(1, (rows.length / 4).ceil())
                          .toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd/MM').format(rows[index].date),
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${spot.barIndex == 0 ? 'Hiện tại' : 'Kỳ trước'} • ${reportDate(spot.barIndex == 0 ? rows[spot.x.toInt()].date : provider.previousStart.add(Duration(days: spot.x.toInt())))}\n${reportMoney((spot.y * 1000000).round())}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
