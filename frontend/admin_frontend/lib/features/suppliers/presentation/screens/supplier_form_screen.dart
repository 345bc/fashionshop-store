import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../data/models/supplier_response_model.dart';
import '../providers/suppliers_provider.dart';
import '../../../../widgets/common/zella_toast.dart';

class SupplierFormScreen extends StatefulWidget {
  final SupplierResponseModel? supplier;
  final VoidCallback onClose;

  const SupplierFormScreen({super.key, this.supplier, required this.onClose});
  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
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
      ZellaToast.show(
        context,
        message: 'Đã lưu nhà cung cấp',
        type: ToastType.success,
      );
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ZellaToast.show(
          context,
          message: 'Không thể lưu nhà cung cấp: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _input(
    String key,
    String label, {
    int maxLength = 100,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => _field(
    label,
    TextFormField(
      controller: _fields[key],
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: const InputDecoration(counterText: ''),
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.supplier != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
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
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 28),
              child: Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Về danh sách nhà cung cấp',
                          onPressed: widget.onClose,
                          icon: const Icon(Symbols.arrow_back, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            editing
                                ? 'Chỉnh sửa nhà cung cấp'
                                : 'Thêm nhà cung cấp',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _section(
                      'Thông tin nhà cung cấp',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _columns([
                            _input(
                              'name',
                              'Tên nhà cung cấp *',
                              maxLength: 150,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng nhập tên'
                                  : null,
                            ),
                            _input('contactPerson', 'Người liên hệ'),
                          ]),
                          const SizedBox(height: 20),
                          _columns([
                            _input(
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
                            _input(
                              'phone',
                              'Số điện thoại',
                              maxLength: 10,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    !RegExp(r'^0[0-9]{9}$').hasMatch(v)) {
                                  return 'SĐT phải gồm 10 chữ số và bắt đầu bằng 0';
                                }
                                return null;
                              },
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _input('address', 'Địa chỉ', maxLength: 255),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Trạng thái hoạt động'),
                            value: _active,
                            onChanged: (value) =>
                                setState(() => _active = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        TextButton(
                          onPressed: widget.onClose,
                          child: const Text('Hủy'),
                        ),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5364FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Symbols.save, size: 18),
                          label: Text(
                            editing ? 'Lưu thay đổi' : 'Thêm nhà cung cấp',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _columns(List<Widget> fields) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 650) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              fields[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: 24),
            Expanded(child: fields[i]),
          ],
        ],
      );
    },
  );

  Widget _section(String title, Widget content) => Container(
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
        Padding(padding: const EdgeInsets.all(24), child: content),
      ],
    ),
  );
}
