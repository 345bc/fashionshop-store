import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/product_review_model.dart';
import '../providers/feedback_provider.dart';
import '../widgets/review_status_badge.dart';

class FeedbackDetailDialog extends StatefulWidget {
  final int reviewId;
  const FeedbackDetailDialog({super.key, required this.reviewId});
  @override
  State<FeedbackDetailDialog> createState() => _FeedbackDetailDialogState();
}

class _FeedbackDetailDialogState extends State<FeedbackDetailDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _reply;
  @override
  void initState() {
    super.initState();
    _reply = TextEditingController(
      text: context.read<FeedbackProvider>().detail(widget.reviewId).adminReply,
    );
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedbackProvider>();
    final r = provider.detail(widget.reviewId);
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: size.width * 2 / 3,
      height: size.height * .85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết phản hồi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'RV-${r.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ReviewStatusBadge(visibility: r.visibility),
                    ReviewStars(rating: r.rating),
                    const Chip(
                      label: Text('Đã mua hàng'),
                      avatar: Icon(Icons.verified_outlined, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section('Khách hàng & đơn hàng', [
                  _info(
                    'Khách hàng',
                    '${r.customerName}${r.customerId == null ? ' • Khách vãng lai' : ''}',
                  ),
                  _info('Email', r.customerEmail),
                  _info('Đơn hàng', r.orderCode),
                  _info('Sản phẩm', r.productName),
                  _info('SKU', r.sku),
                  _info('Ngày gửi', _date(r.createdAt)),
                ]),
                _section('Đánh giá của khách hàng', [
                  SelectableText(r.comment),
                ]),
                if (r.moderationReason != null)
                  _section('Lần xử lý nội dung gần nhất', [
                    Text(r.moderationReason!),
                  ]),
                _section('Trả lời khách hàng', [
                  if (r.repliedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Đã trả lời lúc ${_date(r.repliedAt!)}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  Form(
                    key: _form,
                    child: TextFormField(
                      controller: _reply,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText:
                            'Nhập câu trả lời sẽ hiển thị cùng đánh giá...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập câu trả lời'
                          : value.trim().length > 1000
                          ? 'Tối đa 1000 ký tự'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        provider.reply(r.id, _reply.text, 'CSKH (mẫu)');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã lưu câu trả lời mẫu'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: Text(
                        r.adminReply == null
                            ? 'Gửi trả lời'
                            : 'Cập nhật trả lời',
                      ),
                    ),
                  ),
                ]),
                _section('Kiểm soát nội dung', [
                  const Text(
                    'Chỉ ẩn nội dung vi phạm, spam hoặc chứa thông tin cá nhân. Đánh giá ít sao vẫn được hiển thị.',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _moderate(provider, r),
                      icon: Icon(
                        r.visibility == ReviewVisibility.visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        r.visibility == ReviewVisibility.visible
                            ? 'Ẩn đánh giá'
                            : 'Hiển thị lại',
                      ),
                    ),
                  ),
                ]),
                _section('Lịch sử xử lý', [
                  for (final event in r.history.reversed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.action,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(event.note),
                          Text(
                            '${_date(event.createdAt)} • ${event.actor}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moderate(
    FeedbackProvider provider,
    ProductReviewModel review,
  ) async {
    final value = review.visibility == ReviewVisibility.visible
        ? ReviewVisibility.hidden
        : ReviewVisibility.visible;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ModerationDialog(hiding: value == ReviewVisibility.hidden),
    );
    if (reason == null || !mounted) return;
    provider.moderate(review.id, value, reason, 'CSKH (mẫu)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value == ReviewVisibility.hidden
              ? 'Đã ẩn đánh giá mẫu'
              : 'Đã hiển thị lại đánh giá mẫu',
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text('$label: $value'),
  );
  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _ModerationDialog extends StatefulWidget {
  final bool hiding;
  const _ModerationDialog({required this.hiding});
  @override
  State<_ModerationDialog> createState() => _ModerationDialogState();
}

class _ModerationDialogState extends State<_ModerationDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.hiding ? 'Ẩn đánh giá' : 'Hiển thị lại đánh giá'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _form,
        child: TextFormField(
          controller: _reason,
          maxLength: 500,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Lý do xử lý *',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập lý do'
              : null,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      ElevatedButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
