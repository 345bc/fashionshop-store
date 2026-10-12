import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/promotions/data/models/campaign_model.dart';
import 'package:zella_admin_flutter/features/promotions/data/repositories/campaign_repository.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/dialogs/campaign_form_dialog.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/providers/campaigns_provider.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/screens/campaign_management_screen.dart';

final now = DateTime(2026, 10, 12, 10);

class FakeCampaigns extends CampaignRepository {
  bool fail = false;
  VoucherModel? submitted;
  FakeCampaigns() {
    catalog = [const PromotionProductModel(1, 'Áo test')];
    for (final reward in [false, true]) {
      replace(
        VoucherModel(
          id: reward ? 2 : 1,
          name: reward ? 'Ưu đãi đổi điểm' : 'Ưu đãi nhập mã',
          description: 'Test',
          startsAt: now.subtract(const Duration(days: 1)),
          endsAt: now.add(const Duration(days: 30)),
          enabled: true,
          code: reward ? 'REWARD-TEST' : 'CODE-TEST',
          discountType: DiscountType.fixed,
          discountValue: 20000,
          redeemable: reward,
          pointsRequired: reward ? 200 : null,
        ),
      );
    }
  }
  @override
  Future<void> load() async {
    if (fail) throw Exception('API không khả dụng');
  }

  @override
  Future<void> detail(CampaignModel item) async {}
  @override
  Future<void> save(CampaignModel item, {required bool creating}) async {
    if (fail) throw Exception('Lưu thất bại');
    submitted = item as VoucherModel;
    replace(item);
  }

  @override
  Future<void> state(CampaignModel item, bool enabled) async {
    if (fail) throw Exception('Cập nhật thất bại');
    replace(item.withState(enabled, []));
  }
}

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
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8080/api/v1',
    ),
  );
  testWidgets('Voucher list separates manual codes and rewards', (
    tester,
  ) async {
    final p = CampaignsProvider(repository: FakeCampaigns(), clock: () => now);
    await mount(
      tester,
      p,
      const CampaignManagementScreen(kind: CampaignKind.voucher),
    );
    expect(find.text('Ưu đãi nhập mã'), findsOneWidget);
    expect(find.text('Ưu đãi đổi điểm'), findsNothing);
    await tester.tap(find.text('Voucher đổi điểm'));
    await tester.pumpAndSettle();
    expect(find.text('Ưu đãi đổi điểm'), findsOneWidget);
    expect(find.text('Ưu đãi nhập mã'), findsNothing);
    expect(find.textContaining('200 điểm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reward edit sends points and stays open when API fails', (
    tester,
  ) async {
    final repo = FakeCampaigns();
    final p = CampaignsProvider(repository: repo, clock: () => now);
    await mount(
      tester,
      p,
      CampaignFormDialog(kind: CampaignKind.voucher, item: p.detail(2)),
    );
    final points = find.widgetWithText(TextFormField, 'Điểm cần đổi *');
    await tester.ensureVisible(points);
    await tester.enterText(points, '350');
    repo.fail = true;
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(CampaignFormDialog), findsOneWidget);
    expect(find.textContaining('Lưu thất bại'), findsOneWidget);
    expect(repo.submitted, isNull);
    expect(tester.takeException(), isNull);
  });
  test(
    'Failed state update does not optimistically disable the template',
    () async {
      final repo = FakeCampaigns();
      final p = CampaignsProvider(repository: repo, clock: () => now);
      repo.fail = true;
      await expectLater(p.toggle(2), throwsException);
      expect(p.detail(2).enabled, isTrue);
      repo.fail = false;
      await p.toggle(2);
      expect(p.detail(2).enabled, isFalse);
    },
  );
  testWidgets('API errors display retry and recover', (tester) async {
    final repo = FakeCampaigns()..fail = true;
    final p = CampaignsProvider(repository: repo, clock: () => now);
    await mount(
      tester,
      p,
      const CampaignManagementScreen(kind: CampaignKind.voucher),
    );
    expect(find.textContaining('API không khả dụng'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Ưu đãi nhập mã'), findsOneWidget);
  });
}
