import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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
  Map<String, dynamic>? _snapshot;
  bool loading = false, initialized = false, exporting = false;
  bool _disposed = false;
  int _request = 0;
  String? error;
  bool get isDemo => data.isDemo;
  bool get ready => isDemo || (_snapshot != null && !loading && error == null);
  Map<String, dynamic> _parameters({int? requestedPage, int? size}) => {
    'start': DateFormat('yyyy-MM-dd').format(start),
    'end': DateFormat('yyyy-MM-dd').format(end),
    'section': section.name,
    'q': query,
    if (category != null) 'category': category,
    if (orderStatus != null) 'status': orderStatus,
    'page': requestedPage ?? page,
    'size': size ?? pageSize,
  };
  Future<void> load() async {
    if (isDemo) {
      initialized = true;
      return;
    }
    final request = ++_request;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await data.fetch(_parameters());
      if (_disposed || request != _request) return;
      _snapshot = result;
      initialized = true;
    } catch (e) {
      if (_disposed || request != _request) return;
      error = e is DioException && e.response?.data is Map
          ? e.response!.data['message']?.toString() ?? 'Không thể tải báo cáo'
          : 'Không thể tải báo cáo. Vui lòng thử lại.';
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  int _current(String key) =>
      ((_snapshot?['current']?[key] as num?) ?? 0).round();
  List<String> get categories => isDemo
      ? AnalyticsRepository.products.map((p) => p.category).toSet().toList()
      : List<String>.from(_snapshot?['categories'] ?? []);
  List<String> get warnings => List<String>.from(_snapshot?['warnings'] ?? []);
  Map<String, int> get distribution => isDemo
      ? {
          for (final state in [
            'PENDING',
            'CONFIRMED',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED',
            'RETURNED',
          ])
            state: data.orders
                .where(
                  (o) =>
                      o.status == state &&
                      AnalyticsCalculations.inside(o.createdAt, start, end),
                )
                .length,
        }
      : Map<String, dynamic>.from(_snapshot?['distribution'] ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt()));
  int get totalElements => isDemo
      ? table.rows.length
      : (_snapshot?['table']?['totalElements'] as num? ?? 0).toInt();
  int get stock => isDemo
      ? AnalyticsRepository.products.fold<int>(0, (n, p) => n + p.stock)
      : _current('stock');
  int get reserved => isDemo
      ? AnalyticsRepository.products.fold<int>(0, (n, p) => n + p.reserved)
      : _current('reserved');
  int get costReversal => isDemo
      ? data.returns
            .where(
              (r) => AnalyticsCalculations.inside(r.receivedAt, start, end),
            )
            .fold<int>(0, (n, r) => n + r.costReversal)
      : _current('costReversal');
  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }

  late DateTime start, end;
  AnalyticsPeriod period = AnalyticsPeriod.month;
  AnalyticsSection section = AnalyticsSection.overview;
  bool compare = true;
  String query = '';
  String? category, orderStatus;
  int page = 0;
  final int pageSize = 10;
  AnalyticsSummary get summary => isDemo
      ? AnalyticsCalculations.summary(data, start, end)
      : AnalyticsSummary.fromJson(
          Map<String, dynamic>.from(_snapshot?['summary'] ?? {}),
        );
  int get days => end.difference(start).inDays + 1;
  DateTime get previousEnd => start.subtract(const Duration(days: 1));
  DateTime get previousStart => previousEnd.subtract(Duration(days: days - 1));
  AnalyticsSummary get previous => isDemo
      ? AnalyticsCalculations.summary(data, previousStart, previousEnd)
      : AnalyticsSummary.fromJson(
          Map<String, dynamic>.from(_snapshot?['previous'] ?? {}),
        );
  bool get previousCovered =>
      !isDemo ||
      !previousStart.isBefore(data.today.subtract(const Duration(days: 89)));
  List<({DateTime date, int current, int previous})> get trend => !isDemo
      ? ((_snapshot?['trend'] as List?) ?? [])
            .map(
              (r) => (
                date: DateTime.parse(r['date']),
                current: (r['current'] as num).round(),
                previous: (r['previous'] as num).round(),
              ),
            )
            .toList()
      : List.generate(days, (i) {
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
  AnalyticsTableData get table => !isDemo
      ? AnalyticsTableData(
          List<String>.from(_snapshot?['table']?['columns'] ?? []),
          ((_snapshot?['table']?['rows'] as List?) ?? [])
              .map((r) => List<String>.from(r))
              .toList(),
          _snapshot?['table']?['note'] ?? '',
        )
      : AnalyticsReportBuilder(
          data,
          start,
          end,
          query: query,
          category: category,
          status: orderStatus,
        ).build(section);
  List<List<String>> get pageRows => isDemo
      ? table.rows.skip(page * pageSize).take(pageSize).toList()
      : table.rows;
  int get lowStock => isDemo
      ? AnalyticsRepository.products.where((p) => p.available <= 5).length
      : _current('lowStock');
  int get stockValue => !isDemo
      ? _current('stockValue')
      : AnalyticsCalculations.sum(
          AnalyticsRepository.products,
          (p) => p.stock * p.cost,
        );
  int get currentDebt => isDemo
      ? AnalyticsCalculations.sum(data.receipts, (r) => r.debt)
      : _current('currentDebt');
  int get postedValue => !isDemo
      ? _current('postedValue')
      : AnalyticsCalculations.sum(
          data.receipts.where(
            (r) =>
                r.status == 'POSTED' &&
                AnalyticsCalculations.inside(r.postedAt, start, end),
          ),
          (r) => r.total - r.credit,
        );
  int get pendingRefunds => isDemo
      ? data.returns.where((r) => r.refundedAt == null).length
      : _current('pendingRefunds');
  int get awaitingShipment => isDemo
      ? data.orders.where((o) => o.status == 'CONFIRMED').length
      : _current('awaitingShipment');
  int get purchasingBuyers => !isDemo
      ? _current('purchasingBuyers')
      : data.orders
            .where((o) => AnalyticsCalculations.inside(o.paidAt, start, end))
            .map((o) => o.buyerKey)
            .toSet()
            .length;
  int get newBuyers {
    if (!isDemo) return _current('newBuyers');
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
    if (value.length > 200) throw ArgumentError('Từ khóa tối đa 200 ký tự');
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
    if (!isDemo) {
      load();
    } else {
      notifyListeners();
    }
  }

  void setPage(int value) {
    page = value.clamp(0, ((totalElements - 1) ~/ pageSize).clamp(0, 999999));
    if (!isDemo) {
      load();
    } else {
      notifyListeners();
    }
  }

  Future<String> exportCsv() async {
    if (isDemo) return csv;
    if (!ready || exporting) throw StateError('Báo cáo chưa sẵn sàng');
    exporting = true;
    notifyListeners();
    final parameters = _parameters(requestedPage: 0, size: 100);
    final title = section.label, from = start, to = end;
    try {
      final rows = <List<String>>[];
      List<String> columns = [];
      String note = '';
      int total;
      do {
        final result = await data.fetch(parameters);
        final table = result['table'];
        columns = List<String>.from(table['columns']);
        note = table['note'];
        rows.addAll((table['rows'] as List).map((r) => List<String>.from(r)));
        total = (table['totalElements'] as num).toInt();
        parameters['page'] = (parameters['page'] as int) + 1;
        if ((table['rows'] as List).isEmpty) break;
      } while ((parameters['page'] as int) * 100 < total);
      String escape(String text) {
        final safe = RegExp(r'^\s*[=+@-]').hasMatch(text) ? "'$text" : text;
        return '"${safe.replaceAll('"', '""')}"';
      }

      return [
        ['Báo cáo', title],
        ['Từ ngày', reportDate(from), 'Đến ngày', reportDate(to)],
        ['Ghi chú', note],
        columns,
        ...rows,
      ].map((r) => r.map(escape).join(',')).join('\r\n');
    } finally {
      exporting = false;
      if (!_disposed) notifyListeners();
    }
  }

  String get csv {
    String escape(String value) {
      // Keep spreadsheet formulas from being interpreted when importing the CSV.
      final text = RegExp(r'^[=+@-]').hasMatch(value) ? "'$value" : value;
      return '"${text.replaceAll('"', '""')}"';
    }

    final lines = <List<String>>[
      [isDemo ? 'Báo cáo mẫu' : 'Báo cáo', section.label],
      ['Từ ngày', reportDate(start), 'Đến ngày', reportDate(end)],
      ['Ghi chú', table.note],
      table.columns,
      ...table.rows,
    ];
    return lines.map((line) => line.map(escape).join(',')).join('\r\n');
  }
}
