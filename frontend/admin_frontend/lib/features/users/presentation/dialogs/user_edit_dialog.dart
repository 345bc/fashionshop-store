import '../../../../core/security/role_access.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../providers/users_provider.dart';

class UserEditDialog extends StatefulWidget {
  final Map<String, dynamic>? user;

  const UserEditDialog({super.key, this.user});

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final Set<String> _selectedRoles = {'USER'};
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _roles = [
    'ADMIN',
    'USER',
    'SALES',
    'WAREHOUSE',
    'CUSTOMER_SUPPORT',
    'MARKETING',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?['name']);
    _emailController = TextEditingController(text: widget.user?['email']);
    _passwordController = TextEditingController();

    if (widget.user != null) {
      if (widget.user!['roles'] != null &&
          (widget.user!['roles'] as List).isNotEmpty) {
        _selectedRoles.clear();
        _selectedRoles.addAll(
          (widget.user!['roles'] as List)
              .map((role) => role.toString())
              .where(_roles.contains),
        );
      }
      _isActive = widget.user!['isActive'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chọn ít nhất một vai trò')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<UsersProvider>();
      final isEditing = widget.user != null;

      final data = {
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'roles': _selectedRoles.toList(),
      };

      if (!isEditing || _passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (isEditing) {
        data['isActive'] = _isActive;
        await provider.updateItem(widget.user!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật tài khoản thành công')),
          );
        }
      } else {
        await provider.createItem(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo tài khoản thành công')),
          );
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $errorMsg'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFieldRow(String label, Widget child) {
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
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    bool required = true,
  }) {
    return _buildFieldRow(
      label,
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Vui lòng nhập trường này';
          }
          if (obscureText &&
              value != null &&
              value.isNotEmpty &&
              value.length < 6) {
            return 'Mật khẩu tối thiểu 6 ký tự';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final size = MediaQuery.sizeOf(context);

    return ZellaFormDialog(
      title: isEditing ? 'Chỉnh sửa tài khoản' : 'Thêm mới tài khoản',
      subtitle: isEditing
          ? 'Cập nhật thông tin tài khoản. Nhấn lưu khi hoàn tất.'
          : 'Tạo tài khoản mới. Nhấn lưu khi hoàn tất.',
      width: (size.width * 2 / 3).clamp(480.0, 700.0),
      confirmText: isEditing ? 'Lưu thay đổi' : 'Tạo tài khoản',
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _saveUser,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Form Fields
              _buildTextField(
                'Tên đăng nhập',
                'Nhập tên đăng nhập',
                _nameController,
              ),
              _buildTextField('Email', 'Nhập địa chỉ email', _emailController),
              _buildTextField(
                isEditing ? 'Mật khẩu mới' : 'Mật khẩu',
                isEditing ? 'Để trống nếu không đổi' : 'Nhập mật khẩu',
                _passwordController,
                obscureText: true,
                required: !isEditing,
              ),

              // Role Dropdown
              _buildFieldRow(
                'Vai trò',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roles
                      .map(
                        (role) => FilterChip(
                          label: Text(RoleAccess.labels[role] ?? role),
                          selected: _selectedRoles.contains(role),
                          onSelected: _isLoading
                              ? null
                              : (selected) => setState(() {
                                  if (selected) {
                                    _selectedRoles.add(role);
                                  } else {
                                    _selectedRoles.remove(role);
                                  }
                                }),
                        ),
                      )
                      .toList(),
                ),
              ),

              if (isEditing) ...[
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
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
