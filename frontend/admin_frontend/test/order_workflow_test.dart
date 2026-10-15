import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'support/fake_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:zella_admin_flutter/features/orders/data/models/order_response_model.dart';
import 'package:zella_admin_flutter/features/orders/data/models/return_order_summary.dart';
import 'package:zella_admin_flutter/features/orders/presentation/dialogs/return_management_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/screens/orders_screen.dart';
import 'package:zella_admin_flutter/features/orders/presentation/dialogs/order_detail_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/dialogs/receive_return_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/providers/orders_provider.dart';

class FakeInventory extends InventoryProvider {
  @override
  Future<void> loadItems() async {}
}

class FakeOrders extends OrdersProvider {
  int requestedPage = 0;
  String requestedQuery = '', requestedStatus = 'ALL';
  bool queueFails = false;
  @override
  Future<void> loadItems() async {}
  @override
  Future<({List<ReturnOrderSummary> items, int total})> returnOrders({
    int page = 0,
    String query = '',
    String status = 'ALL',
  }) async {
    requestedPage = page;
    requestedQuery = query;
    requestedStatus = status;
    if (queueFails) throw Exception('Không tải được yêu cầu');
    if (query == 'none') return (items: <ReturnOrderSummary>[], total: 0);
    return (
      items: [
        ReturnOrderSummary({
          'orderId': 10 + page,
          'orderCode': 'ORD-RETURN-${10 + page}',
          'recipientName': 'Khách trả hàng',
          'recipientPhone': '0900000000',
          'totalAmount': 600000,
          'latestRequestAt': '2026-10-10T08:00:00Z',
          'totalRequests': 2,
          'pendingRequests': 1,
          'statuses': ['PENDING', 'APPROVED'],
        }),
      ],
      total: 11,
    );
  }

  Map<String, dynamic>? submitted;
  String? lastAction;
  bool pending = false;
  bool simulation = false;
  @override
  Future<bool> paymentSimulationEnabled() async => simulation;
  @override
  Future<void> simulatePayment(int id) async {
    lastAction = 'simulate-payment';
  }

  OrderResponseModel get order => OrderResponseModel({
    'id': 10,
    'customerUserId': 20,
    'code': 'ORD-TEST',
    'customerName': 'Khách thử',
    'recipientName': 'Khách thử',
    'recipientPhone': '0900000000',
    'address': 'Hồ Chí Minh',
    'status': pending ? 'PENDING' : 'CONFIRMED',
    'paymentStatus': pending ? 'PENDING' : 'PAID',
    'paymentMethod': 'ONLINE',
    'paymentExpiresAt': DateTime.now()
        .add(const Duration(minutes: 5))
        .toUtc()
        .toIso8601String(),
    'inventoryManaged': true,
    'subtotal': 600000,
    'shippingFee': 0,
    'totalAmount': 600000,
    'createdAt': '2026-10-01T10:00:00',
    'items': [
      {
        'id': 30,
        'variantId': 1,
        'productName': 'Áo nữ',
        'sku': 'SKU-1',
        'quantity': 2,
        'unitPrice': 300000,
        'subtotal': 600000,
        'returnedQuantity': 0,
      },
    ],
    'histories': <Map<String, dynamic>>[],
  });
  @override
  Future<OrderResponseModel> loadDetail(int id) async => order;
  @override
  Future<List<ReturnResponseModel>> returns(int orderId) async => [];
  @override
  Future<void> action(
    int id,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    lastAction = action;
  }

  @override
  Future<void> returnAction(
    int id,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    lastAction = action;
    submitted = data;
  }
}

