import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/models/goods_receipt_response_model.dart';
import '../providers/purchases_provider.dart';

class SupplierPaymentDialog extends StatefulWidget {
  final GoodsReceiptResponseModel receipt;
  final bool isRefund;
  const SupplierPaymentDialog({
    super.key,
    required this.receipt,
    this.isRefund = false,
  });
  @override
  State<SupplierPaymentDialog> createState() => _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState extends State<SupplierPaymentDialog> {
  final _key = GlobalKey<FormState>();
  final _amount = TextEditingController(), _note = TextEditingController();
  String _method = 'BANK_TRANSFER';
  bool _saving = false;
  num get _balance => widget.isRefund
      ? widget.receipt.supplierRefundDue
      : widget.receipt.remainingAmount;
  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<PurchasesProvider>().action(
        widget.receipt.id,
        widget.isRefund ? 'refunds' : 'payments',
        data: {
          'amount': num.parse(_amount.text),
          'paymentMethod': _method,
          'note': _note.text.trim(),
        },
      );
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
    title: widget.isRefund
        ? 'Ghi nhận tiền nhà cung cấp hoàn lại'
        : 'Thanh toán nhà cung cấp',
    isLoading: _saving,
    onCancel: () => Navigator.pop(context),
    onConfirm: _save,
    content: Form(
      key: _key,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              '${widget.isRefund ? "Cần nhận hoàn" : "Còn nợ"}: ${money(_balance)}',
            ),
            if (widget.isRefund)
              const Text('Chỉ xác nhận khi đã nhận tiền hoàn thực tế.'),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Số tiền (VND) *'),
              validator: (v) {
                if (!RegExp(r'^\d{1,16}(\.\d{1,2})?$').hasMatch(v ?? '')) {
                  return 'Số tiền không hợp lệ';
                }
                final amount = num.parse(v!);
                return amount <= 0 || amount > _balance
                    ? 'Số tiền phải > 0 và không vượt số còn lại'
                    : null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _method,
              items: const [
                DropdownMenuItem(
                  value: 'BANK_TRANSFER',
                  child: Text('Chuyển khoản'),
                ),
                DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt')),
              ],
              onChanged: (v) => setState(() => _method = v!),
              decoration: const InputDecoration(labelText: 'Phương thức'),
            ),
            TextFormField(
              controller: _note,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
          ],
        ),
      ),
    ),
  );
}
