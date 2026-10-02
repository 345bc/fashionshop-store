import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/promotions/data/models/campaign_model.dart';
import 'package:zella_admin_flutter/features/promotions/data/repositories/campaign_repository.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/dialogs/campaign_form_dialog.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/dialogs/campaign_detail_dialog.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/providers/campaigns_provider.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/screens/campaign_management_screen.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/screens/promotions_screen.dart';

void main() {
  final now = DateTime(2026, 10, 1, 10);
  CampaignsProvider provider() => CampaignsProvider(
    repository: CampaignRepository(now: now),
    clock: () => now,
  );
  Future<void> mount(
    WidgetTester tester,
    CampaignsProvider p,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
          key: UniqueKey(),
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  child is CampaignFormDialog || child is CampaignDetailDialog
                  ? TextButton(
                      onPressed: () =>
                          showDialog(context: context, builder: (_) => child),
                      child: const Text('Mở dialog'),
                    )
                  : child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (child is CampaignFormDialog || child is CampaignDetailDialog) {
      await tester.tap(find.text('Mở dialog'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
  }

  testWidgets(
    'Hub has separate voucher and promotion parts; voucher list opens details',
    (tester) async {
      final p = provider();
      await mount(tester, p, const PromotionsScreen());
      expect(find.text('Voucher'), findsOneWidget);
      expect(find.text('Khuyến mãi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await mount(
        tester,
        p,
        const CampaignManagementScreen(kind: CampaignKind.voucher),
      );
      expect(find.text('WELCOME10'), findsOneWidget);
      expect(find.text('SAVE50K'), findsOneWidget);
      await tester.tap(find.text('WELCOME10'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết voucher'), findsOneWidget);
      expect(find.text('Lịch sử sử dụng mẫu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Create voucher uppercases code; duplicate code is rejected and editing preserves usage',
    (tester) async {
      final p = provider();
      await mount(
        tester,
        p,
        const CampaignFormDialog(kind: CampaignKind.voucher),
      );
      await enter(tester, 'Tên chương trình *', 'Voucher thử nghiệm');
      await enter(tester, 'Mã voucher *', 'welcome10');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Mã voucher đã tồn tại.'), findsOneWidget);
      await enter(tester, 'Mã voucher *', 'test20');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      final created = p.items(CampaignKind.voucher).cast<VoucherModel>().last;
      expect(created.code, 'TEST20');
      expect(created.usedCount, 0);
      final old = p.detail(1) as VoucherModel;
      await mount(
        tester,
        p,
        CampaignFormDialog(kind: CampaignKind.voucher, item: old),
      );
      final codeField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Mã voucher *'),
          matching: find.byType(TextField),
        ),
      );
      expect(codeField.readOnly, isTrue);
      await enter(tester, 'Tên chương trình *', 'Tên đã cập nhật');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      final updated = p.detail(1) as VoucherModel;
      expect(updated.name, 'Tên đã cập nhật');
      expect(updated.code, old.code);
      expect(updated.usedCount, old.usedCount);
      expect(updated.usages, old.usages);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Promotion requires product selection and saves selected products',
    (tester) async {
      final p = provider();
      await mount(
        tester,
        p,
        const CampaignFormDialog(kind: CampaignKind.promotion),
      );
      await enter(tester, 'Tên chương trình *', 'Ưu đãi nữ mới');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(
        find.text('Khuyến mãi cần giảm 1–100% và chọn ít nhất một sản phẩm.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Áo sơ mi nữ lụa cổ nơ'));
      await tester.tap(find.text('Áo sơ mi nữ lụa cổ nơ'));
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      final created = p
          .items(CampaignKind.promotion)
          .cast<PromotionModel>()
          .last;
      expect(created.products.single.id, 2);
      await mount(tester, p, CampaignDetailDialog(id: created.id));
      expect(find.text('Áo sơ mi nữ lụa cổ nơ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Toggle needs reason and does not restore exhausted quota; status filter works',
    (tester) async {
      final p = provider();
      await mount(tester, p, const CampaignDetailDialog(id: 2));
      await tester.tap(find.text('Tắt chương trình'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập lý do'), findsOneWidget);
      await enter(tester, 'Lý do *', 'Dừng đợt ưu đãi');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(p.status(p.detail(2)), CampaignStatus.paused);
      await tester.tap(find.text('Bật chương trình'));
      await tester.pumpAndSettle();
      await enter(tester, 'Lý do *', 'Mở lại');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(p.status(p.detail(2)), CampaignStatus.exhausted);
      expect((p.detail(2) as VoucherModel).usedCount, 100);
      await mount(
        tester,
        p,
        const CampaignManagementScreen(kind: CampaignKind.voucher),
      );
      await tester.tap(find.byType(DropdownButton<CampaignStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sắp diễn ra').last);
      await tester.pumpAndSettle();
      expect(find.text('NEXTMONTH'), findsOneWidget);
      expect(find.text('WELCOME10'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
