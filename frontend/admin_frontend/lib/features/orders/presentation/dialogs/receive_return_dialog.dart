import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../data/models/order_response_model.dart';
import '../providers/orders_provider.dart';

class ReceiveReturnDialog extends StatefulWidget {
  final ReturnResponseModel document;
  const ReceiveReturnDialog({super.key, required this.document});
  @override
  State<ReceiveReturnDialog> createState() => _ReceiveReturnDialogState();
}

class _ReceiveReturnDialogState extends State<ReceiveReturnDialog> {
  late final Map<int, String> _conditions;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _conditions = {
      for (final i in widget.document.items) i['id'] as int: 'INTACT',
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<OrdersProvider>().returnAction(
        widget.document.id,
        'receive',
        data: {
          'items': _conditions.entries
              .map((e) => {'returnItemId': e.key, 'condition': e.value})
              .toList(),
        },
      );
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

  @override
  Widget build(BuildContext context) => ZellaFormDialog(
    title: 'Nhận và kiểm tra hàng trả',
    width: MediaQuery.sizeOf(context).width * 2 / 3,
    height: MediaQuery.sizeOf(context).height * .8,
    isLoading: _saving,
    confirmText: 'Xác nhận đã nhận hàng',
    onCancel: () => Navigator.pop(context),
    onConfirm: _save,
    content: ListView(
      children: [
        const Text(
          'Chỉ xác nhận sau khi đã nhận hàng thực tế. Hàng nguyên vẹn được cộng tồn; hàng hỏng không nhập tồn bán.',
        ),
        const SizedBox(height: 16),
        for (final item in widget.document.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: DropdownButtonFormField<String>(
              initialValue: _conditions[item['id']],
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    '${item["productName"]} • ${item["sku"]} × ${item["quantity"]}',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'INTACT',
                  child: Text('Nguyên vẹn, còn bán được'),
                ),
                DropdownMenuItem(
                  value: 'DAMAGED',
                  child: Text('Hỏng, không nhập tồn bán'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _conditions[item['id'] as int] = v!),
            ),
          ),
      ],
    ),
  );
}
