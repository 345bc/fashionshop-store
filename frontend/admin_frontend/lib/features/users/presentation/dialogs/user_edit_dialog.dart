import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
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
  String _selectedRole = 'USER';
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _roles = ['ADMIN', 'USER', 'EMPLOYEE'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?['name']);
    _emailController = TextEditingController(text: widget.user?['email']);
    _passwordController = TextEditingController();
    
    if (widget.user != null) {
      if (widget.user!['roles'] != null && (widget.user!['roles'] as List).isNotEmpty) {
        String role = (widget.user!['roles'] as List).first.toString().toUpperCase();
        if (_roles.contains(role)) {
          _selectedRole = role;
        }
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
    
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<UsersProvider>();
      final isEditing = widget.user != null;
      
      final data = {
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'roles': [_selectedRole],
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
          SnackBar(content: Text('Lỗi: $errorMsg'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480, 
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                isEditing ? 'Chỉnh sửa tài khoản' : 'Thêm mới tài khoản',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 24),
              
              // Form Fields
              _buildTextField('Tên đăng nhập', 'Nhập tên đăng nhập...', _nameController),
              const SizedBox(height: 16),
              _buildTextField('Email', 'Nhập địa chỉ email...', _emailController),
              const SizedBox(height: 16),
              _buildTextField(
                isEditing ? 'Mật khẩu (Để trống nếu không đổi)' : 'Mật khẩu', 
                'Nhập mật khẩu...', 
                _passwordController, 
                obscureText: true,
                required: !isEditing
              ),
              const SizedBox(height: 16),
              
              // Role Dropdown
              const Text('Vai trò', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderLight)),
                ),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              
              if (isEditing) ...[
                Row(
                  children: [
                    Switch(
                      value: _isActive, 
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(_isActive ? 'Hoạt động' : 'Đã khoá', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEditing ? 'Lưu thay đổi' : 'Tạo tài khoản'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool obscureText = false, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập trường này';
            }
            return null;
          } : null,
        ),
      ],
    );
  }
}
