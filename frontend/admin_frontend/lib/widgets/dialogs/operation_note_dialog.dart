import 'package:flutter/material.dart';

import 'zella_form_dialog.dart';

class OperationNoteDialog extends StatefulWidget {
  final String title, description;
  final Future<void> Function(String note, String method) onSubmit;
  final Map<String, String>? methods;
  const OperationNoteDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onSubmit,
    this.methods,
  });
  @override
  State<OperationNoteDialog> createState() => _OperationNoteDialogState();
}

class _OperationNoteDialogState extends State<OperationNoteDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  bool _saving = false;
  late String _method;
  @override
  void initState() {
    super.initState();
    _method = widget.methods?.keys.first ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_note.text.trim(), _method);
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
    isLoading: _saving,
    onCancel: () => Navigator.pop(context),
    onConfirm: _save,
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.description),
            const SizedBox(height: 16),
            if (widget.methods != null)
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Phương thức'),
                items: widget.methods!.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _method = v!),
              ),
            TextFormField(
              controller: _note,
              maxLength: 400,
              maxLines: 3,
              readOnly: _saving,
              decoration: const InputDecoration(
                labelText: 'Lý do / mã giao dịch *',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập thông tin'
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}
