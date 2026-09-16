import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class UserActionMenu extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onPermission;
  final VoidCallback onResetPassword;
  final VoidCallback onLock;
  final VoidCallback onDelete;
  final bool isLocked;

  const UserActionMenu({
    super.key,
    required this.onView,
    required this.onEdit,
    required this.onPermission,
    required this.onResetPassword,
    required this.onLock,
    required this.onDelete,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppTheme.textSecondary,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 12),
              Text('Xem chi tiết'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text('Sửa tài khoản'),
            ],
          ),
        ),
        // const PopupMenuItem(
        //   value: 'permission',
        //   child: Row(
        //     children: [
        //       Icon(Icons.admin_panel_settings_outlined, size: 18),
        //       SizedBox(width: 12),
        //       Text('Phân quyền'),
        //     ],
        //   ),
        // ),
        // const PopupMenuItem(
        //   value: 'reset_password',
        //   child: Row(
        //     children: [
        //       Icon(Icons.lock_reset_outlined, size: 18),
        //       SizedBox(width: 12),
        //       Text('Đặt lại mật khẩu'),
        //     ],
        //   ),
        // ),
        // const PopupMenuDivider(),
        // PopupMenuItem(
        //   value: 'lock',
        //   child: Row(
        //     children: [
        //       Icon(
        //         isLocked ? Icons.lock_open_outlined : Icons.lock_outline,
        //         size: 18,
        //         color: AppTheme.warning,
        //       ),
        //       const SizedBox(width: 12),
        //       Text(
        //         isLocked ? 'Mở khóa' : 'Khóa tài khoản',
        //         style: const TextStyle(color: AppTheme.warning),
        //       ),
        //     ],
        //   ),
        // ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
              SizedBox(width: 12),
              Text('Xóa', style: TextStyle(color: AppTheme.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
