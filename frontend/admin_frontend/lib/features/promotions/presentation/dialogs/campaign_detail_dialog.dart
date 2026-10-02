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
                icon: const Icon(Icons.close),
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
                  _heading('Lịch sử sử dụng mẫu'),
                  if (item.usages.isEmpty) const Text('Chưa có lượt sử dụng.'),
                  for (final usage in item.usages)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${usage.orderCode} • ${usage.buyer}'),
                      subtitle: Text(campaignDate(usage.usedAt)),
                      trailing: Text(money(usage.discountAmount)),
                    ),
                  const Text(
                    'Lịch sử đang hiển thị một số lượt mẫu; chưa kết nối với đơn hàng thực tế.',
                  ),
                ],
                if (item is PromotionModel) ...[
                  const SizedBox(height: 20),
                  _heading('Sản phẩm áp dụng'),
                  for (final product in item.products)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(product.name),
                    ),
                  const Text(
                    'Một sản phẩm có nhiều khuyến mãi: ưu tiên mức giảm tốt nhất, không cộng dồn phần trăm.',
                  ),
                ],
                const SizedBox(height: 20),
                _heading('Lịch sử xử lý'),
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
                icon: const Icon(Icons.edit_outlined, size: 18),
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
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

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
              const Text(
                'Bật lại không thay đổi thời gian hiệu lực hoặc số lượt đã sử dụng.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Lý do *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Vui lòng nhập lý do'
                    : null,
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
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            p.toggle(item.id, _reason.text);
            Navigator.pop(context);
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
