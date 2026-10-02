import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../data/models/product_review_model.dart';
import '../providers/feedback_provider.dart';
import '../dialogs/feedback_detail_dialog.dart';
import 'review_status_badge.dart';

class FeedbackWorkspace extends StatelessWidget {
  final FeedbackProvider provider;
  const FeedbackWorkspace({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final selected = provider.selectedReview;
    if (selected == null) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Text(
            'Không có phản hồi phù hợp. Bạn có thể đổi bộ lọc để xem các đánh giá khác.',
          ),
        ),
      );
    }
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final list = _list();
            final detail = _InlineReply(
              key: ValueKey(selected.id),
              provider: provider,
              review: selected,
            );
            if (c.maxWidth < 850) {
              return Column(
                children: [
                  SizedBox(height: 260, child: list),
                  const SizedBox(height: 16),
                  SizedBox(height: 650, child: detail),
                ],
              );
            }
            return SizedBox(
              height: (MediaQuery.sizeOf(context).height * .68).clamp(
                480.0,
                780.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: list),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: detail),
                ],
              ),
            );
          },
        ),
        PaginationFooter(
          currentPage: provider.currentPage,
          totalPages: (provider.filteredItems.length / provider.pageSize)
              .ceil(),
          totalElements: provider.filteredItems.length,
          pageSize: provider.pageSize,
          onPageChanged: provider.setPage,
        ),
      ],
    );
  }

  Widget _list() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: ListView.separated(
      key: const ValueKey('review-list'),
      itemCount: provider.pageItems.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = provider.pageItems[index];
        return Material(
          color: r.id == provider.selectedReview?.id
              ? AppTheme.surface
              : Colors.transparent,
          child: InkWell(
            key: ValueKey('review-${r.id}'),
            onTap: () => provider.selectReview(r.id),
            hoverColor: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ReviewStars(rating: r.rating),
                  const SizedBox(height: 6),
                  Text(r.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      Text(DateFormat('dd/MM HH:mm').format(r.createdAt)),
                      Text(
                        r.visibility == ReviewVisibility.hidden
                            ? 'Đã ẩn'
                            : r.adminReply == null
                            ? 'Chưa trả lời'
                            : 'Đã trả lời',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _InlineReply extends StatefulWidget {
  final FeedbackProvider provider;
  final ProductReviewModel review;
  const _InlineReply({super.key, required this.provider, required this.review});
  @override
  State<_InlineReply> createState() => _InlineReplyState();
}

class _InlineReplyState extends State<_InlineReply> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _reply;
  @override
  void initState() {
    super.initState();
    _reply = TextEditingController(
      text:
          widget.provider.drafts[widget.review.id] ??
          widget.review.adminReply ??
          '',
    );
    _reply.addListener(
      () => widget.provider.drafts[widget.review.id] = _reply.text,
    );
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                r.customerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ReviewStatusBadge(visibility: r.visibility),
              TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: widget.provider,
                    child: FeedbackDetailDialog(reviewId: r.id),
                  ),
                ),
                child: const Text('Lịch sử / xử lý nội dung'),
              ),
            ],
          ),
          Text(
            '${r.customerId == null ? 'Khách vãng lai • ' : ''}${r.customerEmail}',
          ),
          const SizedBox(height: 8),
          Text('${r.orderCode} • ${r.sku}'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => widget.provider.openProduct(r.productId),
              icon: const Icon(Icons.checkroom, size: 18),
              label: Text(r.productName),
            ),
          ),
          ReviewStars(rating: r.rating),
          const SizedBox(height: 16),
          SelectableText(r.comment),
          const SizedBox(height: 24),
          if (r.adminReply != null) ...[
            const Text(
              'Shop đã trả lời',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(r.adminReply!),
            const SizedBox(height: 16),
          ],
          Form(
            key: _form,
            child: TextFormField(
              key: const ValueKey('inline-reply'),
              controller: _reply,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Trả lời khách hàng',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập câu trả lời'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                widget.provider.replyAndNext(r.id, _reply.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu câu trả lời mẫu')),
                );
              },
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(
                r.adminReply == null ? 'Gửi & xem tiếp' : 'Cập nhật & xem tiếp',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
