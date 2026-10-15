import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/features/dashboard/data/models/analytics_models.dart';
import 'package:zella_admin_flutter/features/dashboard/data/repositories/analytics_repository.dart';
import 'package:zella_admin_flutter/features/dashboard/presentation/providers/dashboard_provider.dart';

class ControlledReports extends AnalyticsRepository {
  final requests = <Map<String, dynamic>>[];
  final responses = <Completer<Map<String, dynamic>>>[];
  @override
  Future<Map<String, dynamic>> fetch(Map<String, dynamic> parameters) {
    requests.add(Map.of(parameters));
    final response = Completer<Map<String, dynamic>>();
    responses.add(response);
    return response.future;
  }
}

Map<String, dynamic> report({
  int revenue = 0,
  int total = 21,
  List<List<String>>? rows,
}) => {
  'summary': {'grossGoods': revenue},
  'previous': {},
  'current': {'stock': 12, 'reserved': 2},
  'trend': [],
  'categories': ['Áo nữ'],
  'warnings': [],
  'distribution': {'RETURNED': 2},
  'table': {
    'columns': ['Mã', 'Giá trị'],
    'rows':
        rows ??
        [
          ['ORDER-1', '100 đ'],
        ],
    'totalElements': total,
    'note': 'Test report',
  },
};

void main() {
  test(
    'Production repository starts empty; a failed API never shows demo numbers',
    () async {
      final repository = ControlledReports();
      final p = DashboardProvider(repository: repository);
      expect(repository.orders, isEmpty);
      expect(p.ready, isFalse);
      final load = p.load();
      repository.responses.first.completeError(Exception('Network failure'));
      await load;
      expect(p.error, isNotNull);
      expect(p.ready, isFalse);
      expect(p.summary.netRevenue, 0);
      expect(p.table.rows, isEmpty);
    },
  );

  test(
    'Late response from an old date range cannot replace the current report',
    () async {
      final repository = ControlledReports();
      final p = DashboardProvider(repository: repository);
      final old = p.load();
      p.setPeriod(AnalyticsPeriod.week);
      repository.responses[1].complete(report(revenue: 200));
      await Future<void>.delayed(Duration.zero);
      repository.responses[0].complete(report(revenue: 999));
      await old;
      expect(p.summary.netRevenue, 200);
      expect(p.ready, isTrue);
      expect(p.days, 7);
    },
  );

  test(
    'Pagination uses server totals and preserves server page rows',
    () async {
      final repository = ControlledReports();
      final p = DashboardProvider(repository: repository);
      p.setSection(AnalyticsSection.orders);
      repository.responses[0].complete(report());
      await Future<void>.delayed(Duration.zero);
      p.setPage(1);
      expect(repository.requests[1]['page'], 1);
      repository.responses[1].complete(
        report(
          rows: [
            ['ORDER-11', '200 đ'],
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(p.totalElements, 21);
      expect(p.pageRows.first.first, 'ORDER-11');
      expect(p.stock, 12);
      expect(p.distribution['RETURNED'], 2);
    },
  );

  test('CSV fetches every server page with the captured filters and escapes formulas', () async {
    final repository = ControlledReports();
    final p = DashboardProvider(repository: repository);
    p.setQuery('Áo');
    repository.responses[0].complete(report());
    await Future<void>.delayed(Duration.zero);
    final export = p.exportCsv();
    repository.responses[1].complete(
      report(total: 101, rows: List.generate(100, (i) => ['ROW-$i', '100 đ'])),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.requests[2]['page'], 1);
    expect(repository.requests[2]['size'], 100);
    expect(repository.requests[2]['q'], 'Áo');
    repository.responses[2].complete(
      report(
        total: 101,
        rows: [
          ['=HYPERLINK(test)', '200 đ'],
        ],
      ),
    );
    final csv = await export;
    expect(csv.split('\r\n').length, 105);
    expect(csv, contains("'=HYPERLINK(test)"));
    expect(p.exporting, isFalse);
  });
}
