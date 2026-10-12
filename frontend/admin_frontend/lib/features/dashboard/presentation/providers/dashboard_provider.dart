import 'package:flutter/material.dart';

import '../../data/analytics_calculations.dart';
import '../../data/analytics_report_builder.dart';
import '../../data/models/analytics_models.dart';
import '../../data/repositories/analytics_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({AnalyticsRepository? repository})
    : data = repository ?? AnalyticsRepository() {
    end = data.today;
    start = end.subtract(const Duration(days: 29));
  }
  final AnalyticsRepository data;
  late DateTime start, end;
  AnalyticsPeriod period = AnalyticsPeriod.month;
  AnalyticsSection section = AnalyticsSection.overview;
  bool compare = true;
  String query = '';
  String? category, orderStatus;
  int page = 0;
  final int pageSize = 10;
  AnalyticsSummary get summary =>
      AnalyticsCalculations.summary(data, start, end);
  int get days => end.difference(start).inDays + 1;
  DateTime get previousEnd => start.subtract(const Duration(days: 1));
  DateTime get previousStart => previousEnd.subtract(Duration(days: days - 1));
  AnalyticsSummary get previous =>
      AnalyticsCalculations.summary(data, previousStart, previousEnd);
  bool get previousCovered =>
      !previousStart.isBefore(data.today.subtract(const Duration(days: 89)));
  List<({DateTime date, int current, int previous})> get trend =>
      List.generate(days, (i) {
        final date = start.add(Duration(days: i));
        final old = previousStart.add(Duration(days: i));
        return (
          date: date,
          current: AnalyticsCalculations.summary(data, date, date).netRevenue,
          previous: AnalyticsCalculations.summary(data, old, old).netRevenue,
        );
      });
  String growth(int current, int old) => !previousCovered
      ? 'Kỳ trước chưa đủ dữ liệu'
      : old <= 0
      ? 'Chưa có cơ sở so sánh'
      : '${current >= old ? '+' : ''}${((current - old) / old * 100).toStringAsFixed(1)}% so với kỳ trước';
  AnalyticsTableData get table => AnalyticsReportBuilder(
    data,
    start,
    end,
    query: query,
    category: category,
    status: orderStatus,
  ).build(section);
  List<List<String>> get pageRows =>
      table.rows.skip(page * pageSize).take(pageSize).toList();
  int get lowStock =>
      AnalyticsRepository.products.where((p) => p.available <= 5).length;
  int get stockValue => AnalyticsCalculations.sum(
    AnalyticsRepository.products,
    (p) => p.stock * p.cost,
  );
  int get currentDebt =>
      AnalyticsCalculations.sum(data.receipts, (r) => r.debt);
  int get postedValue => AnalyticsCalculations.sum(
    data.receipts.where(
      (r) =>
          r.status == 'POSTED' &&
          AnalyticsCalculations.inside(r.postedAt, start, end),
    ),
    (r) => r.total - r.credit,
  );
  int get pendingRefunds =>
      data.returns.where((r) => r.refundedAt == null).length;
  int get awaitingShipment =>
      data.orders.where((o) => o.status == 'CONFIRMED').length;
  int get purchasingBuyers => data.orders
      .where((o) => AnalyticsCalculations.inside(o.paidAt, start, end))
      .map((o) => o.buyerKey)
      .toSet()
      .length;
  int get newBuyers {
    final firstPayments = <String, DateTime>{};
    for (final o in data.orders.where((o) => o.paidAt != null)) {
      if (firstPayments[o.buyerKey] == null ||
          o.paidAt!.isBefore(firstPayments[o.buyerKey]!)) {
        firstPayments[o.buyerKey] = o.paidAt!;
      }
    }
    return firstPayments.values
        .where((d) => AnalyticsCalculations.inside(d, start, end))
        .length;
  }

  void setPeriod(AnalyticsPeriod value) {
    if (value == AnalyticsPeriod.custom) return;
    period = value;
    end = data.today;
    start = end.subtract(
      Duration(
        days: switch (value) {
          AnalyticsPeriod.today => 0,
          AnalyticsPeriod.week => 6,
          AnalyticsPeriod.month => 29,
          AnalyticsPeriod.quarter => 89,
          AnalyticsPeriod.custom => 0,
        },
      ),
    );
    _reset();
  }

  void setRange(DateTimeRange range) {
    final nextStart = DateUtils.dateOnly(range.start);
    final nextEnd = DateUtils.dateOnly(range.end);
    if (nextEnd.isBefore(nextStart) ||
        nextEnd.isAfter(data.today) ||
        nextEnd.difference(nextStart).inDays > 365) {
      throw ArgumentError(
        'Khoảng ngày không hợp lệ (tối đa 366 ngày, không vượt hôm nay).',
      );
    }
    start = nextStart;
    end = nextEnd;
    period = AnalyticsPeriod.custom;
    _reset();
  }

  void setSection(AnalyticsSection value) {
    section = value;
    query = '';
    category = null;
    orderStatus = null;
    _reset();
  }

  void setQuery(String value) {
    query = value;
    _reset();
  }

  void setCategory(String? value) {
    category = value;
    _reset();
  }

  void setOrderStatus(String? value) {
    orderStatus = value;
    _reset();
  }

  void setCompare(bool value) {
    compare = value;
    notifyListeners();
  }

  void _reset() {
    page = 0;
    notifyListeners();
  }

  void setPage(int value) {
    page = value.clamp(
      0,
      ((table.rows.length - 1) ~/ pageSize).clamp(0, 999999),
    );
    notifyListeners();
  }

  String get csv {
    String escape(String value) {
      // Keep spreadsheet formulas from being interpreted when importing the CSV.
      final text = RegExp(r'^[=+@-]').hasMatch(value) ? "'$value" : value;
      return '"${text.replaceAll('"', '""')}"';
    }

    final lines = <List<String>>[
      ['Báo cáo mẫu', section.label],
      ['Từ ngày', reportDate(start), 'Đến ngày', reportDate(end)],
      ['Ghi chú', table.note],
      table.columns,
      ...table.rows,
    ];
    return lines.map((line) => line.map(escape).join(',')).join('\r\n');
  }
}
