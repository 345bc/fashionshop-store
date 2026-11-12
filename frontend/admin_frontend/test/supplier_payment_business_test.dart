import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/purchases/data/models/goods_receipt_response_model.dart';
import 'package:zella_admin_flutter/features/purchases/presentation/dialogs/supplier_payment_dialog.dart';
import 'package:zella_admin_flutter/features/purchases/presentation/providers/purchases_provider.dart';

class PaymentRecorder extends PurchasesProvider {
  final calls = <Map<String, dynamic>>[];
  bool fails = false;
  @override
  Future<void> action(
    int id,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    calls.add({'id': id, 'action': action, ...?data});
    if (fails) throw Exception('Payment unavailable');
  }
}

GoodsReceiptResponseModel receipt() => GoodsReceiptResponseModel({
  'id': 15,
  'supplierId': 2,
  'code': 'TEST-15',
  'supplierName': 'NCC test',
  'status': 'POSTED',
  'paymentStatus': 'PARTIAL',
  'totalAmount': 1000,
  'paidAmount': 400,
  'remainingAmount': 600,
  'supplierRefundDue': 200,
  'createdAt': '2026-11-02T00:00:00Z',
  'items': [],
  'payments': [],
});

Future<void> open(
  WidgetTester tester,
  PaymentRecorder provider, {
  bool refund = false,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<PurchasesProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => ChangeNotifierProvider<PurchasesProvider>.value(
                  value: provider,
                  child: SupplierPaymentDialog(
                    receipt: receipt(),
                    isRefund: refund,
                  ),
                ),
              ),
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
      envString: 'API_BASE_URL=http://127.0.0.1:18080/api/v1',
    ),
  );
  for (final amount in ['', '0', '-1', '601', '12.345']) {
    testWidgets('Supplier payment rejects invalid amount [$amount]', (
      tester,
    ) async {
      final provider = PaymentRecorder();
      await open(tester, provider);
      await tester.enterText(find.byType(TextFormField).first, amount);
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(provider.calls, isEmpty);
      expect(find.byType(SupplierPaymentDialog), findsOneWidget);
    });
  }
  testWidgets('Supplier payment accepts exact remaining debt and trims note', (
    tester,
  ) async {
    final provider = PaymentRecorder();
    await open(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '600');
    await tester.enterText(find.byType(TextFormField).last, '  Paid  ');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(provider.calls.single, {
      'id': 15,
      'action': 'payments',
      'amount': 600,
      'paymentMethod': 'BANK_TRANSFER',
      'note': 'Paid',
    });
    expect(find.byType(SupplierPaymentDialog), findsNothing);
  });
  testWidgets('Supplier refund rejects amount exceeding refundable balance', (
    tester,
  ) async {
    final provider = PaymentRecorder();
    await open(tester, provider, refund: true);
    await tester.enterText(find.byType(TextFormField).first, '201');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(provider.calls, isEmpty);
  });
  testWidgets('Supplier refund submits to refunds instead of payments', (
    tester,
  ) async {
    final provider = PaymentRecorder();
    await open(tester, provider, refund: true);
    await tester.enterText(find.byType(TextFormField).first, '200');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(provider.calls.single['action'], 'refunds');
    expect(provider.calls.single['amount'], 200);
  });
  testWidgets('Supplier payment API error preserves amount for retry', (
    tester,
  ) async {
    final provider = PaymentRecorder()..fails = true;
    await open(tester, provider);
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Exception: Payment unavailable'), findsOneWidget);
    expect(find.byType(SupplierPaymentDialog), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '100',
    );
    provider.fails = false;
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(provider.calls, hasLength(2));
    expect(find.byType(SupplierPaymentDialog), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
