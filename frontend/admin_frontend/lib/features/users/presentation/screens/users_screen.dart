import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/bulk_action_bar.dart';
import '../../../../widgets/common/zella_checkbox.dart';
import '../../../../widgets/common/zella_toast.dart';
import '../../../../theme/app_theme.dart';

import '../../data/models/user_response_model.dart';
import '../providers/users_provider.dart';
import '../dialogs/user_details_dialog.dart';
import '../dialogs/user_edit_dialog.dart';
import '../dialogs/role_create_dialog.dart';
import '../dialogs/user_lock_dialog.dart';
import '../dialogs/user_delete_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UsersProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FeatureHeader(
                  title: 'Tài khoản hệ thống',
                  subtitle: 'Quản lý tài khoản và phân quyền truy cập',
                  secondaryAction: OutlinedButton.icon(
                    icon: const Icon(Symbols.add, size: 18),
                    label: const Text('Thêm role'),
                    onPressed: () async {
                      final created = await showDialog<bool>(
                        context: context,
                        builder: (_) => const RoleCreateDialog(),
                      );
                      if (created == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm role')),
                        );
                      }
                    },
                  ),
                  actionLabel: 'Tạo tài khoản',
                  actionIcon: Symbols.add,
                  onExportPressed: () {},
                  onActionPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const UserEditDialog(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FeatureToolbar(
                  searchHint: 'Tìm kiếm theo tên tài khoản',
                  onSearchChanged: (query) {
                    context.read<UsersProvider>().loadItems(
                      query: query,
                      page: 0,
                    );
                  },
                  initialSearchText: context.read<UsersProvider>().currentQuery,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(children: [_buildTable()]),
                ),
              ],
            ),
          ),
          BulkActionBar(
            selectedCount: selectedIds.length,
            itemLabel: 'tài khoản',
            onClear: () => setState(() => selectedIds.clear()),
            actions: [
              BulkActionButton(
                icon: Symbols.lock,
                tooltip: 'Khóa',
                onPressed: () async {
                  final ids = selectedIds.toList();
                  await context.read<UsersProvider>().toggleActiveBulk(
                    ids,
                    false,
                  );
                  if (context.mounted) {
                    ZellaToast.show(
                      context,
                      message: 'Đã khóa ${ids.length} tài khoản',
                      type: ToastType.success,
                    );
                  }
                  setState(() => selectedIds.clear());
                },
              ),
              BulkActionButton(
                icon: Symbols.lock_open,
                tooltip: 'Mở khóa',
                onPressed: () async {
                  final ids = selectedIds.toList();
                  await context.read<UsersProvider>().toggleActiveBulk(
                    ids,
                    true,
                  );
                  if (context.mounted) {
                    ZellaToast.show(
                      context,
                      message: 'Đã mở khóa ${ids.length} tài khoản',
                      type: ToastType.success,
                    );
                  }
                  setState(() => selectedIds.clear());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      alignment: Alignment.centerLeft,
                      child: ZellaCheckbox(
                        value:
                            users.isNotEmpty &&
                            selectedIds.length == users.length,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedIds.addAll(users.map((e) => e.id));
                            } else {
                              selectedIds.clear();
                            }
                          });
                        },
                      ),
                    ),
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                    child: Text(
                      'Không có dữ liệu',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
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
              const Divider(height: 1, color: AppTheme.borderLight),
              PaginationFooter(
                currentPage: provider.currentPage,
                totalPages:
                    (provider.totalElements / provider.pageSize).ceil() == 0
                    ? 1
                    : (provider.totalElements / provider.pageSize).ceil(),
                totalElements: provider.totalElements,
                pageSize: provider.pageSize,
                onPageChanged: (page) => provider.loadItems(page: page),
              ),
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
    final roleDisplay = user.roles.isEmpty
        ? 'USER'
        : '${user.roles.first}${user.roles.length > 1 ? ' +${user.roles.length - 1}' : ''}';
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
        onTap: () {},
        hoverColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                alignment: Alignment.centerLeft,
                child: ZellaCheckbox(
                  value: selectedIds.contains(user.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedIds.add(user.id);
                      } else {
                        selectedIds.remove(user.id);
                      }
                    });
                  },
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(25),
                      child: Text(
                        user.username.isNotEmpty
                            ? user.username.substring(0, 1).toUpperCase()
                            : 'U',
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
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: user.roles.join(', '),
                    child: StatusBadge(
                      text: roleDisplay,
                      textColor: roleDisplay.toLowerCase() == 'super admin'
                          ? AppTheme.primary
                          : roleDisplay.toLowerCase() == 'admin'
                          ? const Color(0xFF1976D2)
                          : roleDisplay.toLowerCase() == 'manager'
                          ? const Color(0xFF7B1FA2)
                          : AppTheme.textSecondary,
                      backgroundColor:
                          roleDisplay.toLowerCase() == 'super admin'
                          ? AppTheme.primary.withAlpha(25)
                          : roleDisplay.toLowerCase() == 'admin'
                          ? const Color(0xFFE3F2FD)
                          : roleDisplay.toLowerCase() == 'manager'
                          ? const Color(0xFFF3E5F5)
                          : AppTheme.surface,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    text: statusDisplay,
                    textColor: statusDisplay.toLowerCase() == 'hoạt động'
                        ? AppTheme.success
                        : AppTheme.danger,
                    backgroundColor: statusDisplay.toLowerCase() == 'hoạt động'
                        ? AppTheme.success.withAlpha(25)
                        : AppTheme.danger.withAlpha(25),
                  ),
                ),
              ),
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
              SizedBox(
                width: 48,
                child: ActionMenu(
                  items: [
                    const ActionMenuItem(
                      value: 'view',
                      label: 'Xem chi tiết',
                      icon: Symbols.visibility,
                    ),
                    const ActionMenuItem(
                      value: 'edit',
                      label: 'Chỉnh sửa',
                      icon: Symbols.edit,
                    ),
                    // const ActionMenuItem(
                    //   value: 'permission',
                    //   label: 'Phân quyền',
                    //   icon: Symbols.shield,
                    // ),
                    // const ActionMenuItem(
                    //   value: 'reset_password',
                    //   label: 'Cấp lại mật khẩu',
                    //   icon: Symbols.lock_reset,
                    // ),
                    // ActionMenuItem.divider(),
                    // ActionMenuItem(
                    //   value: 'lock',
                    //   label: user.isActive
                    //       ? 'Khóa tài khoản'
                    //       : 'Mở khóa tài khoản',
                    //   icon: user.isActive
                    //       ? Symbols.lock
                    //       : Symbols.lock_open,
                    //   color: user.isActive
                    //       ? AppTheme.warning
                    //       : AppTheme.success,
                    // ),
                    // ActionMenuItem(
                    //   value: 'delete',
                    //   label: 'Xóa tài khoản',
                    //   icon: Symbols.delete,
                    //   color: AppTheme.danger,
                    // ),
                  ],
                  onSelected: (value) {
                    final userMap = {
                      'id': user.id,
                      'name': user.username,
                      'email': user.email,
                      'role': roleDisplay,
                      'status': statusDisplay,
                      'roles': user.roles,
                      'isActive': user.isActive,
                    };

                    switch (value) {
                      case 'view':
                        showDialog(
                          context: context,
                          builder: (_) => UserDetailsDialog(user: userMap),
                        );
                        break;
                      case 'edit':
                        showDialog(
                          context: context,
                          builder: (_) => UserEditDialog(user: userMap),
                        );
                        break;
                      case 'permission':
                        showDialog(
                          context: context,
                          builder: (_) => UserEditDialog(user: userMap),
                        );
                        break;
                      case 'reset_password':
                        showDialog(
                          context: context,
                          builder: (_) => UserEditDialog(user: userMap),
                        );
                        break;
                      case 'lock':
                        showDialog(
                          context: context,
                          builder: (_) => UserLockDialog(user: userMap),
                        );
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (_) => UserDeleteDialog(user: userMap),
                        );
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
