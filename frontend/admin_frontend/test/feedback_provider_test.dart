import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/features/feedback/data/models/product_review_model.dart';
import 'package:zella_admin_flutter/features/feedback/data/repositories/feedback_repository.dart';
import 'package:zella_admin_flutter/features/feedback/presentation/providers/feedback_provider.dart';

class FailingFeedbackRepository extends FeedbackRepository {
  FailingFeedbackRepository() : super.demo();

  @override
  Future<ProductReviewModel> reply(int id, String text, String actor) async {
    throw Exception('Network unavailable');
  }
}

void main() {
  test('Failed reply preserves the draft and selected review', () async {
    final p = FeedbackProvider(repository: FailingFeedbackRepository());
    p.selectReview(1);
    p.drafts[1] = 'Cảm ơn bạn';
    await expectLater(p.replyAndNext(1, p.drafts[1]!), throwsException);
    expect(p.selectedReview!.id, 1);
    expect(p.detail(1).adminReply, isNull);
    expect(p.drafts[1], 'Cảm ơn bạn');
    expect(p.saving, isFalse);
    expect(p.error, isNotNull);
  });

  test('Reply and moderation enforce input limits before saving', () async {
    final p = FeedbackProvider(repository: FeedbackRepository.demo());
    for (final text in ['', '   ', 'x' * 1001]) {
      await expectLater(p.reply(1, text, 'support'), throwsArgumentError);
    }
    for (final reason in ['', '   ', 'x' * 501]) {
      await expectLater(
        p.moderate(1, ReviewVisibility.hidden, reason, 'support'),
        throwsArgumentError,
      );
    }
    expect(p.detail(1).history.length, 1);
    expect(p.detail(1).visibility, ReviewVisibility.visible);
  });

  test(
    'Hidden reviews do not contribute to the average or pending queue',
    () async {
      final p = FeedbackProvider(repository: FeedbackRepository.demo());
      await p.moderate(
        1,
        ReviewVisibility.hidden,
        'Thông tin cá nhân',
        'support',
      );
      final visible = p.items
          .where((r) => r.visibility == ReviewVisibility.visible)
          .toList();
      expect(
        p.averageRating,
        visible.fold<int>(0, (n, r) => n + r.rating) / visible.length,
      );
      expect(p.filteredItems.any((r) => r.id == 1), isFalse);
      await p.moderate(1, ReviewVisibility.visible, 'Đã kiểm tra', 'support');
      expect(p.filteredItems.any((r) => r.id == 1), isTrue);
      expect(p.detail(1).rating, 5);
    },
  );
}
