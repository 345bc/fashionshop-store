import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/voucher_email_model.dart';
import '../providers/campaigns_provider.dart';

class VoucherEmailDialog extends StatefulWidget {
  final VoucherModel voucher;
  final CampaignsProvider provider;
  const VoucherEmailDialog({
    super.key,
    required this.voucher,
    required this.provider,
  });

  @override
  State<VoucherEmailDialog> createState() => _VoucherEmailDialogState();
}

class _VoucherEmailDialogState extends State<VoucherEmailDialog> {
  static const _labels = {
    'STANDARD': 'Thường',
    'SILVER': 'Bạc',
    'GOLD': 'Vàng',
  };
  final Set<String> _tiers = {};
  VoucherEmailPreview? _preview;
  bool _busy = false;
  String? _error, _success;

  Future<void> _loadPreview() async {
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final preview = await widget.provider.previewVoucherEmail(
        widget.voucher.id,
        Set.of(_tiers),
      );
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final preview = _preview;
    if (_busy || preview == null || preview.toQueue == 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.provider.sendVoucherEmail(
        widget.voucher.id,
        Set.of(_tiers),
        preview.audienceKey,
      );
      if (mounted) {
        setState(() {
          _preview = null;
          _success =
              'Đã xếp hàng gửi voucher cho ${result.queued} khách. '
              'Email sẽ được gửi lần lượt. '
              '${result.alreadyQueued} khách đã xếp hàng trước đó được bỏ qua.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _preview = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text('Gửi voucher ${widget.voucher.code}'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chọn hạng thành viên nhận email'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final tier in _labels.entries)
                      FilterChip(
                        label: Text(tier.value),
                        selected: _tiers.contains(tier.key),
                        onSelected: _busy || _success != null
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _tiers.add(tier.key);
                                  } else {
                                    _tiers.remove(tier.key);
                                  }
                                  _preview = null;
                                  _error = null;
                                });
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gửi cho khách đang hoạt động, có email hợp lệ. '
                  'Mỗi email chỉ được xếp hàng một lần cho cùng voucher. '
                  'Mã dùng chung vẫn áp dụng theo điều kiện hiện tại của voucher.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LinearProgressIndicator(),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                if (_success != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _success!,
                      style: const TextStyle(color: AppTheme.success),
                    ),
                  ),
                if (preview != null) ...[
                  const Divider(height: 28),
                  Text(
                    'Sẽ gửi: ${preview.toQueue} khách',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Đã xếp hàng trước đó: ${preview.alreadyQueued} • Email không hợp lệ: ${preview.invalidEmails}',
                  ),
                  if (preview.remainingUses != null)
                    Text(
                      'Voucher còn ${preview.remainingUses} lượt sử dụng. Email không giữ trước lượt.',
                    ),
                  if (preview.toQueue == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Không có khách mới phù hợp để gửi. Bạn có thể chọn hạng khác.',
                      ),
                    ),
                  if (preview.sample.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Danh sách xem trước (tối đa 20 khách)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    for (final recipient in preview.sample)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(recipient.name),
                        subtitle: Text(recipient.email),
                        trailing: Text(
                          _labels[recipient.tier] ?? recipient.tier,
                        ),
                      ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Xem nội dung email mẫu'),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            '${preview.subject}\n\n${preview.emailBody}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (_success == null) ...[
            OutlinedButton(
              onPressed: _busy || _tiers.isEmpty ? null : _loadPreview,
              child: const Text('Xem trước'),
            ),
            ElevatedButton.icon(
              onPressed: _busy || preview == null || preview.toQueue == 0
                  ? null
                  : _send,
              icon: const Icon(Icons.mail_outline, size: 18),
              label: Text(
                'Gửi email${preview == null ? '' : ' cho ${preview.toQueue} khách'}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
