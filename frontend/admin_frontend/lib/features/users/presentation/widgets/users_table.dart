// GENERATED FROM TEMPLATE: templates/feature_table.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'user_status_badge.dart';
import 'user_action_menu.dart';
import 'user_role_badge.dart';
import '../dialogs/user_details_dialog.dart';
import '../dialogs/user_edit_dialog.dart';
import '../dialogs/user_permissions_dialog.dart';
import '../dialogs/user_reset_password_dialog.dart';
import '../dialogs/user_lock_dialog.dart';
import '../dialogs/user_delete_dialog.dart';

class UsersTable extends StatelessWidget {
  const UsersTable({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data cho UI
    final List<Map<String, dynamic>> users = [
      {
        'name': 'Nguyễn Văn A',
        'email': 'nva@example.com',
        'role': 'Super Admin',
        'status': 'Hoạt động',
        '2fa': true,
        'last_login': '2 giờ trước'
      },
      {
        'name': 'Trần Thị B',
        'email': 'ttb@example.com',
        'role': 'Admin',
        'status': 'Hoạt động',
        '2fa': false,
        'last_login': '1 ngày trước'
      },
      {
        'name': 'Lê Văn C',
        'email': 'lvc@example.com',
        'role': 'Manager',
        'status': 'Bị khóa',
        '2fa': true,
        'last_login': '3 ngày trước'
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Tài khoản', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Vai trò', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
                Expanded(flex: 3, child: Text('Đăng nhập gần nhất', style: _headerStyle())),
                const SizedBox(width: 48), // Action space
              ],
            ),
          ),
          // Data Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildDataRow(context, user);
            },
          ),
          // Pagination Footer
          const Divider(height: 1, color: AppTheme.borderLight),
          _buildPagination(),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    );
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // User Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        user['name'].substring(0, 1),
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(user['email'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              // Role
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserRoleBadge(role: user['role']),
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserStatusBadge(status: user['status']),
                ),
              ),
              // Last Login
              Expanded(
                flex: 3,
                child: Text(
                  user['last_login'],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              // Actions
              SizedBox(
                width: 48,
                child: UserActionMenu(
                  isLocked: user['status'] == 'Bị khóa',
                  onView: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserDetailsDialog(user: user),
                    );
                  },
                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserEditDialog(user: user),
                    );
                  },
                  onPermission: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserPermissionsDialog(user: user),
                    );
                  },
                  onResetPassword: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserResetPasswordDialog(user: user),
                    );
                  },
                  onLock: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserLockDialog(user: user),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserDeleteDialog(user: user),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hiển thị 1-10 trong số 124 tài khoản',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, onPressed: null), // Disabled
              const SizedBox(width: 8),
              _buildPageNumber('1', isActive: true),
              const SizedBox(width: 4),
              _buildPageNumber('2'),
              const SizedBox(width: 4),
              _buildPageNumber('3'),
              const SizedBox(width: 4),
              const Text('...', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(width: 4),
              _buildPageNumber('13'),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPageNumber(String text, {bool isActive = false}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(8),
          color: onPressed == null ? AppTheme.surface : Colors.white,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? AppTheme.border : AppTheme.text,
        ),
      ),
    );
  }
}

