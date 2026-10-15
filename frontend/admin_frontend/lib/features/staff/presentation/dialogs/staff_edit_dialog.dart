import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

class StaffEditDialog extends StatefulWidget {
  final Map<String, dynamic>? staff;
  const StaffEditDialog({super.key, this.staff});
  @override
  State<StaffEditDialog> createState() => _StaffEditDialogState();
}

class _StaffEditDialogState extends State<StaffEditDialog> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    for (final key in [
      'fullName',
      'position',
      'phone',
      'hiredDate',
      'username',
      'email',
      'password',
    ]) {
      _fields[key] = TextEditingController(
        text:
            s?[key]?.toString() ??
            (key == 'hiredDate'
                ? DateTime.now().toIso8601String().substring(0, 10)
                : ''),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickHiredDate() async {
    if (_busy) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final current = DateTime.tryParse(_fields['hiredDate']!.text);
    final initial = current == null || current.isAfter(today)
        ? today
        : DateUtils.dateOnly(current);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(DateTime(1900)) ? initial : DateTime(1900),
      lastDate: today,
      helpText: 'Chọn ngày vào làm',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null && mounted) {
      setState(
        () => _fields['hiredDate']!.text = picked.toIso8601String().substring(
          0,
          10,
        ),
      );
    }
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool secret = false,
    bool readOnly = false,
  }) => _row(
    key == 'hiredDate' ? 'Ngày vào làm' : label,
    TextFormField(
      controller: _fields[key],
      readOnly: readOnly || _busy || key == 'hiredDate',
      onTap: key == 'hiredDate' && !_busy ? _pickHiredDate : null,
      obscureText: secret,
      keyboardType: key == 'phone' ? TextInputType.phone : null,
      inputFormatters: key == 'phone'
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      style: const TextStyle(fontSize: 14),
      decoration:
          _decoration(
            key == 'hiredDate'
                ? 'YYYY-MM-DD'
                : secret && !(widget.staff == null)
                ? 'Để trống nếu không đổi'
                : 'Nhập ${label.toLowerCase()}',
          ).copyWith(
            suffixIcon: key == 'hiredDate'
                ? IconButton(
                    tooltip: 'Chọn ngày vào làm',
                    onPressed: _busy ? null : _pickHiredDate,
                    icon: const Icon(Symbols.calendar_month, size: 18),
                  )
                : null,
          ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return 'Vui lòng nhập $label';
        }
        if (key == 'email' &&
            v != null &&
            v.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
          return 'Email không hợp lệ';
        }
        if (key == 'phone' && !RegExp(r'^0[0-9]{9}$').hasMatch(v ?? '')) {
          return 'Số điện thoại gồm 10 chữ số, bắt đầu bằng 0';
        }
        if (key == 'password' && v != null && v.isNotEmpty && v.length < 6) {
          return 'Mật khẩu tối thiểu 6 ký tự';
        }
        if (key == 'hiredDate') {
          final date = DateTime.tryParse(v ?? '');
          if (date == null || date.isAfter(DateTime.now())) {
            return 'Ngày hợp lệ: YYYY-MM-DD, không vượt ngày hiện tại';
          }
        }
        return null;
      },
    ),
  );
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        for (final key in ['fullName', 'position', 'phone', 'hiredDate'])
          key: _fields[key]!.text.trim(),
        if (widget.staff == null) ...{
          'username': _fields['username']!.text.trim(),
          'email': _fields['email']!.text.trim(),
          'password': _fields['password']!.text,
        },
      };
      if (widget.staff == null) {
        await ApiClient().post('/staff', data: data);
      } else {
        await ApiClient().put('/staff/${widget.staff!['id']}', data: data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  );

  Widget _row(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final caption = Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.text,
          ),
        );
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [caption, const SizedBox(height: 8), child],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: caption,
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.staff != null;
    return PopScope(
      canPop: !_busy,
      child: ZellaFormDialog(
        title: editing ? 'Chỉnh sửa nhân sự' : 'Thêm mới nhân sự',
        subtitle: editing
            ? 'Cập nhật thông tin cơ bản. Nhấn lưu khi hoàn tất.'
            : 'Tạo tài khoản nhân sự mới. Nhấn lưu khi hoàn tất.',
        width: 700,
        confirmText: editing ? 'Lưu thay đổi' : 'Thêm nhân sự',
        isLoading: _busy,
        onCancel: () => Navigator.pop(context),
        onConfirm: _save,
        content: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field('fullName', 'Họ và tên', required: true),
                _field('position', 'Chức vụ'),
                _field('phone', 'Số điện thoại', required: true),
                _field('hiredDate', 'Ngày vào làm', required: true),
                if (!editing) ...[
                  _field('username', 'Tên đăng nhập', required: true),
                  _field('email', 'Email', required: true),
                  _field('password', 'Mật khẩu', required: true, secret: true),
                ],
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
