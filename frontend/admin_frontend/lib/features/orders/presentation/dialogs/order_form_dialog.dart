import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../providers/orders_provider.dart';

class OrderFormDialog extends StatefulWidget {
  const OrderFormDialog({super.key});
  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderLine {
  int? variantId;
  final quantity = TextEditingController(text: '1');
  void dispose() => quantity.dispose();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController(),
      _note = TextEditingController(),
      _shipping = TextEditingController(text: '0');
  final _lines = <_OrderLine>[_OrderLine()];
  late final Future<
    ({
      List<Map<String, dynamic>> customers,
      List<InventoryResponseModel> variants,
    })
  >
  _options;
  int? _customer;

  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _options = context.read<OrdersProvider>().options();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _note, _shipping]) {
      c.dispose();
    }
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true || _lines.isEmpty) return;
    setState(() => _saving = true);
    try {
      await context.read<OrdersProvider>().create({
        'customerUserId': _customer,
        'recipientName': _name.text.trim(),
        'recipientPhone': _phone.text.trim(),
        'address': _address.text.trim(),
        'note': _note.text.trim(),
        'shippingFee': num.parse(_shipping.text),
        'paymentMethod': 'ONLINE',
        'items': _lines
            .map(
              (l) => {
                'variantId': l.variantId,
                'quantity': int.parse(l.quantity.text),
              },
            )
            .toList(),
      });
      if (!mounted) return;
      context.read<InventoryProvider>().loadItems();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Vui lòng nhập thông tin' : null;
  @override
  Widget build(BuildContext context) => ZellaFormDialog(
    title: 'Tạo đơn hàng',
    width: MediaQuery.sizeOf(context).width * 2 / 3,
    height: MediaQuery.sizeOf(context).height * .8,
    isLoading: _saving,
    confirmText: 'Tạo đơn và giữ hàng',
    onCancel: () => Navigator.pop(context),
    onConfirm: _save,
    content: FutureBuilder(
      future: _options,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final options = snapshot.data!;
        final total =
            _lines.fold<num>(0, (sum, l) {
              final found = options.variants.where(
                (v) => v.variantId == l.variantId,
              );
              return sum +
                  (found.isEmpty
                      ? 0
                      : found.first.price *
                            (int.tryParse(l.quantity.text) ?? 0));
            }) +
            (num.tryParse(_shipping.text) ?? 0);
        return Form(
          key: _form,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _customer ?? -1,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tài khoản khách hàng (không bắt buộc)',
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Khách vãng lai — không cần tài khoản'),
                  ),
                  ...options.customers.map(
                    (c) => DropdownMenuItem(
                      value: c['userId'] as int,
                      child: Text(
                        '${c["fullName"]} — ${c["email"]}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (id) => setState(() {
                        _customer = id == -1 ? null : id;
                        if (id == -1) return;
                        final c = options.customers.firstWhere(
                          (c) => c['userId'] == id,
                        );
                        _name.text = c['fullName']?.toString() ?? '';
                        _phone.text = c['phone']?.toString() ?? '';
                        _address.text = c['address']?.toString() ?? '';
                      }),
              ),
              TextFormField(
                controller: _name,
                readOnly: _saving,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Người nhận *'),
                validator: _required,
              ),
              TextFormField(
                controller: _phone,
                readOnly: _saving,
                maxLength: 20,
                decoration: const InputDecoration(labelText: 'Điện thoại *'),
                validator: _required,
              ),
              TextFormField(
                controller: _address,
                readOnly: _saving,
                maxLength: 350,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng *',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              for (final line in _lines)
                Padding(
                  key: ObjectKey(line),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: line.variantId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Biến thể *',
                        ),
                        items: options.variants
                            .where(
                              (v) =>
                                  v.variantId == line.variantId ||
                                  !_lines.any(
                                    (l) => l.variantId == v.variantId,
                                  ),
                            )
                            .map(
                              (v) => DropdownMenuItem(
                                value: v.variantId,
                                child: Text(
                                  '${v.label} • ${money(v.price)} • Còn ${v.availableQuantity}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => line.variantId = v),
                        validator: (v) => v == null ? 'Chọn biến thể' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: line.quantity,
                              readOnly: _saving,
                              decoration: const InputDecoration(
                                labelText: 'Số lượng *',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                final found = options.variants.where(
                                  (i) => i.variantId == line.variantId,
                                );
                                return n == null ||
                                        n <= 0 ||
                                        (found.isNotEmpty &&
                                            n > found.first.availableQuantity)
                                    ? 'Số lượng phải > 0 và không vượt tồn khả dụng'
                                    : null;
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _saving || _lines.length == 1
                                ? null
                                : () => setState(() {
                                    _lines.remove(line);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                          (_) => line.dispose(),
                                        );
                                  }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving || _lines.length >= 200
                      ? null
                      : () => setState(() => _lines.add(_OrderLine())),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sản phẩm'),
                ),
              ),
              TextFormField(
                controller: _shipping,
                readOnly: _saving,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Phí vận chuyển (VND)',
                ),
                validator: (v) =>
                    !RegExp(r'^\d{1,16}(\.\d{1,2})?$').hasMatch(v ?? '')
                    ? 'Phí không hợp lệ'
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Thanh toán online • Giữ hàng 5 phút, quá hạn chưa thanh toán sẽ tự hủy.',
                ),
              ),
              TextFormField(
                controller: _note,
                maxLength: 500,
                readOnly: _saving,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              const SizedBox(height: 16),
              Text(
                'Tổng dự kiến: ${money(total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Giá bán và tồn kho được kiểm tra lại khi tạo đơn.'),
            ],
          ),
        );
      },
    ),
  );
}
