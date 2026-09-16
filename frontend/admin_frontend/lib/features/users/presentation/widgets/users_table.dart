import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../providers/users_provider.dart';
import '../../data/models/user_response_model.dart';
import 'user_status_badge.dart';
import 'user_action_menu.dart';
import 'user_role_badge.dart';
import '../dialogs/user_details_dialog.dart';
import '../dialogs/user_edit_dialog.dart';
import '../dialogs/user_permissions_dialog.dart';
import '../dialogs/user_reset_password_dialog.dart';
import '../dialogs/user_lock_dialog.dart';
import '../dialogs/user_delete_dialog.dart';
import 'package:intl/intl.dart';

class UsersTable extends StatelessWidget {
  const UsersTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && provider.items.isEmpty) {
          final errorMsg = provider.error!.replaceAll('Exception: ', '');
          return Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Text(
                'Lỗi: $errorMsg',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          );
        }

        final users = provider.items;

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
                    Expanded(
                      flex: 3,
                      child: Text('Tài khoản', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Vai trò', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Trạng thái', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Ngày tạo', style: _headerStyle()),
                    ),
                    const SizedBox(width: 48), // Action space
                  ],
                ),
              ),
              // Data Rows
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildDataRow(context, user);
                  },
                ),
              // Pagination Footer
              const Divider(height: 1, color: AppTheme.borderLight),
              _buildPagination(context, provider),
            ],
          ),
        );
      },
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    );
  }

  Widget _buildDataRow(BuildContext context, UserResponseModel user) {
    // Map data to the existing UI format
    final roleDisplay = user.roles.isNotEmpty ? user.roles.first : 'USER';
    final statusDisplay = user.isActive ? 'Hoạt động' : 'Bị khóa';
    
    String dateDisplay = '';
    if (user.createdAt != null) {
      try {
        final date = DateTime.parse(user.createdAt!).toLocal();
        dateDisplay = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        dateDisplay = user.createdAt!;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Xử lý khi nhấn vào dòng (vd: xem chi tiết)
        },
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
                        user.username.isNotEmpty ? user.username.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Role
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserRoleBadge(role: roleDisplay),
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserStatusBadge(status: statusDisplay),
                ),
              ),
              // Created At
              Expanded(
                flex: 3,
                child: Text(
                  dateDisplay,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 48,
                child: UserActionMenu(
                  isLocked: !user.isActive,
                  onView: () {
                    // Create a dummy map since old code used map
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                      'role': roleDisplay,
                      'status': statusDisplay,
                      '2fa': false,
                      'last_login': dateDisplay,
                      'roles': user.roles,
                      'isActive': user.isActive,
                    };
                    showDialog(
                      context: context,
                      builder: (_) => UserDetailsDialog(user: userMap),
                    );
                  },
                  onEdit: () {
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                      'role': roleDisplay,
                      'status': statusDisplay,
                      'roles': user.roles,
                      'isActive': user.isActive,
                    };
                    showDialog(
                      context: context,
                      builder: (_) => UserEditDialog(user: userMap),
                    );
                  },
                  onPermission: () {
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                      'role': roleDisplay,
                      'status': statusDisplay,
                      'roles': user.roles,
                      'isActive': user.isActive,
                    };
                    showDialog(
                      context: context,
                      builder: (_) => UserPermissionsDialog(user: userMap),
                    );
                  },
                  onResetPassword: () {
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                    };
                    showDialog(
                      context: context,
                      builder: (_) => UserResetPasswordDialog(user: userMap),
                    );
                  },
                  onLock: () {
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                      'roles': user.roles,
                      'isActive': user.isActive,
                    };
                    showDialog(
                      context: context,
                      builder: (_) => UserLockDialog(user: userMap),
                    );
                  },
                  onDelete: () {
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                      'roles': user.roles,
                      'isActive': user.isActive,
                    };
                    showDialog(
                      context: context,
                      builder: (_) => UserDeleteDialog(user: userMap),
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

  Widget _buildPagination(BuildContext context, UsersProvider provider) {
    int totalPages = (provider.totalElements / provider.pageSize).ceil();
    if (totalPages == 0) totalPages = 1;
    
    final currentPage = provider.currentPage;

    int start = currentPage * provider.pageSize + 1;
    int end = (currentPage + 1) * provider.pageSize;
    if (end > provider.totalElements) end = provider.totalElements;
    if (provider.totalElements == 0) start = 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start-$end trong số ${provider.totalElements} tài khoản',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(
                Icons.chevron_left, 
                onPressed: currentPage > 0 
                    ? () => provider.loadItems(page: currentPage - 1)
                    : null,
              ), 
              const SizedBox(width: 8),
              
              // Đơn giản hóa pagination: hiển thị tối đa 5 trang
              ...List.generate(totalPages, (index) {
                // Chỉ hiển thị 5 trang gần nhất
                if (totalPages > 5) {
                  if (index != 0 && index != totalPages - 1 && (index < currentPage - 1 || index > currentPage + 1)) {
                    // Hiển thị ... thay vì số
                    if (index == 1 || index == totalPages - 2) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('...', style: TextStyle(color: AppTheme.textSecondary)),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildPageNumber(
                    '${index + 1}', 
                    isActive: currentPage == index,
                    onTap: () => provider.loadItems(page: index),
                  ),
                );
              }),

              const SizedBox(width: 4),
              _buildPageButton(
                Icons.chevron_right, 
                onPressed: currentPage < totalPages - 1 
                    ? () => provider.loadItems(page: currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(String text, {bool isActive = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: isActive ? null : onTap,
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
