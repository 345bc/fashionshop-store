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
import '../../../../core/security/role_access.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

import '../../data/models/user_response_model.dart';
import '../providers/users_provider.dart';
import '../dialogs/user_edit_dialog.dart';
import '../dialogs/role_create_dialog.dart';

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
                        ZellaToast.show(
                          context,
                          message: 'Đã thêm role',
                          type: ToastType.success,
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
                  filterWidget: Consumer<UsersProvider>(
                    builder: (context, provider, _) {
                      final roles = <String>{
                        ...RoleAccess.labels.keys,
                        ...provider.items.expand((user) => user.roles),
                      };
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilterDropdown<String>(
                            label: 'Vai trò',
                            searchHint: 'Tìm vai trò',
                            value: provider.currentRole ?? 'ALL',
                            defaultValue: 'ALL',
                            options: roles
                                .map(
                                  (role) => FilterOption(
                                    value: role,
                                    label: RoleAccess.labels[role] ?? role,
                                  ),
                                )
                                .toList(),
                            onChanged: (role) {
                              setState(() => selectedIds.clear());
                              provider.loadItems(role: role);
                            },
                          ),
                          FilterDropdown<String>(
                            label: 'Trạng thái',
                            value: provider.currentStatus,
                            defaultValue: 'ALL',
                            options: const [
                              FilterOption(
                                value: 'ACTIVE',
                                label: 'Hoạt động',
                                icon: Symbols.check_circle,
                                iconColor: AppTheme.success,
                              ),
                              FilterOption(
                                value: 'LOCKED',
                                label: 'Đã khóa',
                                icon: Symbols.lock,
                                iconColor: AppTheme.danger,
                              ),
                            ],
                            onChanged: (status) {
                              setState(() => selectedIds.clear());
                              provider.loadItems(status: status);
                            },
                          ),
                        ],
                      );
                    },
                  ),
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
    final canManageSuperadmins =
        context.watch<AuthProvider?>()?.hasRole('SUPERADMIN') ?? false;
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
        final editableIds = users
            .where(
              (user) =>
                  canManageSuperadmins || !user.roles.contains('SUPERADMIN'),
            )
            .map((user) => user.id)
            .toSet();

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
                            editableIds.isNotEmpty &&
                            selectedIds.containsAll(editableIds),
                        onChanged: editableIds.isEmpty
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    selectedIds.addAll(editableIds);
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
                    return _buildDataRow(
                      context,
                      user,
                      editableIds.contains(user.id),
                    );
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

  Widget _buildDataRow(
    BuildContext context,
    UserResponseModel user,
    bool canEdit,
  ) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              alignment: Alignment.centerLeft,
              child: ZellaCheckbox(
                value: selectedIds.contains(user.id),
                onChanged: !canEdit
                    ? null
                    : (v) {
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
                    backgroundColor: roleDisplay.toLowerCase() == 'super admin'
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
              child: !canEdit
                  ? null
                  : ActionMenu(
                      items: const [
                        ActionMenuItem(
                          value: 'edit',
                          label: 'Chỉnh sửa',
                          icon: Symbols.edit,
                        ),
                      ],
                      onSelected: (_) {
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