Future<void> openDialog(
  WidgetTester tester,
  FakeOrders provider,
  Widget dialog,
) async {
  tester.view.physicalSize = const Size(1600, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuth()),
        ChangeNotifierProvider<OrdersProvider>.value(value: provider),
        ChangeNotifierProvider<InventoryProvider>(
          create: (_) => FakeInventory(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showDialog(context: context, builder: (_) => dialog),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8080/api/v1',
    ),
  );
  testWidgets(
    'Orders replaces creation with return management and opens invoice detail',
    (tester) async {
      final provider = FakeOrders();
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuth()),
            ChangeNotifierProvider<OrdersProvider>.value(value: provider),
            ChangeNotifierProvider<InventoryProvider>(
              create: (_) => FakeInventory(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: OrdersScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tạo đơn hàng'), findsNothing);
      await tester.tap(find.text('Quản lý hoàn hàng'));
      await tester.pumpAndSettle();
      expect(find.byType(ReturnManagementDialog), findsOneWidget);
      expect(find.text('ORD-RETURN-10'), findsOneWidget);
      expect(find.textContaining('2 yêu cầu ·'), findsOneWidget);
      await tester.tap(find.text('ORD-RETURN-10'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );

  testWidgets('Return management filters, pages and shows empty results', (
    tester,
  ) async {
    final provider = FakeOrders();
    await openDialog(tester, provider, const ReturnManagementDialog());
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(provider.requestedPage, 1);
    expect(find.text('ORD-RETURN-11'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chờ duyệt').last);
    await tester.pumpAndSettle();
    expect(provider.requestedStatus, 'PENDING');
    expect(provider.requestedPage, 0);
    await tester.enterText(find.byType(TextField), 'none');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(provider.requestedQuery, 'none');
    expect(find.text('Chưa có đơn hàng có yêu cầu phù hợp.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets('Return management retries loading errors', (tester) async {
    final provider = FakeOrders()..queueFails = true;
    await openDialog(tester, provider, const ReturnManagementDialog());
    expect(find.textContaining('Không tải được yêu cầu'), findsOneWidget);
    provider.queueFails = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('ORD-RETURN-10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
  testWidgets('Shipping requires confirmation before the API action', (
    tester,
  ) async {
    final provider = FakeOrders();
    await openDialog(tester, provider, const OrderDetailDialog(orderId: 10));
    await tester.ensureVisible(find.text('Xuất kho'));
    await tester.tap(find.text('Xuất kho'));
    await tester.pumpAndSettle();
    expect(provider.lastAction, isNull);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(provider.lastAction, 'ship');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
  testWidgets('Receiving a damaged return sends the inspected condition', (
    tester,
  ) async {
    final provider = FakeOrders();
    final document = ReturnResponseModel({
      'id': 40,
      'orderId': 10,
      'orderCode': 'ORD-TEST',
      'code': 'RET-TEST',
      'status': 'APPROVED',
      'reason': 'Test',
      'refundAmount': 300000,
      'items': [
        {
          'id': 41,
          'orderItemId': 30,
          'variantId': 1,
          'productName': 'Áo nữ',
          'sku': 'SKU-1',
          'quantity': 1,
        },
      ],
      'histories': <Map<String, dynamic>>[],
    });
    await openDialog(tester, provider, ReceiveReturnDialog(document: document));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hỏng, không nhập tồn bán').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận đã nhận hàng'));
    await tester.pumpAndSettle();
    expect(provider.lastAction, 'receive');
    expect(provider.submitted?['items'], [
      {'returnItemId': 41, 'condition': 'DAMAGED'},
    ]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
  testWidgets(
    'Pending online order has countdown and no manual confirmation or collection buttons',
    (tester) async {
      final provider = FakeOrders()..pending = true;
      await openDialog(tester, provider, const OrderDetailDialog(orderId: 10));
      expect(find.text('Xác nhận đơn'), findsNothing);
      expect(find.text('Ghi nhận đã thu tiền'), findsNothing);
      expect(find.text('Xuất kho'), findsNothing);
      expect(find.textContaining('Giữ hàng còn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
  testWidgets(
    'Temporary confirmation button is gated and calls the simulation API after confirmation',
    (tester) async {
      final provider = FakeOrders()
        ..pending = true
        ..simulation = true;
      await openDialog(tester, provider, const OrderDetailDialog(orderId: 10));
      final button = find.text('TEST • Xác nhận đơn');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(provider.lastAction, isNull);
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(provider.lastAction, 'simulate-payment');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
}
