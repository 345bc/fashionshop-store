import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../../../widgets/common/bulk_action_bar.dart';
import '../../../../widgets/common/zella_checkbox.dart';
import '../../../../widgets/common/zella_toast.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../providers/product_variants_provider.dart';

class ProductVariantsScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductVariantsScreen({super.key, required this.product});

  @override
  State<ProductVariantsScreen> createState() => _ProductVariantsScreenState();
}

class _ProductVariantsScreenState extends State<ProductVariantsScreen> {
  Set<int> selectedIds = {};
  bool _deleting = false;
  int? get _productId => (widget.product?['id'] as num?)?.toInt();

  Future<void> _confirmDelete(Set<int> ids, {String? sku}) async {
    final productId = _productId;
    if (_deleting || productId == null || ids.isEmpty) return;
    final provider = context.read<ProductVariantsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ZellaConfirmDialog(
        title: sku == null ? 'Xóa ${ids.length} biến thể?' : 'Xóa biến thể?',
        content: Text(
          sku == null
              ? 'Chỉ những biến thể đủ điều kiện mới bị xóa. Thao tác này không thể hoàn tác.'
              : 'Xóa biến thể “$sku”? Thao tác này không thể hoàn tác.',
        ),
        confirmText: 'Xóa',
        onCancel: () => Navigator.pop(dialogContext, false),
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true || !mounted || _deleting || _productId != productId)
      return;
    setState(() => _deleting = true);
    try {
      final result = await provider.deleteItems(productId, ids);
      if (!mounted || _productId != productId) return;
      setState(() => selectedIds.removeAll(result.deleted));
      final count = result.deleted.length;
      ZellaToast.show(
        context,
        message: result.errors.isEmpty
            ? 'Đã xóa $count biến thể.'
            : count == 0 && ids.length == 1
            ? result.errors.values.first
            : 'Đã xóa $count/${ids.length} biến thể. ${result.errors.values.first}',
        type: result.errors.isEmpty
            ? ToastType.success
            : count == 0
            ? ToastType.error
            : ToastType.warning,
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = _productId;
      if (!mounted || id == null) return;
      final provider = context.read<ProductVariantsProvider>();
      provider.loadItems(
        productId: id,
        page: provider.productId == id ? provider.currentPage : 0,
      );
    });
  }

