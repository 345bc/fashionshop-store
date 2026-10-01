import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'package:zella_admin_flutter/features/users/presentation/providers/users_provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../data/models/customer_response_model.dart';
import '../dialogs/customer_detail_dialog.dart';
import '../dialogs/customer_form_dialog.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _tier = 'all';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomersProvider>().loadItems();
      context.read<UsersProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureHeader(
            title: 'Khách hàng',
            subtitle: 'Quản lý hồ sơ và tài khoản khách hàng',
            actionLabel: "",
            actionIcon: Icons.add,
            onExportPressed:
                context.watch<AuthProvider>().user?.roles.any(
                      (role) => role == 'ADMIN' || role == 'ROLE_ADMIN',
                    ) ==
                    true
                ? () {
                    // TODO: Xử lý xuất dữ liệu
                  }
                : null,
            onActionPressed: () => showDialog(
              context: context,
              builder: (_) => const CustomerFormDialog(),
            ),
            showAction: false,
          ),
          const SizedBox(height: 32),
          FeatureToolbar(
            searchHint: 'Tìm theo tên, email hoặc số điện thoại...',
            onSearchChanged: context.read<CustomersProvider>().setQuery,
            filterWidget: DropdownButton<String>(
              value: _tier,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả hạng')),
                DropdownMenuItem(value: 'STANDARD', child: Text('Thường')),
                DropdownMenuItem(value: 'SILVER', child: Text('Bạc')),
                DropdownMenuItem(value: 'GOLD', child: Text('Vàng')),
                DropdownMenuItem(value: 'DIAMOND', child: Text('Kim cương')),
              ],
              onChanged: (v) {
                setState(() => _tier = v ?? 'all');
                context.read<CustomersProvider>().setFilter(_tier);
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Consumer<CustomersProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (provider.error != null && provider.items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(child: Text('Lỗi: ${provider.error}')),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _header('KHÁCH HÀNG')),
                          Expanded(flex: 2, child: _header('LIÊN HỆ')),
                          Expanded(flex: 1, child: _header('HẠNG')),
                          Expanded(flex: 2, child: _header('TRẠNG THÁI')),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (provider.pageItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Text('Không có dữ liệu'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.pageItems.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _row(provider.pageItems[index]),
                      ),
                    const Divider(height: 1),
                    PaginationFooter(
                      currentPage: provider.currentPage,
                      totalPages: provider.totalElements == 0
                          ? 1
                          : (provider.totalElements / provider.pageSize).ceil(),
                      totalElements: provider.totalElements,
                      pageSize: provider.pageSize,
                      onPageChanged: provider.setPage,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    ),
  );
  Widget _row(CustomerResponseModel c) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => CustomerDetailDialog(customerId: c.id),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '@${c.username}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.phone ?? '—'),
                  Text(
                    c.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(flex: 1, child: Text(c.membershipTier)),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: c.isActive ? 'Hoạt động' : 'Đã khóa',
                  textColor: c.isActive ? AppTheme.success : AppTheme.danger,
                  backgroundColor:
                      (c.isActive ? AppTheme.success : AppTheme.danger)
                          .withAlpha(25),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: ActionMenu(
                items: const [
                  ActionMenuItem(
                    value: 'view',
                    label: 'Xem chi tiết',
                    icon: Icons.visibility_outlined,
                  ),
                  ActionMenuItem(
                    value: 'edit',
                    label: 'Chỉnh sửa',
                    icon: Icons.edit_outlined,
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    showDialog(
                      context: context,
                      builder: (_) => CustomerDetailDialog(customerId: c.id),
                    );
                  }
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) => CustomerFormDialog(customer: c),
                    );
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
