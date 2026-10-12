import 'package:flutter/material.dart';

import 'zella_form_dialog.dart';

class QuantityChoice {
  final int id, maximum;
  final String label;
  const QuantityChoice({
    required this.id,
    required this.maximum,
    required this.label,
  });
}

class QuantitySelectionDialog extends StatefulWidget {
  final String title, description;
  final List<QuantityChoice> choices;
  final bool requireAll;
  final Future<void> Function(String reason, Map<int, int> quantities) onSubmit;
  const QuantitySelectionDialog({
    super.key,
    required this.title,
    required this.description,
    required this.choices,
    required this.onSubmit,
    this.requireAll = false,
  });
  @override
  State<QuantitySelectionDialog> createState() =>
      _QuantitySelectionDialogState();
}

class _QuantitySelectionDialogState extends State<QuantitySelectionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late final Map<int, TextEditingController> _counts;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _counts = {
      for (final c in widget.choices)
        c.id: TextEditingController(
          text: widget.requireAll ? '${c.maximum}' : '0',
        ),
    };
  }

  @override
  void dispose() {
    _reason.dispose();
    for (final c in _counts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true) return;
    final selected = {
      for (final e in _counts.entries)
        if (int.parse(e.value.text) > 0) e.key: int.parse(e.value.text),
    };
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất một sản phẩm')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_reason.text.trim(), selected);
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
    title: widget.title,
    width: MediaQuery.sizeOf(context).width * 2 / 3,
    height: MediaQuery.sizeOf(context).height * .8,
    isLoading: _saving,
    onCancel: () => Navigator.pop(context),
    onConfirm: _save,
    content: Form(
      key: _form,
      child: ListView(
        children: [
          Text(widget.description),
          const SizedBox(height: 16),
          for (final c in widget.choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _counts[c.id],
                readOnly: _saving || widget.requireAll,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: c.label,
                  helperText: 'Có thể trả tối đa: ${c.maximum}',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 0 || n > c.maximum
                      ? 'Số lượng phải từ 0 đến ${c.maximum}'
                      : null;
                },
              ),
            ),
          TextFormField(
            controller: _reason,
            maxLength: 500,
            readOnly: _saving,
            decoration: const InputDecoration(labelText: 'Lý do *'),
            maxLines: 3,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập lý do' : null,
          ),
        ],
      ),
    ),
  );
}
