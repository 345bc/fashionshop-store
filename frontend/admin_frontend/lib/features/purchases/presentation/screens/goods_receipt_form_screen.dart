import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../../../../widgets/common/searchable_multi_select_field.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../suppliers/data/models/supplier_response_model.dart';
import '../../data/models/goods_receipt_response_model.dart';
import '../providers/purchases_provider.dart';
import '../../../../widgets/common/zella_toast.dart';

class GoodsReceiptFormScreen extends StatefulWidget {
  final GoodsReceiptResponseModel? receipt;
  final VoidCallback onClose;

  const GoodsReceiptFormScreen({
    super.key,
    this.receipt,
    required this.onClose,
  });

  @override
  State<GoodsReceiptFormScreen> createState() => _GoodsReceiptFormScreenState();
}

class _GoodsReceiptFormScreenState extends State<GoodsReceiptFormScreen> {
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
  Object? _selectedProduct;
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
    if (_saving || _form.currentState?.validate() != true) return;
    if (_lines.isEmpty) {
      _message('Vui lòng thêm ít nhất một dòng hàng', ToastType.warning);
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
      _message('Đã lưu phiếu nhập nháp', ToastType.success);
      widget.onClose();
    } catch (e) {
      if (mounted) _message(e.toString(), ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value, ToastType type) =>
      ZellaToast.show(context, message: value, type: type);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: _saving ? null : widget.onClose,
          icon: const Icon(Symbols.arrow_back, size: 20),
        ),
        title: Text(
          widget.receipt == null ? 'Tạo phiếu nhập' : 'Sửa phiếu nhập nháp',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder(
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
          final products = {
            for (final v in variants) _productKey(v): v.productName,
          };
          final supplierValid = choices.suppliers.any(
            (s) => s.id == _supplierId,
          );
          return Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Color(0xFF5364FF)),
                ),
              ),
            ),
            child: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 700 ? 16 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section('Thông tin phiếu nhập', [
                        _field(
                          'Nhà cung cấp *',
                          SearchableSelectField<int>(
                            initialValue: supplierValid ? _supplierId : null,
                            decoration: const InputDecoration(
                              hintText: 'Chọn nhà cung cấp',
                            ),
                            items: choices.suppliers
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            validator: (_) => supplierValid
                                ? null
                                : 'Chọn nhà cung cấp đang hoạt động',
                            onChanged: (v) => setState(() {
                              if (v != _supplierId) {
                                for (final l in _lines) {
                                  l.dispose();
                                }
                                _lines.clear();
                                _selectedProduct = null;
                              }
                              _supplierId = v;
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          'Ghi chú',
                          TextFormField(
                            controller: _note,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText: 'Nhập ghi chú',
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _section('Hàng nhập', [
                        _productFields(variants, products),
                        if (_lines.isNotEmpty) const SizedBox(height: 20),
                        for (final line in _lines)
                          _variantRow(
                            line,
                            variants
                                .where((v) => v.variantId == line.id)
                                .firstOrNull,
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
                      ]),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _saving ? null : widget.onClose,
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'Đang lưu…' : 'Lưu nháp'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Object _productKey(InventoryResponseModel variant) =>
      variant.productId ?? (variant.productName, variant.categoryName);

  Widget _productFields(
    List<InventoryResponseModel> variants,
    Map<Object, String> products,
  ) {
    final product = _selectedProduct;
    final options = {
      for (final variant in variants)
        if (_productKey(variant) == product)
          variant.variantId:
              '${variant.sizeName} / ${variant.colorName}${variant.isActive ? '' : ' · Ngừng bán'} (${variant.sku})',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          'Sản phẩm',
          SearchableSelectField<Object>(
            key: ValueKey(_supplierId),
            initialValue: product,
            enabled: products.isNotEmpty,
            decoration: InputDecoration(
              hintText: _supplierId == null
                  ? 'Chọn nhà cung cấp trước'
                  : products.isEmpty
                  ? 'Nhà cung cấp chưa có sản phẩm'
                  : 'Chọn sản phẩm',
            ),
            items: [
              for (final entry in products.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => _selectedProduct = value),
          ),
        ),
        if (product != null) ...[
          const SizedBox(height: 12),
          _field(
            'Biến thể',
            SearchableMultiSelectField<int>(
              key: ValueKey(product),
              values: {
                for (final line in _lines)
                  if (options.containsKey(line.id)) line.id,
              },
              decoration: const InputDecoration(hintText: 'Chọn biến thể'),
              options: options,
              onChanged: (selected) => setState(() {
                for (final line in _lines.toList()) {
                  if (options.containsKey(line.id) &&
                      !selected.contains(line.id)) {
                    _lines.remove(line);
                    line.dispose();
                  }
                }
                final existing = _lines.map((line) => line.id).toSet();
                for (final id in selected.difference(existing)) {
                  _lines.add(_DraftLine(id: id));
                }
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _variantRow(
    _DraftLine line,
    InventoryResponseModel? variant,
  ) => Padding(
    key: ValueKey(line.id),
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                variant?.label ?? 'Biến thể #${line.id} không còn khả dụng',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _lines.remove(line);
                      line.dispose();
                    }),
              tooltip: 'Xóa biến thể',
              icon: const Icon(Symbols.close),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                'Số lượng *',
                TextFormField(
                  controller: line.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Nhập số lượng'),
                  validator: (value) {
                    if (variant == null) {
                      return 'Xóa biến thể không còn khả dụng';
                    }
                    return (int.tryParse(value ?? '') ?? 0) <= 0
                        ? 'Nhập số nguyên > 0'
                        : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _field(
                'Đơn giá nhập (VND) *',
                TextFormField(
                  controller: line.cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(hintText: 'Nhập đơn giá'),
                  validator: (value) =>
                      RegExp(r'^\d{1,16}(\.\d{1,2})?$').hasMatch(value ?? '')
                      ? null
                      : 'Nhập giá không âm, tối đa 2 số lẻ',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _field(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 9),
      field,
    ],
  );

  Widget _section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE4E7EC)),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    ),
  );
}

class _DraftLine {
  final int id;
  final TextEditingController quantity, cost;
  _DraftLine({required this.id, String quantity = '', String cost = ''})
    : quantity = TextEditingController(text: quantity),
      cost = TextEditingController(text: cost);
  void dispose() {
    quantity.dispose();
    cost.dispose();
  }
}
