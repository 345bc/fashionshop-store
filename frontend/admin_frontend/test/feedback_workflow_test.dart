import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/feedback/data/models/product_review_model.dart';
import 'package:zella_admin_flutter/features/feedback/presentation/dialogs/feedback_detail_dialog.dart';
import 'package:zella_admin_flutter/features/feedback/presentation/providers/feedback_provider.dart';
import 'package:zella_admin_flutter/features/feedback/presentation/screens/feedback_screen.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    FeedbackProvider p,
    Widget child, {
    double width = 1600,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
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

  final replyField = find.byKey(const ValueKey('inline-reply'));
  testWidgets(
    'Inbox replies inline and moves to next pending review; drafts survive selection',
    (tester) async {
      final p = FeedbackProvider();
      await mount(tester, p, const FeedbackScreen());
      expect(p.filter, ReviewFilter.unanswered);
      expect(p.selectedReview!.id, 1);
      expect(
        p.filteredItems.every(
          (r) =>
              r.adminReply == null && r.visibility == ReviewVisibility.visible,
        ),
        isTrue,
      );
      await tester.ensureVisible(find.text('Gửi & xem tiếp'));
      await tester.tap(find.text('Gửi & xem tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập câu trả lời'), findsOneWidget);
      await tester.enterText(replyField, 'Shop cảm ơn bạn!');
      expect(p.drafts[1], 'Shop cảm ơn bạn!');
      await tester.ensureVisible(find.text('Hoàng Mai Ly').first);
      await tester.tap(find.text('Hoàng Mai Ly').first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('review-list')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('review-1')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(replyField).controller!.text,
        'Shop cảm ơn bạn!',
      );
      await tester.ensureVisible(find.text('Gửi & xem tiếp'));
      await tester.tap(find.text('Gửi & xem tiếp'));
      await tester.pumpAndSettle();
      expect(p.detail(1).adminReply, 'Shop cảm ơn bạn!');
      expect(p.selectedReview!.id, 3);
      expect(p.drafts.containsKey(1), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Product catalog filters parent/child and preserves filters when returning',
    (tester) async {
      final p = FeedbackProvider();
      await mount(tester, p, const FeedbackScreen());
      await tester.tap(find.text('Theo sản phẩm'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<int>, 'Danh mục cha'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nữ').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<int>, 'Danh mục con'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áo nữ').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'SP-1');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(p.catalogIds, [1]);
      await tester.tap(find.text('Áo sơ mi nữ lụa cổ nơ'));
      await tester.pumpAndSettle();
      expect(p.filteredItems.every((r) => r.productId == 1), isTrue);
      await tester.tap(find.text('Danh sách sản phẩm'));
      await tester.pumpAndSettle();
      expect(p.catalogFilters.query, 'SP-1');
      expect(p.catalogFilters.parentId, 1);
      expect(p.catalogFilters.categoryId, 11);
      expect(p.catalogIds, [1]);
      await tester.tap(find.text('Cần xử lý (12)'));
      await tester.pumpAndSettle();
      expect(p.query, isEmpty);
      expect(p.filter, ReviewFilter.unanswered);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Inbox pagination and search/rating filters select relevant review',
    (tester) async {
      final p = FeedbackProvider();
      await mount(tester, p, const FeedbackScreen(), width: 700);
      await tester.ensureVisible(find.byIcon(Icons.chevron_right));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(p.currentPage, 1);
      expect(p.pageItems.any((r) => r.id == p.selectedReview!.id), isTrue);
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'ORD-DEMO-104');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(p.selectedReview!.orderCode, 'ORD-DEMO-104');
      await tester.tap(find.byType(DropdownButton<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 sao').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Không có phản hồi phù hợp.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Moderation still requires reason and preserves original review',
    (tester) async {
      final p = FeedbackProvider();
      final original = p.detail(1);
      await mount(tester, p, const FeedbackDetailDialog(reviewId: 1));
      await tester.ensureVisible(find.text('Ẩn đánh giá'));
      await tester.tap(find.text('Ẩn đánh giá'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập lý do'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Chứa thông tin cá nhân',
      );
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(p.detail(1).visibility, ReviewVisibility.hidden);
      expect(p.detail(1).comment, original.comment);
      expect(p.detail(1).rating, original.rating);
      expect(tester.takeException(), isNull);
    },
  );
}
