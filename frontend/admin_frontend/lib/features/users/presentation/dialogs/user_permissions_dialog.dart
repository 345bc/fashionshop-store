// GENERATED FROM TEMPLATE: templates/feature_dialog_form.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UserPermissionsDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserPermissionsDialog({super.key, required this.user});

  @override
  State<UserPermissionsDialog> createState() => _UserPermissionsDialogState();
}

class _UserPermissionsDialogState extends State<UserPermissionsDialog> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user['role'] ?? 'Viewer';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Phân quyền tài khoản',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thiết lập quyền truy cập cho ${widget.user['name']}',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Radio Options
            _buildRoleOption('Super Admin', 'Toàn quyền quản trị hệ thống, bao gồm cả cài đặt.'),
            const SizedBox(height: 12),
            _buildRoleOption('Admin', 'Quản trị viên, có thể chỉnh sửa mọi dữ liệu trừ cài đặt hệ thống.'),
            const SizedBox(height: 12),
            _buildRoleOption('Manager', 'Quản lý, có thể tạo và sửa đơn hàng, khách hàng.'),
            const SizedBox(height: 12),
            _buildRoleOption('Viewer', 'Chỉ được phép xem dữ liệu, không thể thao tác thêm, sửa, xóa.'),
            
            const SizedBox(height: 32),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Lưu phân quyền'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String role, String description) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primary.withAlpha(10) : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: role,
              groupValue: _selectedRole,
              activeColor: AppTheme.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

