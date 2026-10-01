import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../data/models/supplier_response_model.dart';
import '../dialogs/supplier_detail_dialog.dart';
import '../dialogs/supplier_form_dialog.dart';
import '../providers/suppliers_provider.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _status = 'all';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SuppliersProvider>().loadItems();
    });
  }

  Future<void> _delete(SupplierResponseModel supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ZellaConfirmDialog(
        title: 'Xóa nhà cung cấp',
        content: Text(
          'Xóa "${supplier.name}"? Nhà cung cấp đang gắn với sản phẩm hoặc phiếu nhập sẽ không thể xóa.',
        ),
        confirmText: 'Xóa',
        iconColor: AppTheme.danger,
        onCancel: () => Navigator.pop(dialogContext, false),
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<SuppliersProvider>().deleteItem(supplier.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã xóa nhà cung cấp')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa nhà cung cấp: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
            title: 'Nhà cung cấp',
            subtitle: 'Quản lý thông tin đối tác cung ứng',
            actionLabel: 'Thêm nhà cung cấp',
            actionIcon: Icons.add,
            onActionPressed: () => showDialog(
              context: context,
              builder: (_) => const SupplierFormDialog(),
            ),
          ),
          const SizedBox(height: 32),
          FeatureToolbar(
            searchHint: 'Tìm theo tên, mã, email hoặc số điện thoại...',
            onSearchChanged: context.read<SuppliersProvider>().setQuery,
            filterWidget: DropdownButton<String>(
              value: _status,
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả trạng thái'),
                ),
                DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                DropdownMenuItem(value: 'inactive', child: Text('Đã ẩn')),
              ],
              onChanged: (v) {
                setState(() => _status = v ?? 'all');
                context.read<SuppliersProvider>().setStatus(_status);
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
            child: Consumer<SuppliersProvider>(
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
                          Expanded(flex: 3, child: _header('NHÀ CUNG CẤP')),
                          Expanded(flex: 2, child: _header('LIÊN HỆ')),
                          Expanded(flex: 2, child: _header('SỐ ĐIỆN THOẠI')),
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

  Widget _row(SupplierResponseModel s) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => SupplierDetailDialog(supplierId: s.id),
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
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    s.code?.isNotEmpty == true ? s.code! : '#${s.id}',
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
                  Text(s.contactPerson ?? '—'),
                  Text(
                    s.contactEmail ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(s.phone ?? '—')),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: s.isActive ? 'Hoạt động' : 'Đã ẩn',
                  textColor: s.isActive ? AppTheme.success : AppTheme.danger,
                  backgroundColor:
                      (s.isActive ? AppTheme.success : AppTheme.danger)
                          .withAlpha(25),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: ActionMenu(
                items: [
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
                  if (context.read<AuthProvider>().user?.roles.any(
                        (role) => role == 'ADMIN' || role == 'ROLE_ADMIN',
                      ) ??
                      false)
                    const ActionMenuItem(
                      value: 'delete',
                      label: 'Xóa',
                      icon: Icons.delete_outline,
                      color: AppTheme.danger,
                    ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    showDialog(
                      context: context,
                      builder: (_) => SupplierDetailDialog(supplierId: s.id),
                    );
                  }
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) => SupplierFormDialog(supplier: s),
                    );
                  }
                  if (value == 'delete') _delete(s);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
