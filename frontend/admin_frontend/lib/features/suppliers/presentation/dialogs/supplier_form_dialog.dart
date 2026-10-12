import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../data/models/supplier_response_model.dart';
import '../providers/suppliers_provider.dart';

class SupplierFormDialog extends StatefulWidget {
  final SupplierResponseModel? supplier;
  const SupplierFormDialog({super.key, this.supplier});
  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _fields = {
      'name': TextEditingController(text: s?.name),
      'code': TextEditingController(text: s?.code),
      'contactPerson': TextEditingController(text: s?.contactPerson),
      'contactEmail': TextEditingController(text: s?.contactEmail),
      'phone': TextEditingController(text: s?.phone),
      'address': TextEditingController(text: s?.address),
    };
    _active = s?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
        'isActive': _active,
      };
      final provider = context.read<SuppliersProvider>();
      if (widget.supplier == null) {
        await provider.createItem(data);
      } else {
        await provider.updateItem(widget.supplier!.id, data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu nhà cung cấp')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu nhà cung cấp: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    int maxLength = 100,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _fields[key],
              maxLength: maxLength,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaFormDialog(
      title: widget.supplier == null
          ? 'Thêm nhà cung cấp'
          : 'Chỉnh sửa nhà cung cấp',
      subtitle: widget.supplier == null
          ? 'Tạo nhà cung cấp mới. Nhấn lưu khi hoàn tất.'
          : 'Cập nhật thông tin nhà cung cấp. Nhấn lưu khi hoàn tất.',
      width: (size.width * 2 / 3).clamp(480.0, 700.0),
      height: size.height * 2 / 3,
      confirmText: widget.supplier == null
          ? 'Thêm nhà cung cấp'
          : 'Lưu thay đổi',
      isLoading: _saving,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _save,
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _field(
                'name',
                'Tên nhà cung cấp *',
                maxLength: 150,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              _field('contactPerson', 'Người liên hệ'),
              _field(
                'contactEmail',
                'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v != null &&
                        v.trim().isNotEmpty &&
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v.trim())
                    ? 'Email không hợp lệ'
                    : null,
              ),
              _field(
                'phone',
                'Số điện thoại',
                maxLength: 10,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v != null && v.isNotEmpty && !RegExp(r'^0[0-9]{9}$').hasMatch(v)) {
                    return 'SĐT phải gồm 10 chữ số và bắt đầu bằng 0';
                  }
                  return null;
                },
              ),
              _field('address', 'Địa chỉ', maxLength: 255),
              Row(
                children: [
                  const SizedBox(
                    width: 160,
                    child: Text(
                      'Trạng thái hoạt động',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.text,
                      ),
                    ),
                  ),
                  Switch(
                    value: _active,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
