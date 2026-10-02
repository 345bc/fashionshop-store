import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/inventory/data/models/inventory_response_model.dart';
import 'package:zella_admin_flutter/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:zella_admin_flutter/features/orders/data/models/order_response_model.dart';
import 'package:zella_admin_flutter/features/orders/presentation/dialogs/order_detail_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/dialogs/order_form_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/dialogs/receive_return_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/providers/orders_provider.dart';

class FakeInventory extends InventoryProvider {
  @override
  Future<void> loadItems() async {}
}

class FakeOrders extends OrdersProvider {
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

  final variant = InventoryResponseModel({
    'variantId': 1,
    'supplierId': 1,
    'stockQuantity': 5,
    'reservedQuantity': 0,
    'availableQuantity': 5,
    'sku': 'SKU-1',
    'productName': 'Áo nữ',
    'categoryName': 'Áo',
    'supplierName': 'NCC',
    'sizeName': 'M',
    'colorName': 'Trắng',
    'costPrice': 100000,
    'price': 300000,
    'isActive': true,
  });
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
  Future<
    ({
      List<Map<String, dynamic>> customers,
      List<InventoryResponseModel> variants,
    })
  >
  options() async => (
    customers: [
      {
        'userId': 20,
        'fullName': 'Khách thử',
        'email': 'test@example.com',
        'phone': '0900000000',
        'address': 'Hồ Chí Minh',
      },
    ],
    variants: [variant],
  );
  @override
  Future<void> create(Map<String, dynamic> data) async {
    submitted = data;
  }

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
    'Creating an order sends customer and quantities but no client price or stock',
    (tester) async {
      final provider = FakeOrders();
      await openDialog(tester, provider, const OrderFormDialog());
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khách thử — test@example.com').last);
      await tester.pumpAndSettle();
      final skuDropdown = find.byType(DropdownButtonFormField<int>).last;
      await tester.ensureVisible(skuDropdown);
      await tester.tap(skuDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('SKU-1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo đơn và giữ hàng'));
      await tester.pumpAndSettle();
      expect(provider.submitted?['customerUserId'], 20);
      expect(provider.submitted?['items'], [
        {'variantId': 1, 'quantity': 1},
      ]);
      expect(provider.submitted?.containsKey('price'), false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
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
  testWidgets('Guest order sends no customer account and only ONLINE payment', (
    tester,
  ) async {
    final provider = FakeOrders();
    await openDialog(tester, provider, const OrderFormDialog());
    expect(find.text('Khách vãng lai — không cần tài khoản'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Khách không đăng ký');
    await tester.enterText(fields.at(1), '0900000000');
    await tester.enterText(fields.at(2), 'TP.HCM');
    final sku = find.byType(DropdownButtonFormField<int>).last;
    await tester.ensureVisible(sku);
    await tester.tap(sku);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('SKU-1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đơn và giữ hàng'));
    await tester.pumpAndSettle();
    expect(provider.submitted?['customerUserId'], isNull);
    expect(provider.submitted?['paymentMethod'], 'ONLINE');
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
      final button = find.text('TEST • Xác nhận đơn (giả lập)');
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
