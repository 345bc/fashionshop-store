import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/campaign_model.dart';
import '../../data/repositories/campaign_repository.dart';
import '../providers/campaigns_provider.dart';

class CampaignFormDialog extends StatefulWidget {
  final CampaignKind kind;
  final CampaignModel? item;
  const CampaignFormDialog({super.key, required this.kind, this.item});
  @override
  State<CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<CampaignFormDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _description = TextEditingController(),
      _code = TextEditingController();
  final _value = TextEditingController(),
      _min = TextEditingController(),
      _cap = TextEditingController();
  final _limit = TextEditingController();
  late DateTime _start, _end;
  bool _enabled = true;
  DiscountType _type = DiscountType.percent;
  final Set<int> _products = {};
  String? _error;
  bool get _voucher => widget.kind == CampaignKind.voucher;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name.text = item?.name ?? '';
    _description.text = item?.description ?? '';
    _start = item?.startsAt ?? DateTime.now();
    _end = item?.endsAt ?? _start.add(const Duration(days: 30));
    _enabled = item?.enabled ?? true;
    if (item is VoucherModel) {
      _code.text = item.code;
      _type = item.discountType;
      _value.text = '${item.discountValue}';
      _min.text = '${item.minOrderAmount}';
      _cap.text = item.maxDiscountAmount?.toString() ?? '';
      _limit.text = item.usageLimit?.toString() ?? '';
    } else {
      _value.text = item is PromotionModel ? '${item.discountPercent}' : '10';
      _min.text = '0';
      if (item is PromotionModel) {
        _products.addAll(item.products.map((p) => p.id));
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _code,
      _value,
      _min,
      _cap,
      _limit,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final p = context.read<CampaignsProvider>();
    try {
      final item = widget.item;
      final id = item?.id ?? p.nextId();
      final CampaignModel value = _voucher
          ? VoucherModel(
              id: id,
              name: _name.text.trim(),
              description: _description.text.trim(),
              startsAt: _start,
              endsAt: _end,
              enabled: _enabled,
              code: _code.text.trim().toUpperCase(),
              discountType: _type,
              discountValue: int.parse(_value.text),
              minOrderAmount: int.parse(_min.text),
              maxDiscountAmount: _type == DiscountType.percent
                  ? int.tryParse(_cap.text)
                  : null,
              usageLimit: int.tryParse(_limit.text),
              usedCount: item is VoucherModel ? item.usedCount : 0,
              usages: item is VoucherModel ? item.usages : const [],
            )
          : PromotionModel(
              id: id,
              name: _name.text.trim(),
              description: _description.text.trim(),
              startsAt: _start,
              endsAt: _end,
              enabled: _enabled,
              discountPercent: int.parse(_value.text),
              products: CampaignRepository.catalog
                  .where((product) => _products.contains(product.id))
                  .toList(),
            );
      p.save(value, creating: item == null);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu chương trình mẫu')));
    } on ArgumentError catch (e) {
      setState(() => _error = '${e.message}');
    }
  }

  Future<void> _pickDate(bool start) async {
    final initial = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = result;
      } else {
        _end = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final used =
        widget.item is VoucherModel &&
        (widget.item as VoucherModel).usedCount > 0;
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
                  '${widget.item == null ? 'Thêm' : 'Chỉnh sửa'} ${widget.kind.label.toLowerCase()}',
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
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Dữ liệu mẫu • Chưa ảnh hưởng đến đơn hàng và giá bán thực tế.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Tên chương trình *',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập tên'
                          : null,
                    ),
                    if (_voucher)
                      TextFormField(
                        controller: _code,
                        maxLength: 50,
                        readOnly: used,
                        decoration: InputDecoration(
                          labelText: 'Mã voucher *',
                          helperText: used
                              ? 'Mã đã có lượt dùng, không đổi mã.'
                              : '3–50 ký tự A–Z, 0–9, _ hoặc -; tự chuyển chữ hoa.',
                        ),
                        validator: (v) =>
                            RegExp(r'^[A-Z0-9_-]{3,50}$')
                                .hasMatch((v ?? '').trim().toUpperCase())
                            ? null
                            : 'Mã không hợp lệ',
                      ),
                    TextFormField(
                      controller: _description,
                      maxLength: 500,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 20),
                    _heading('Mức giảm'),
                    if (_voucher)
                      DropdownButtonFormField<DiscountType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Loại giảm',
                        ),
                        items: [
                          for (final type in DiscountType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                        ],
                        onChanged: (type) => setState(() => _type = type!),
                      ),
                    _number(
                      _value,
                      !_voucher || _type == DiscountType.percent
                          ? 'Giảm (%) *'
                          : 'Giảm (VND) *',
                      max: !_voucher || _type == DiscountType.percent
                          ? 100
                          : null,
                    ),
                    if (_voucher && _type == DiscountType.percent)
                      _number(_cap, 'Giảm tối đa (VND)', optional: true),
                    if (_voucher) ...[
                      const SizedBox(height: 20),
                      _heading('Điều kiện & lượt sử dụng'),
                      _number(_min, 'Giá trị hàng tối thiểu (VND) *', min: 0),
                      _number(
                        _limit,
                        'Tổng lượt dùng',
                        optional: true,
                        max: 2147483647,
                      ),
                      const Text('Để trống tổng lượt dùng nếu không giới hạn.'),
                    ] else ...[
                      const SizedBox(height: 20),
                      _heading('Sản phẩm áp dụng *'),
                      const Text(
                        'Danh sách sản phẩm mẫu; giảm cho tất cả biến thể của sản phẩm đã chọn.',
                      ),
                      for (final product in CampaignRepository.catalog)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(product.name),
                          value: _products.contains(product.id),
                          onChanged: (selected) => setState(() {
                            if (selected == true) {
                              _products.add(product.id);
                            } else {
                              _products.remove(product.id);
                            }
                          }),
                        ),
                    ],
                    const SizedBox(height: 20),
                    _heading('Thời gian hiệu lực'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(true),
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text('Bắt đầu: ${campaignDate(_start)}'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(false),
                          icon: const Icon(Icons.event_outlined),
                          label: Text('Kết thúc: ${campaignDate(_end)}'),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bật chương trình'),
                      subtitle: const Text(
                        'Chỉ có hiệu lực trong khoảng thời gian đã chọn.',
                      ),
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _save, child: const Text('Lưu')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      value,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );
  Widget _number(
    TextEditingController controller,
    String label, {
    bool optional = false,
    int min = 1,
    int? max,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      if (optional && (value ?? '').isEmpty) return null;
      final number = int.tryParse(value ?? '');
      if (number == null || number < min || (max != null && number > max)) {
        return 'Nhập số nguyên từ $min${max != null ? ' đến $max' : ' trở lên'}';
      }
      return null;
    },
  );
}
