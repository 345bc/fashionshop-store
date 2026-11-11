import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';
import '../../data/models/analytics_models.dart';

class RevenueChart extends StatelessWidget {
  final DashboardProvider provider;
  const RevenueChart({super.key, required this.provider});

  static const Color primaryColor = Color(0xFF465FFF);
  static const Color secondaryColor = Color(0xFF9DB4FF);

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
      color: previous ? secondaryColor : primaryColor,
      barWidth: 2.5,
      dashArray: null,
      dotData: FlDotData(show: rows.length == 1),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: previous
              ? [
                  secondaryColor.withValues(alpha: 0.12),
                  secondaryColor.withValues(alpha: 0.0),
                ]
              : [
                  primaryColor.withValues(alpha: 0.16),
                  primaryColor.withValues(alpha: 0.0),
                ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu thuần theo ngày',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Kỳ hiện tại',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              if (provider.compare && provider.previousCovered)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: secondaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Kỳ trước (cùng số ngày)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              if (provider.compare && !provider.previousCovered)
                const Text(
                  'Kỳ trước chưa đủ dữ liệu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              const Text(
                'Đơn vị: triệu đồng',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
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
                maxY: maxValue * 1.25,
                lineBarsData: [
                  line(false),
                  if (provider.compare && provider.previousCovered) line(true),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F4F9),
                    strokeWidth: 1,
                  ),
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
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: math
                          .max(1, (rows.length / 4).ceil())
                          .toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            DateFormat('dd/MM').format(rows[index].date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  getTouchLineStart: (barData, spotIndex) => -double.infinity,
                  getTouchLineEnd: (barData, spotIndex) => double.infinity,
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      final color = barData.color ?? primaryColor;
                      return TouchedSpotIndicatorData(
                        const FlLine(
                          color: Color(0xFFD0D5DD),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 5,
                            color: color,
                            strokeWidth: 4,
                            strokeColor: color.withValues(alpha: 0.32),
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipBorder: const BorderSide(
                      color: Color(0xFFEEF2F6),
                      width: 1,
                    ),
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    tooltipMargin: 16,
                    maxContentWidth: 260,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (List<LineBarSpot> spots) {
                      if (spots.isEmpty) return [];

                      return spots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final spot = entry.value;
                        final isPrevious = spot.barIndex != 0;
                        final dotColor = isPrevious ? secondaryColor : primaryColor;
                        final label = isPrevious ? 'Kỳ trước' : 'Kỳ hiện tại';
                        final money = reportMoney((spot.y * 1000000).round());
                        final date = rows[spot.x.toInt()].date;
                        final dateStr = DateFormat('dd/MM/yyyy').format(date);

                        if (index == 0) {
                          return LineTooltipItem(
                            '$dateStr\n',
                            const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.left,
                            children: [
                              TextSpan(
                                text: '●  ',
                                style: TextStyle(
                                  color: dotColor,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: '$label: ',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: money,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }

                        return LineTooltipItem(
                          '●  ',
                          TextStyle(
                            color: dotColor,
                            fontSize: 11,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                          children: [
                            TextSpan(
                              text: '$label: ',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: money,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
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
