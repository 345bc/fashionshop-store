import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/campaign_model.dart';

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
  final _points = TextEditingController();
  bool _redeemable = false;
  late DateTime _start, _end;
  bool _enabled = true;
  DiscountType _type = DiscountType.percent;
  final Set<int> _products = {};
  String? _error;
  bool _saving = false;
  String _targetMode = 'SELECTED';
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
    _redeemable = context.read<CampaignsProvider>().rewardScope;
    if (item is VoucherModel) {
      _redeemable = item.redeemable;
      _points.text = item.pointsRequired?.toString() ?? '';
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
        _targetMode = item.targetMode;
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
      _points,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
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
              discountValue: _type == DiscountType.gift
                  ? 0
                  : int.parse(_value.text),
              redeemable: _redeemable,
              pointsRequired: _redeemable ? int.tryParse(_points.text) : null,
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
              targetMode: _targetMode,
              products: p.catalog
                  .where((product) => _products.contains(product.id))
                  .toList(),
            );
      await p.save(value, creating: item == null);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu chương trình')));
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = '${e.message}');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
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
                icon: const Icon(Symbols.close),
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
                      'Thay đổi được lưu vào hệ thống. Voucher đã cấp cho khách giữ nguyên quyền lợi.',
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
                    if (_voucher) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Voucher đổi điểm'),
                        subtitle: const Text(
                          'Khách dùng điểm thưởng để đổi mã riêng, sử dụng một lần trong 30 ngày.',
                        ),
                        value: _redeemable,
                        onChanged: used || _saving
                            ? null
                            : (value) => setState(() {
                                _redeemable = value;
                                if (!value && _type == DiscountType.gift) {
                                  _type = DiscountType.fixed;
                                }
                              }),
                      ),
                      if (_redeemable)
                        _number(_points, 'Điểm cần đổi *', max: 2147483647),
                    ],
                    _heading('Mức giảm'),
                    if (_voucher)
                      DropdownButtonFormField<DiscountType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Loại giảm',
                        ),
                        items: [
                          for (final type in DiscountType.values.where(
                            (t) => _redeemable || t != DiscountType.gift,
                          ))
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                        ],
                        onChanged: (type) => setState(() => _type = type!),
                      ),
                    if (_type != DiscountType.gift)
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
                      Text(
                        _redeemable
                            ? 'Giới hạn số lần đổi điểm. Mỗi mã cấp cho khách dùng một lần.'
                            : 'Để trống tổng lượt dùng nếu không giới hạn.',
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      _heading('Sản phẩm áp dụng *'),
                      DropdownButtonFormField<String>(
                        initialValue: _targetMode,
                        items: const [
                          DropdownMenuItem(
                            value: 'SELECTED',
                            child: Text('Sản phẩm được chọn'),
                          ),
                          DropdownMenuItem(
                            value: 'NEW_PRODUCTS',
                            child: Text('Sản phẩm mới trong 7 ngày'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _targetMode = value!),
                      ),
                      const Text(
                        'Giảm cho tất cả biến thể. Sản phẩm mới tự ngừng hưởng giảm khi đủ 7 ngày.',
                      ),
                      if (_targetMode == 'SELECTED')
                        for (final product
                            in context.watch<CampaignsProvider>().catalog)
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
                          icon: const Icon(Symbols.calendar_today),
                          label: Text('Bắt đầu: ${campaignDate(_start)}'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(false),
                          icon: const Icon(Symbols.event),
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
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
              ),
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
