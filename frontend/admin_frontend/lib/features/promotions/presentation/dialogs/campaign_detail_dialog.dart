import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/campaign_model.dart';
import '../providers/campaigns_provider.dart';
import '../widgets/campaign_status_badge.dart';
import 'campaign_form_dialog.dart';

class CampaignDetailDialog extends StatelessWidget {
  final int id;
  const CampaignDetailDialog({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<CampaignsProvider>();
    final item = p.detail(id);
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: size.width * 2 / 3,
      height: size.height * .85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết ${item.kind.label.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Symbols.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CampaignStatusBadge(status: p.status(item)),
                ),
                const SizedBox(height: 16),
                Text(item.description),
                _line('Mức giảm', item.discountLabel),
                _line('Bắt đầu', campaignDate(item.startsAt)),
                _line('Kết thúc', campaignDate(item.endsAt)),
                if (item is VoucherModel) ...[
                  _line('Mã voucher', item.code),
                  _line(
                    'Loại voucher',
                    item.redeemable ? 'Đổi điểm' : 'Nhập mã',
                  ),
                  if (item.redeemable)
                    _line('Điểm cần đổi', '${item.pointsRequired} điểm'),
                  _line('Giá trị hàng tối thiểu', money(item.minOrderAmount)),
                  _line(
                    'Giảm tối đa',
                    item.maxDiscountAmount == null
                        ? 'Không giới hạn'
                        : money(item.maxDiscountAmount!),
                  ),
                  _line(
                    'Lượt sử dụng',
                    '${item.usedCount} / ${item.usageLimit ?? 'Không giới hạn'}',
                  ),
                  const SizedBox(height: 20),
                  _heading(
                    item.redeemable
                        ? 'Lịch sử đổi điểm (50 lần gần nhất)'
                        : 'Đơn hàng sử dụng mã (50 đơn gần nhất)',
                  ),
                  if (item.usages.isEmpty) const Text('Chưa có lượt sử dụng.'),
                  for (final usage in item.usages)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${usage.orderCode} • ${usage.buyer}'),
                      subtitle: Text(
                        '${campaignDate(usage.usedAt)}${usage.pointsRequired == null ? '' : ' · ${usage.pointsRequired} điểm'}',
                      ),
                      trailing: Text(
                        usage.discountType == 'GIFT'
                            ? 'Gói quà'
                            : usage.discountType == 'PERCENT'
                            ? '${usage.discountAmount}%'
                            : money(usage.discountAmount),
                      ),
                    ),
                  Text(
                    item.redeemable
                        ? 'Số lượt là số mã đã đổi thành công. Mã đã cấp giữ nguyên quyền lợi khi sửa hoặc tắt mẫu.'
                        : 'Số lượt gồm lượt đã dùng và lượt đang giữ cho đơn chờ thanh toán.',
                  ),
                ],
                if (item is PromotionModel) ...[
                  const SizedBox(height: 20),
                  _heading('Sản phẩm áp dụng'),
                  if (item.targetMode == 'NEW_PRODUCTS')
                    const Text(
                      'Tự động áp dụng cho sản phẩm mới tạo trong 7 ngày gần nhất.',
                    ),
                  for (final product in item.products)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Symbols.check_circle),
                      title: Text(product.name),
                    ),
                  const Text(
                    'Một sản phẩm có nhiều khuyến mãi: ưu tiên mức giảm tốt nhất, không cộng dồn phần trăm.',
                  ),
                ],
                const SizedBox(height: 20),
                if (item.history.isNotEmpty) _heading('Lịch sử xử lý'),
                for (final event in item.history.reversed)
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
                        Text(campaignDate(event.createdAt)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: p,
                    child: _ToggleDialog(id: item.id),
                  ),
                ),
                child: Text(
                  item.enabled ? 'Tắt chương trình' : 'Bật chương trình',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: p,
                    child: CampaignFormDialog(kind: item.kind, item: item),
                  ),
                ),
                icon: const Icon(Symbols.edit, size: 18),
                label: const Text('Chỉnh sửa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text('$label: $value'),
  );
  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      value,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );
}

class _ToggleDialog extends StatefulWidget {
  final int id;
  const _ToggleDialog({required this.id});
  @override
  State<_ToggleDialog> createState() => _ToggleDialogState();
}

class _ToggleDialogState extends State<_ToggleDialog> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final p = context.read<CampaignsProvider>();
    final item = p.detail(widget.id);
    return AlertDialog(
      title: Text(item.enabled ? 'Tắt chương trình' : 'Bật chương trình'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const Text(
                'Bật lại không thay đổi thời gian hiệu lực hoặc số lượt đã sử dụng.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await p.toggle(item.id);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) setState(() => _error = e.toString());
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
