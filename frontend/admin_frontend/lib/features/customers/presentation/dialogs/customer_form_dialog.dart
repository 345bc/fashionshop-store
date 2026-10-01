import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../data/models/customer_response_model.dart';
import '../providers/customers_provider.dart';

class CustomerFormDialog extends StatefulWidget {
  final CustomerResponseModel? customer;
  const CustomerFormDialog({super.key, this.customer});
  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late bool _active;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _fields = {
      'fullName': TextEditingController(text: c?.fullName),
      'email': TextEditingController(text: c?.email),
      'username': TextEditingController(text: c?.username),
      'password': TextEditingController(),
      'phone': TextEditingController(text: c?.phone),
      'address': TextEditingController(text: c?.address),
    };
    _active = c?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label, {
    int maxLength = 100,
    bool obscure = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: _fields[key],
    maxLength: maxLength,
    obscureText: obscure,
    enabled: enabled,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<CustomersProvider>();
      await provider.updateItem(widget.customer!.id, {'isActive': _active});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu khách hàng')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu khách hàng: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaFormDialog(
      title: 'Chỉnh sửa khách hàng',
      width: (size.width * 2 / 3).clamp(480.0, 1100.0),
      height: size.height * 2 / 3,
      confirmText: 'Lưu thay đổi',
      isLoading: _saving,
      onCancel: () => Navigator.pop(context),
      onConfirm: _save,
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thông tin khách hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _field('fullName', 'Họ và tên', enabled: false),
              _field('email', 'Email', enabled: false),
              _field('phone', 'Số điện thoại', enabled: false),
              _field('address', 'Địa chỉ', enabled: false),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tài khoản hoạt động'),
                value: _active,
                activeThumbColor: AppTheme.primary,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
