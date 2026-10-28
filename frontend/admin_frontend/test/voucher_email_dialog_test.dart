import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/features/promotions/data/models/campaign_model.dart';
import 'package:zella_admin_flutter/features/promotions/data/models/voucher_email_model.dart';
import 'package:zella_admin_flutter/features/promotions/data/repositories/campaign_repository.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/dialogs/voucher_email_dialog.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/providers/campaigns_provider.dart';

class EmailCampaigns extends CampaignRepository {
  int previewCalls = 0, sendCalls = 0;
  Set<String>? selectedTiers;
  bool empty = false, failSend = false;

  @override
  Future<VoucherEmailPreview> previewVoucherEmail(
    int id,
    Set<String> tiers,
  ) async {
    previewCalls++;
    selectedTiers = Set.of(tiers);
    return VoucherEmailPreview(
      eligible: empty ? 0 : 3,
      alreadyQueued: empty ? 0 : 1,
      invalidEmails: 0,
      toQueue: empty ? 0 : 2,
      remainingUses: 10,
      audienceKey: 'confirmed-audience',
      subject: 'ZELLA - MEMBER20',
      emailBody: 'Mã voucher: MEMBER20',
      sample: empty
          ? []
          : const [
              VoucherEmailRecipientModel(
                name: 'An',
                email: 'an@gmail.com',
                tier: 'GOLD',
              ),
            ],
    );
  }

  @override
  Future<VoucherEmailSendResult> sendVoucherEmail(
    int id,
    Set<String> tiers,
    String audienceKey,
  ) async {
    sendCalls++;
    selectedTiers = Set.of(tiers);
    expect(audienceKey, 'confirmed-audience');
    if (failSend) {
      throw Exception('Danh sách đã thay đổi. Vui lòng xem trước lại.');
    }
    return const VoucherEmailSendResult(2, 1);
  }
}

Future<void> mount(WidgetTester tester, EmailCampaigns repository) async {
  tester.view.physicalSize = const Size(1300, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final now = DateTime(2026, 10, 21);
  final voucher = VoucherModel(
    id: 1,
    name: 'Ưu đãi thành viên',
    description: '',
    startsAt: now.subtract(const Duration(days: 1)),
    endsAt: now.add(const Duration(days: 10)),
    enabled: true,
    code: 'MEMBER20',
    discountType: DiscountType.percent,
    discountValue: 20,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VoucherEmailDialog(
          voucher: voucher,
          provider: CampaignsProvider(repository: repository, clock: () => now),
        ),
      ),
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

  testWidgets('Preview selected ranks before confirming a send', (
    tester,
  ) async {
    final repository = EmailCampaigns();
    await mount(tester, repository);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Xem trước'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Bạc'));
    await tester.tap(find.widgetWithText(FilterChip, 'Vàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trước'));
    await tester.pumpAndSettle();
    expect(repository.selectedTiers, {'SILVER', 'GOLD'});
    expect(repository.sendCalls, 0);
    expect(find.text('an@gmail.com'), findsOneWidget);
    expect(find.text('Sẽ gửi: 2 khách'), findsOneWidget);
    await tester.tap(find.text('Gửi email cho 2 khách'));
    await tester.pumpAndSettle();
    expect(repository.sendCalls, 1);
    expect(
      find.textContaining('Đã xếp hàng gửi voucher cho 2 khách'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Gửi email'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changing ranks clears preview and disables sending', (
    tester,
  ) async {
    final repository = EmailCampaigns();
    await mount(tester, repository);
    await tester.tap(find.widgetWithText(FilterChip, 'Vàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trước'));
    await tester.pumpAndSettle();
    expect(find.text('Sẽ gửi: 2 khách'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Thường'));
    await tester.pumpAndSettle();
    expect(find.text('Sẽ gửi: 2 khách'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Gửi email'),
          )
          .onPressed,
      isNull,
    );
    expect(repository.sendCalls, 0);
  });

  testWidgets('No eligible recipients prevents sending', (tester) async {
    final repository = EmailCampaigns()..empty = true;
    await mount(tester, repository);
    await tester.tap(find.widgetWithText(FilterChip, 'Thường'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trước'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không có khách mới phù hợp'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Gửi email cho 0 khách'),
          )
          .onPressed,
      isNull,
    );
    expect(repository.sendCalls, 0);
  });

  testWidgets('Stale audience failure requires a new preview', (tester) async {
    final repository = EmailCampaigns()..failSend = true;
    await mount(tester, repository);
    await tester.tap(find.widgetWithText(FilterChip, 'Bạc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trước'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi email cho 2 khách'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Danh sách đã thay đổi'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Gửi email'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Xem trước'));
    await tester.pumpAndSettle();
    expect(repository.previewCalls, 2);
    expect(repository.sendCalls, 1);
  });
}
