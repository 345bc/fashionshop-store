import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../data/models/inventory_response_model.dart';
import '../providers/inventory_provider.dart';

class InventoryAdjustmentDialog extends StatefulWidget {
  final InventoryResponseModel item;
  const InventoryAdjustmentDialog({super.key, required this.item});
  @override
  State<InventoryAdjustmentDialog> createState() =>
      _InventoryAdjustmentDialogState();
}

class _InventoryAdjustmentDialogState extends State<InventoryAdjustmentDialog> {
  final _key = GlobalKey<FormState>();
  final _quantity = TextEditingController(), _reason = TextEditingController();
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _quantity.text = widget.item.stockQuantity.toString();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<InventoryProvider>().adjust({
        'reason': _reason.text.trim(),
        'items': [
          {
            'variantId': widget.item.variantId,
            'expectedQuantity': widget.item.stockQuantity,
            'countedQuantity': int.parse(_quantity.text),
          },
        ],
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ZellaFormDialog(
    title: 'Điều chỉnh tồn kho',
    onConfirm: _save,
    onCancel: () => Navigator.pop(context),
    isLoading: _saving,
    content: Form(
      key: _key,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(widget.item.label),
            const SizedBox(height: 16),
            Text(
              'Tồn hiện tại: ${widget.item.stockQuantity} • Đã giữ: ${widget.item.reservedQuantity}',
            ),
            TextFormField(
              controller: _quantity,
              decoration: const InputDecoration(
                labelText: 'Số lượng thực tế *',
              ),
              validator: (v) =>
                  int.tryParse(v ?? '') == null ||
                      int.parse(v!) < widget.item.reservedQuantity
                  ? 'Nhập số nguyên không nhỏ hơn số đã giữ'
                  : null,
            ),
            TextFormField(
              controller: _reason,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Lý do *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập lý do' : null,
            ),
          ],
        ),
      ),
    ),
  );
}
