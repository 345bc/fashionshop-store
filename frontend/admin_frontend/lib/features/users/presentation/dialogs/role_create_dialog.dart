import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

class RoleCreateDialog extends StatefulWidget {
  const RoleCreateDialog({super.key});
  @override
  State<RoleCreateDialog> createState() => _RoleCreateDialogState();
}

class _RoleCreateDialogState extends State<RoleCreateDialog> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController(),
      _name = TextEditingController(),
      _description = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient().post(
        '/role',
        data: {
          'roleCode': _code.text.trim().toUpperCase(),
          'roleName': _name.text.trim(),
          'description': _description.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: ZellaFormDialog(
      title: 'Thêm role',
      subtitle: 'Tạo role mới trong hệ thống.',
      width: 520,
      isLoading: _busy,
      confirmText: 'Thêm role',
      onCancel: () => Navigator.pop(context),
      onConfirm: _save,
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _code,
                enabled: !_busy,
                maxLength: 50,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Mã role',
                  hintText: 'Ví dụ: ACCOUNTANT',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final code = (v ?? '').trim().toUpperCase();
                  if (!RegExp(r'^[A-Z][A-Z0-9_]{0,49}$').hasMatch(code)) {
                    return 'Nhập mã gồm chữ, số và dấu gạch dưới';
                  }
                  if (code.startsWith('ROLE_') ||
                      ['EMPLOYEE', 'CUSTOMER'].contains(code)) {
                    return 'Mã role không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tên role',
                  hintText: 'Ví dụ: Kế toán',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Nhập tên role' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                maxLength: 255,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (không bắt buộc)',
                  border: OutlineInputBorder(),
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
      ),
    ),
  );
}
