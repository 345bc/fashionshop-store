import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../../../widgets/common/bulk_action_bar.dart';
import '../../../../widgets/common/zella_checkbox.dart';
import '../../../../widgets/common/zella_toast.dart';
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
  Set<int> selectedIds = {};

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
    body: Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          FeatureHeader(
            title: 'Nhà cung cấp',
            subtitle: 'Quản lý thông tin đối tác cung ứng',
            actionLabel: 'Thêm nhà cung cấp',
            actionIcon: Symbols.add,
            onActionPressed: () => showDialog(
              context: context,
              builder: (_) => const SupplierFormDialog(),
            ),
          ),
          const SizedBox(height: 32),
          FeatureToolbar(
            searchHint: 'Tìm theo tên, mã, người liên hệ, email hoặc SĐT',
            onSearchChanged: context.read<SuppliersProvider>().setQuery,
            filterWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilterDropdown<String>(
                  label: 'Trạng thái',
                  searchHint: 'Tìm kiếm trạng thái',
                  value: _status,
                  defaultValue: 'all',
                  options: const [
                    FilterOption(
                      value: 'active',
                      label: 'Hoạt động',
                      icon: Symbols.check_circle,
                      iconColor: AppTheme.success,
                    ),
                    FilterOption(
                      value: 'inactive',
                      label: 'Đã ẩn',
                      icon: Symbols.cancel,
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _status = val);
                    context.read<SuppliersProvider>().setStatus(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
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
                        horizontal: 28,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            alignment: Alignment.centerLeft,
                            child: ZellaCheckbox(
                              value: provider.pageItems.isNotEmpty && selectedIds.length == provider.pageItems.length,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    selectedIds.addAll(provider.pageItems.map((e) => e.id));
                                  } else {
                                    selectedIds.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          Expanded(flex: 3, child: _header('NHÀ CUNG CẤP')),
                          Expanded(flex: 2, child: _header('LIÊN HỆ')),
                          Expanded(flex: 2, child: _header('SỐ ĐIỆN THOẠI')),
                          Expanded(flex: 2, child: _header('TRẠNG THÁI')),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
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
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppTheme.borderLight,
                        ),
                        itemBuilder: (context, index) =>
                            _row(provider.pageItems[index]),
                      ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PaginationFooter(
                        currentPage: provider.currentPage,
                        totalPages: provider.totalElements == 0
                            ? 1
                            : (provider.totalElements / provider.pageSize)
                                  .ceil(),
                        totalElements: provider.totalElements,
                        pageSize: provider.pageSize,
                        onPageChanged: provider.setPage,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
    BulkActionBar(
      selectedCount: selectedIds.length,
      itemLabel: 'nhà cung cấp',
      onClear: () => setState(() => selectedIds.clear()),
      actions: [
        BulkActionButton(
          icon: Symbols.visibility_off,
          tooltip: 'Ẩn',
          onPressed: () async {
            final ids = selectedIds.toList();
            await context.read<SuppliersProvider>().toggleActiveBulk(ids, false);
            if (context.mounted) {
              ZellaToast.show(
                context,
                message: 'Đã ẩn ${ids.length} nhà cung cấp',
                type: ToastType.success,
              );
            }
            setState(() => selectedIds.clear());
          },
        ),
        BulkActionButton(
          icon: Symbols.visibility,
          tooltip: 'Hoạt động',
          onPressed: () async {
            final ids = selectedIds.toList();
            await context.read<SuppliersProvider>().toggleActiveBulk(ids, true);
            if (context.mounted) {
              ZellaToast.show(
                context,
                message: 'Đã hiện ${ids.length} nhà cung cấp',
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

  Widget _header(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.5,
    ),
  );

  Widget _row(SupplierResponseModel s) => Material(
    color: Colors.transparent,
    child: InkWell(
      hoverColor: AppTheme.surface,
      onTap: () => showDialog(
        context: context,
        builder: (_) => SupplierDetailDialog(supplierId: s.id),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              alignment: Alignment.centerLeft,
              child: ZellaCheckbox(
                value: selectedIds.contains(s.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedIds.add(s.id);
                    } else {
                      selectedIds.remove(s.id);
                    }
                  });
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.code?.isNotEmpty == true ? s.code! : '#${s.id}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.person,
                        size: 16,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.contactPerson ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Symbols.mail,
                        size: 16,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.contactEmail ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Symbols.call,
                    size: 16,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.phone ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: s.isActive ? 'Hoạt động' : 'Đã ẩn',
                  textColor: s.isActive
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                  backgroundColor:
                      (s.isActive ? AppTheme.success : AppTheme.textSecondary)
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
                    icon: Symbols.visibility,
                  ),
                  ActionMenuItem(
                    value: 'edit',
                    label: 'Chỉnh sửa',
                    icon: Symbols.edit,
                  ),
                  if (context.read<AuthProvider>().hasRole('ADMIN'))
                    const ActionMenuItem(
                      value: 'delete',
                      label: 'Xóa',
                      icon: Symbols.delete,
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
