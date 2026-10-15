import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../providers/products_provider.dart';

class ProductContentDialog extends StatefulWidget {
  const ProductContentDialog({super.key, required this.product});
  final Map<String, dynamic> product;
  @override
  State<ProductContentDialog> createState() => _ProductContentDialogState();
}

class _ProductContentDialogState extends State<ProductContentDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields = {
    for (final key in ['name', 'description', 'style', 'occasion'])
      key: TextEditingController(text: widget.product[key]?.toString() ?? ''),
  };
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient().patch(
        '/product/${widget.product['id']}/content',
        data: _fields.map(
          (key, controller) => MapEntry(key, controller.text.trim()),
        ),
      );
      if (!mounted) return;
      final provider = context.read<ProductsProvider>();
      await provider.loadItems(page: provider.currentPage);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ZellaFormDialog(
    title: 'Nội dung sản phẩm',
    formKey: _form,
    width: 560,
    onCancel: () => Navigator.pop(context),
    onConfirm: _save,
    isLoading: _saving,
    content: SingleChildScrollView(
      child: Column(
        children: [
          for (final entry in {
            'name': 'Tên sản phẩm',
            'description': 'Mô tả',
            'style': 'Phong cách',
            'occasion': 'Dịp sử dụng',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: _fields[entry.key],
                enabled: !_saving,
                maxLines: entry.key == 'description' ? 5 : 1,
                maxLength: switch (entry.key) {
                  'name' => 200,
                  'description' => 5000,
                  'style' => 50,
                  _ => 100,
                },
                decoration: InputDecoration(
                  labelText: entry.value,
                  counterText: '',
                ),
                validator: (value) =>
                    entry.key == 'name' && (value?.trim().isEmpty ?? true)
                    ? 'Nhập tên sản phẩm'
                    : null,
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
