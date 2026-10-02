import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../suppliers/data/models/supplier_response_model.dart';
import '../../data/models/goods_receipt_response_model.dart';
import '../providers/purchases_provider.dart';

class GoodsReceiptFormDialog extends StatefulWidget {
  final GoodsReceiptResponseModel? receipt;
  const GoodsReceiptFormDialog({super.key, this.receipt});
  @override
  State<GoodsReceiptFormDialog> createState() => _GoodsReceiptFormDialogState();
}

class _GoodsReceiptFormDialogState extends State<GoodsReceiptFormDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final List<_DraftLine> _lines = [];
  late final Future<
    ({
      List<SupplierResponseModel> suppliers,
      List<InventoryResponseModel> variants,
    })
  >
  _options;
  int? _supplierId;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _supplierId = widget.receipt?.supplierId;
    _note.text = widget.receipt?.note ?? '';
    for (final item in widget.receipt?.items ?? <Map<String, dynamic>>[]) {
      _lines.add(
        _DraftLine(
          id: item['variantId'] as int,
          quantity: item['quantity'].toString(),
          cost: item['unitCost'].toString(),
        ),
      );
    }
    _options = context.read<PurchasesProvider>().options();
  }

  @override
  void dispose() {
    _note.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true) return;
    if (_lines.isEmpty) {
      _message('Vui lòng thêm ít nhất một dòng hàng');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PurchasesProvider>().save({
        'supplierId': _supplierId,
        'note': _note.text.trim(),
        'items': _lines
            .map(
              (l) => {
                'variantId': l.id,
                'quantity': int.parse(l.quantity.text),
                'unitCost': num.parse(l.cost.text),
              },
            )
            .toList(),
      }, id: widget.receipt?.id);
      if (!mounted) return;
      _message('Đã lưu phiếu nhập nháp');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaFormDialog(
      title: widget.receipt == null ? 'Tạo phiếu nhập' : 'Sửa phiếu nhập nháp',
      width: size.width * 2 / 3,
      height: size.height * .8,
      isLoading: _saving,
      confirmText: 'Lưu nháp',
      onCancel: () => Navigator.pop(context),
      onConfirm: _save,
      content: FutureBuilder(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Không tải được lựa chọn: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final choices = snapshot.data!;
          final variants = choices.variants
              .where((v) => v.supplierId == _supplierId)
              .toList();
          final supplierValid = choices.suppliers.any(
            (s) => s.id == _supplierId,
          );
          return Form(
            key: _form,
            child: ListView(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: supplierValid ? _supplierId : null,
                  decoration: const InputDecoration(
                    labelText: 'Nhà cung cấp *',
                  ),
                  items: choices.suppliers
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  validator: (_) =>
                      supplierValid ? null : 'Chọn nhà cung cấp đang hoạt động',
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                          if (v != _supplierId) {
                            for (final l in _lines) {
                              l.dispose();
                            }
                            _lines.clear();
                          }
                          _supplierId = v;
                        }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hàng nhập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final line in _lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                key: ObjectKey(line),
                                initialValue:
                                    variants.any((v) => v.variantId == line.id)
                                    ? line.id
                                    : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Biến thể *',
                                ),
                                items: variants
                                    .where(
                                      (v) =>
                                          v.variantId == line.id ||
                                          !_lines.any(
                                            (l) => l.id == v.variantId,
                                          ),
                                    )
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v.variantId,
                                        child: Text(
                                          v.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                validator: (_) =>
                                    variants.any((v) => v.variantId == line.id)
                                    ? null
                                    : 'Chọn biến thể hợp lệ',
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() {
                                        line.id = v;
                                        line.cost.text = variants
                                            .firstWhere((i) => i.variantId == v)
                                            .costPrice
                                            .toString();
                                      }),
                              ),
                            ),
                            IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                      _lines.remove(line);
                                      line.dispose();
                                    }),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: line.quantity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Số lượng *',
                                ),
                                validator: (v) =>
                                    int.tryParse(v ?? '') == null ||
                                        int.parse(v!) <= 0
                                    ? 'Nhập số nguyên > 0'
                                    : null,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: line.cost,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Đơn giá nhập (VND) *',
                                ),
                                validator: (v) =>
                                    RegExp(r'^\d{1,16}(\.\d{1,2})?$')
                                        .hasMatch(v ?? '')
                                    ? null
                                    : 'Nhập giá không âm, tối đa 2 số lẻ',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _saving || !supplierValid
                        ? null
                        : () => setState(() => _lines.add(_DraftLine())),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm dòng hàng'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tổng dự kiến: ${money(_lines.fold<num>(0, (sum, l) => sum + (int.tryParse(l.quantity.text) ?? 0) * (num.tryParse(l.cost.text) ?? 0)))}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lưu nháp chưa làm tăng tồn kho. Xác nhận nhập kho sau khi kiểm tra hàng đã nhận.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DraftLine {
  int? id;
  final TextEditingController quantity, cost;
  _DraftLine({this.id, String quantity = '1', String cost = '0'})
    : quantity = TextEditingController(text: quantity),
      cost = TextEditingController(text: cost);
  void dispose() {
    quantity.dispose();
    cost.dispose();
  }
}
