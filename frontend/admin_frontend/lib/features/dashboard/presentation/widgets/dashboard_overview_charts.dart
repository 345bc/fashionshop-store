import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/analytics_models.dart';

const dashboardAccent = Color(0xFF5364FF);

Widget overviewCard({required Widget child}) => Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE4E7EC)),
    borderRadius: BorderRadius.circular(18),
  ),
  child: child,
);

class DashboardSalesBars extends StatelessWidget {
  final DashboardProvider provider;
  const DashboardSalesBars({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final rows = provider.trend;
    final maxValue = rows.fold<double>(
      1,
      (value, row) => math.max(value, row.current.abs() / 1000000),
    );
    return overviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu trong kỳ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Theo ngày · Đơn vị: triệu đồng',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: rows.isEmpty
                ? const Center(child: Text('Chưa có dữ liệu doanh thu.'))
                : LayoutBuilder(
                    builder: (context, box) => BarChart(
                      BarChartData(
                        maxY: maxValue * 1.2,
                        minY: rows.any((row) => row.current < 0)
                            ? -maxValue * 1.2
                            : 0,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
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
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= rows.length ||
                                    index %
                                            math.max(
                                              1,
                                              (rows.length / 5).ceil(),
                                            ) !=
                                        0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('dd/MM')
                                        .format(rows[index].date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < rows.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: rows[i].current / 1000000,
                                  width: (box.maxWidth / rows.length * 0.45)
                                      .clamp(2.0, 18.0),
                                  color: dashboardAccent,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                        ],
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem:
                                (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) => BarTooltipItem(
                                  '${reportDate(rows[group.x].date)}\n${reportMoney(rows[group.x].current)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                          ),
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

class DashboardOrderStatus extends StatelessWidget {
  final DashboardProvider provider;
  const DashboardOrderStatus({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final distribution = provider.distribution;
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    final delivered = distribution['DELIVERED'] ?? 0;
    final rate = total == 0 ? 0.0 : delivered / total;
    return overviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đơn đặt trong kỳ',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tỷ lệ giao thành công của nhóm đơn tạo trong kỳ',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 205,
            child: LayoutBuilder(
              builder: (context, box) => CustomPaint(
                painter: _DeliveryGauge(rate),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 38),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$delivered / $total đơn',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF039855),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            const Text(
              'Chưa có đơn đặt trong khoảng thời gian này.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            const Text(
              'Trạng thái hiện tại của các đơn hàng trong bộ lọc đã chọn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                for (final entry in [
                  ('Đã đặt', total),
                  ('Đã giao', delivered),
                  ('Đã hủy', distribution['CANCELLED'] ?? 0),
                ])
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          entry.$1,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${entry.$2}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final status in ['PENDING', 'CONFIRMED', 'SHIPPED', 'RETURNED'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: dashboardAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      orderStatusLabel(status),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${distribution[status] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryGauge extends CustomPainter {
  final double value;
  _DeliveryGauge(this.value);
  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2 - 16, size.height - 26);
    final center = Offset(size.width / 2, size.height - 16);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      paint..color = const Color(0xFFEAECF0),
    );
    if (value > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * value.clamp(0, 1),
        false,
        paint..color = dashboardAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DeliveryGauge oldDelegate) =>
      oldDelegate.value != value;
}