  @override
  void didUpdateWidget(covariant ProductVariantsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = (oldWidget.product?['id'] as num?)?.toInt();
    if (_productId != oldId && _productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ProductVariantsProvider>().loadItems(
            productId: _productId!,
            query: '',
          );
        }
      });
    }
  }

  String _money(dynamic value) {
    final amount = (value as num?)?.toInt() ?? 0;
    final digits = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$digits  VND';
  }

  @override
  Widget build(BuildContext context) {
    final id = _productId;
    if (id == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không tìm thấy sản phẩm'),
            TextButton(
              onPressed: () => MainScreen.of(context).navigate('/products'),
              child: const Text('Về danh sách sản phẩm'),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Về sản phẩm',
                    onPressed: () =>
                        MainScreen.of(context).navigate('/products'),
                    icon: const Icon(Symbols.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biến thể: ${widget.product?['name'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã sản phẩm #$id · ${widget.product?['slug'] ?? ''}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => MainScreen.of(context).navigate(
                      '/products/variants/new',
                      {'product': widget.product},
                    ),
                    icon: const Icon(Symbols.add),
                    label: const Text('Thêm biến thể'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FeatureToolbar(
                initialSearchText: context.select(
                  (ProductVariantsProvider provider) =>
                      provider.productId == id ? provider.query : '',
                ),
                searchHint:
                    'Tìm theo SKU, tên SP, danh mục, kích cỡ hoặc màu sắc',
                onSearchChanged: (query) => context
                    .read<ProductVariantsProvider>()
                    .loadItems(productId: id, query: query),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Consumer<ProductVariantsProvider>(
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
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Không tải được biến thể: ${provider.error}',
                                style: const TextStyle(color: AppTheme.error),
                              ),
                              TextButton(
                                onPressed: () => provider.loadItems(
                                  productId: id,
                                  page: provider.currentPage,
                                ),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
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
                              Container(
                                width: 48,
                                alignment: Alignment.centerLeft,
                                child: ZellaCheckbox(
                                  value:
                                      provider.items.isNotEmpty &&
                                      selectedIds.length ==
                                          provider.items.length,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        selectedIds.addAll(
                                          provider.items.map(
                                            (e) => (e['id'] as num).toInt(),
                                          ),
                                        );
                                      } else {
                                        selectedIds.clear();
                                      }
                                    });
                                  },
                                ),
                              ),
                              Expanded(flex: 3, child: _heading('BIẾN THỂ')),
                              Expanded(
                                flex: 2,
                                child: _heading('GIÁ BÁN / GIÁ VỐN'),
                              ),
                              Expanded(flex: 2, child: _heading('TỒN KHO')),
                              Expanded(flex: 2, child: _heading('TRẠNG THÁI')),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (provider.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Text('Chưa có biến thể nào'),
                          )
                        else
                          ..._groupedRows(provider.items),
                        const Divider(height: 1),
                        PaginationFooter(
                          currentPage: provider.currentPage,
                          totalPages: provider.totalElements == 0
                              ? 1
                              : (provider.totalElements / provider.pageSize)
                                    .ceil(),
                          totalElements: provider.totalElements,
                          pageSize: provider.pageSize,
                          onPageChanged: (page) =>
                              provider.loadItems(productId: id, page: page),
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
          itemLabel: 'biến thể',
          onClear: () => setState(() => selectedIds.clear()),
          actions: [
            BulkActionButton(
              icon: Symbols.visibility_off,
              tooltip: 'Ẩn',
              onPressed: () async {
                final ids = selectedIds.toList();
                await context.read<ProductVariantsProvider>().toggleActiveBulk(
                  ids,
                  false,
                );
                if (context.mounted) {
                  ZellaToast.show(
                    context,
                    message: 'Đã ẩn ${ids.length} biến thể',
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
                await context.read<ProductVariantsProvider>().toggleActiveBulk(
                  ids,
                  true,
                );
                if (context.mounted) {
                  ZellaToast.show(
                    context,
                    message: 'Đã hiện ${ids.length} biến thể',
                    type: ToastType.success,
                  );
                }
                setState(() => selectedIds.clear());
              },
            ),
            if (context.watch<AuthProvider>().hasRole('ADMIN'))
              BulkActionButton(
                icon: Symbols.delete,
                isDanger: true,
                tooltip: 'Xóa biến thể đã chọn',
                onPressed: () => _confirmDelete(Set.of(selectedIds)),
              ),
          ],
        ),
      ],
    );
  }

  Text _heading(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AppTheme.textSecondary,
    ),
  );

  List<Widget> _groupedRows(List<Map<String, dynamic>> variants) {
    final groups = <Object?, List<Map<String, dynamic>>>{};
    for (final variant in variants) {
      final color = variant['colorId'] ?? variant['colorName'];
      groups.putIfAbsent(color, () => []).add(variant);
    }
    return [
      for (final group in groups.values) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppTheme.surface,
          child: Text(
            group.first['colorName']?.toString() ?? 'Chưa có màu',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        for (final variant in group) ...[
          const Divider(height: 1),
          _row(variant),
        ],
      ],
    ];
  }

  Widget _row(Map<String, dynamic> variant) {
    final isActive = variant['isActive'] == true;
    final stock = (variant['stockQuantity'] as num?)?.toInt() ?? 0;
    final reserved = (variant['reservedQuantity'] as num?)?.toInt() ?? 0;
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
                value: selectedIds.contains((variant['id'] as num).toInt()),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedIds.add((variant['id'] as num).toInt());
                    } else {
                      selectedIds.remove((variant['id'] as num).toInt());
                    }
                  });
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant['sku']?.toString() ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${variant['sizeName'] ?? '—'}',
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
                  Text(_money(variant['price'])),
                  const SizedBox(height: 4),
                  Text(
                    'Vốn: ${_money(variant['costPrice'])}',
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
                  Text(
                    '$stock',
                    style: TextStyle(
                      color: stock == 0 ? AppTheme.error : AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã đặt: $reserved · Còn: ${stock - reserved}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: isActive ? 'Đang bán' : 'Ngừng bán',
                  textColor: isActive ? AppTheme.success : AppTheme.danger,
                  backgroundColor:
                      (isActive ? AppTheme.success : AppTheme.danger).withAlpha(
                        25,
                      ),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: ActionMenu(
                items: [
                  const ActionMenuItem(
                    value: 'edit',
                    label: 'Chỉnh sửa',
                    icon: Symbols.edit,
                  ),
                  if (context.watch<AuthProvider>().hasRole('ADMIN') &&
                      variant['hasOrders'] != true) ...[
                    ActionMenuItem.divider(),
                    const ActionMenuItem(
                      value: 'delete',
                      label: 'Xóa biến thể',
                      icon: Symbols.delete,
                      color: AppTheme.danger,
                    ),
                  ],
                ],
                onSelected: (action) {
                  if (action == 'delete') {
                    _confirmDelete({
                      (variant['id'] as num).toInt(),
                    }, sku: variant['sku']?.toString());
                    return;
                  }
                  MainScreen.of(context).navigate('/products/variants/edit', {
                    'product': widget.product,
                    'variant': variant,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
