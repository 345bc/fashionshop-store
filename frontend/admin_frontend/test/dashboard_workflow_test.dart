import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/dashboard/data/analytics_calculations.dart';
import 'package:zella_admin_flutter/features/dashboard/data/models/analytics_models.dart';
import 'package:zella_admin_flutter/features/dashboard/data/repositories/analytics_repository.dart';
import 'package:zella_admin_flutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:zella_admin_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:zella_admin_flutter/features/dashboard/presentation/widgets/analytics_cards.dart';

void main() {
  final today = DateTime(2026, 10, 1);
  int amount(String text) => int.parse(text.replaceAll(RegExp(r'[^0-9-]'), ''));
  DashboardProvider provider() =>
      DashboardProvider(repository: AnalyticsRepository(now: today));
  test('Revenue, cash and refund use separate event dates and reconcile return cost', () {
    final data = AnalyticsRepository(now: today);
    data.orders.clear();
    data.returns.clear();
    data.orders.addAll([
      AnalyticsOrder(
        id: 1,
        productId: 1,
        quantity: 2,
        listPrice: 100000,
        soldPrice: 90000,
        unitCost: 40000,
        voucherDiscount: 10000,
        shipping: 30000,
        code: 'ORDER-1',
        status: 'DELIVERED',
        paymentStatus: 'PAID',
        buyerKey: 'BUYER-1',
        buyerName: 'Khách 1',
        guest: true,
        createdAt: DateTime(2026, 9, 28),
        paidAt: DateTime(2026, 9, 28),
        deliveredAt: today,
      ),
      AnalyticsOrder(
        id: 2,
        productId: 1,
        quantity: 1,
        listPrice: 200000,
        soldPrice: 200000,
        unitCost: 100000,
        voucherDiscount: 0,
        shipping: 30000,
        code: 'ORDER-2',
        status: 'CONFIRMED',
        paymentStatus: 'PAID',
        buyerKey: 'BUYER-2',
        buyerName: 'Khách 2',
        guest: false,
        createdAt: today,
        paidAt: today,
      ),
    ]);
    data.returns.add(
      AnalyticsReturn(
        1,
        1,
        1,
        85000,
        40000,
        today,
        today.add(const Duration(days: 1)),
      ),
    );
    final s = AnalyticsCalculations.summary(data, today, today);
    expect(s.netRevenue, 85000);
    expect(s.cogs, 40000);
    expect(s.grossProfit, 45000);
    expect(s.cashIn, 230000);
    expect(s.cashOut, 0);
    expect(s.shipping, 30000);
    expect(s.createdOrders, 1);
    expect(s.deliveredOrders, 1);
    expect(s.soldQuantity, 1);
    final next = today.add(const Duration(days: 1));
    expect(AnalyticsCalculations.summary(data, next, next).cashOut, 85000);
    expect(AnalyticsCalculations.summary(data, next, next).netRevenue, 0);
  });
  test('Product and daily report totals equal KPI; stock/debt are date independent', () {
    final p = provider();
    p.setSection(AnalyticsSection.products);
    expect(
      p.table.rows.fold<int>(0, (n, row) => n + amount(row[4])),
      p.summary.netRevenue,
    );
    expect(
      p.table.rows.fold<int>(0, (n, row) => n + amount(row[5])),
      p.summary.cogs,
    );
    p.setSection(AnalyticsSection.revenue);
    expect(
      p.table.rows.fold<int>(0, (n, row) => n + amount(row[1])),
      p.summary.netRevenue,
    );
    expect(
      p.table.rows.fold<int>(0, (n, row) => n + amount(row[4])),
      p.summary.cashIn,
    );
    final stock = p.stockValue, debt = p.currentDebt;
    p.setPeriod(AnalyticsPeriod.today);
    expect(p.stockValue, stock);
    expect(p.currentDebt, debt);
    expect(p.summary.createdOrders, 3);
  });
  test('Previous period has equal length and missing history is not growth; invalid range preserves state', () {
    final p = provider();
    p.setPeriod(AnalyticsPeriod.week);
    expect(p.days, 7);
    expect(p.previousEnd, p.start.subtract(const Duration(days: 1)));
    expect(p.previousEnd.difference(p.previousStart).inDays, 6);
    p.setPeriod(AnalyticsPeriod.quarter);
    expect(p.previousCovered, isFalse);
    expect(p.growth(100, 10), 'Kỳ trước chưa đủ dữ liệu');
    final oldEnd = p.end;
    expect(
      () => p.setRange(
        DateTimeRange(start: today, end: today.add(const Duration(days: 1))),
      ),
      throwsArgumentError,
    );
    expect(p.end, oldEnd);
  });
  Future<void> mount(
    WidgetTester tester,
    DashboardProvider p, {
    double width = 1600,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: p)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Presets, table pagination, filter and detail work', (
    tester,
  ) async {
    final p = provider();
    p.setSection(AnalyticsSection.orders);
    await mount(tester, p);
    await tester.tap(find.byType(DropdownButton<AnalyticsPeriod>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 ngày').last);
    await tester.pumpAndSettle();
    expect(p.summary.createdOrders, 21);
    await tester.ensureVisible(find.byIcon(Icons.chevron_right));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(p.page, 1);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'ORD-DEMO-0270');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(p.table.rows.length, 1);
    expect(p.page, 0);
    final orderCell = find.descendant(
      of: find.byType(DataTable),
      matching: find.text('ORD-DEMO-0270'),
    );
    await tester.ensureVisible(orderCell);
    await tester.tap(orderCell);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Chi tiết đơn hàng'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Overview stays compact and KPI opens detail tab with the same dates',
    (tester) async {
      final p = provider();
      await mount(tester, p);
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Cần xử lý hiện tại'), findsNothing);
      final start = p.start, end = p.end;
      await tester.tap(find.text('Doanh thu thuần'));
      await tester.pumpAndSettle();
      expect(p.section, AnalyticsSection.revenue);
      expect(p.start, start);
      expect(p.end, end);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byType(AnalyticsCards), findsNothing);
      expect(find.text('Thực thu từ khách'), findsNothing);
      await tester.ensureVisible(find.text('Xem chỉ số tổng hợp & cách tính'));
      await tester.tap(find.text('Xem chỉ số tổng hợp & cách tính'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsCards), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'All report sections render at narrow width; empty orders have empty state',
    (tester) async {
      final p = provider();
      await mount(tester, p, width: 700);
      for (final section in AnalyticsSection.values) {
        p.setSection(section);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: section.label);
      }
      p.setSection(AnalyticsSection.orders);
      p.setRange(
        DateTimeRange(
          start: today.subtract(const Duration(days: 200)),
          end: today.subtract(const Duration(days: 195)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Không có dữ liệu trong bộ lọc đã chọn.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('CSV copies all filtered rows, not just visible page', (
    tester,
  ) async {
    final p = provider();
    p.setSection(AnalyticsSection.orders);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await mount(tester, p);
    await tester.tap(find.text('Sao chép CSV'));
    await tester.pumpAndSettle();
    expect(copied, contains(p.table.rows.last.first));
    expect(copied!.split('\r\n').length, p.table.rows.length + 4);
    expect(tester.takeException(), isNull);
  });
}
