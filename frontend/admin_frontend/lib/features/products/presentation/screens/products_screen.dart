import '../dialogs/product_content_dialog.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../../widgets/common/zella_checkbox.dart';
import '../../../../widgets/common/bulk_action_bar.dart';
import '../../../../widgets/common/zella_toast.dart';

import '../providers/products_provider.dart';
import '../../data/models/product_response_model.dart';
import '../dialogs/product_form_dialog.dart';
import '../dialogs/product_detail_dialog.dart';
import '../../../../main.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  Set<int> selectedIds = {};

  PopupMenuItem<String> _attributeOption(
    String route,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: route,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.text),
            ),
          ),
          const Icon(
            Symbols.chevron_right,
            size: 16,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductsProvider>().loadItems();
      context.read<CategoriesProvider>().loadOptions();
    });
  }

  String _fmtVND(double n) {
    return '${n.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}  VND';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by AppLayout
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FeatureHeader(
                  showAction: context.watch<AuthProvider>().hasRole('ADMIN'),
                  title: 'Sản phẩm & Bộ sưu tập',
                  subtitle: 'Quản lý hàng hoá, giá bán và thuộc tính',
                  secondaryAction:
                      context.watch<AuthProvider>().hasRole('ADMIN')
                      ? PopupMenuButton<String>(
                          tooltip: 'Thuộc tính sản phẩm',
                          position: PopupMenuPosition.under,
                          offset: const Offset(0, 8),
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          menuPadding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(
                            minWidth: 230,
                            maxWidth: 230,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                          onSelected: (route) =>
                              MainScreen.of(context).navigate(route),
                          itemBuilder: (_) => [
                            _attributeOption(
                              '/sizes',
                              'Kích thước',
                              Symbols.straighten,
                            ),
                            _attributeOption(
                              '/colors',
                              'Màu sắc',
                              Symbols.palette,
                            ),
                            _attributeOption(
                              '/sizeguides',
                              'Bảng kích thước',
                              Symbols.table_chart,
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Symbols.tune, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Thuộc tính sản phẩm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(
                                  Symbols.expand_more,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                  actionLabel: 'Thêm sản phẩm',
                  actionIcon: Symbols.add,
                  onExportPressed: () {},
                  onActionPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ProductFormDialog(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Consumer2<ProductsProvider, CategoriesProvider>(
                  builder: (context, products, categories, _) => FeatureToolbar(
                    searchHint: 'Tìm kiếm sản phẩm theo tên',
                    onSearchChanged: (query) =>
                        products.loadItems(query: query),
                    initialSearchText: products.currentQuery,
                    filterWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterDropdown<int>(
                          label: 'Danh mục',
                          searchHint: 'Tìm kiếm danh mục',
                          value: products.categoryId ?? 0,
                          defaultValue: 0,
                          options: [
                            if (products.categoryId != null &&
                                !categories.options.any(
                                  (c) => c.id == products.categoryId,
                                ))
                              FilterOption(
                                value: products.categoryId!,
                                label: 'Danh mục đang chọn',
                              ),
                            ...categories.options.map(
                              (category) => FilterOption<int>(
                                value: category.id,
                                label: category.parentName == null
                                    ? category.name
                                    : '${category.parentName} / ${category.name}',
                              ),
                            ),
                          ],
                          onChanged: (id) =>
                              products.setCategory(id == 0 ? null : id),
                        ),
                        if (categories.optionsError != null)
                          IconButton(
                            tooltip:
                                'Không tải được danh mục. Nhấn để thử lại.',
                            onPressed: categories.loadOptions,
                            icon: const Icon(
                              Symbols.refresh,
                              color: AppTheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(children: [_buildTable(context)]),
                ),
              ],
            ),
          ),
          if (context.watch<AuthProvider>().hasRole('ADMIN'))
            BulkActionBar(
              selectedCount: selectedIds.length,
              itemLabel: 'sản phẩm đã chọn',
              onClear: () => setState(() => selectedIds.clear()),
              actions: [
                BulkActionButton(
                  icon: Symbols.visibility_off,
                  tooltip: 'Ẩn',
                  onPressed: () async {
                    final ids = selectedIds.toList();
                    await context.read<ProductsProvider>().toggleActiveBulk(
                      ids,
                      false,
                    );
                    if (context.mounted) {
                      ZellaToast.show(
                        context,
                        message: 'Đã ẩn ${ids.length} sản phẩm',
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
                    await context.read<ProductsProvider>().toggleActiveBulk(
                      ids,
                      true,
                    );
                    if (context.mounted) {
                      ZellaToast.show(
                        context,
                        message: 'Đã hiện ${ids.length} sản phẩm',
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

  Widget _buildTable(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
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

        final products = provider.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ZellaCheckbox(
                    value:
                        products.isNotEmpty &&
                        selectedIds.length == products.length,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedIds = products.map((e) => e.id).toSet();
                        } else {
                          selectedIds.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _headerText('SẢN PHẨM')),
                  Expanded(flex: 2, child: _headerText('DANH MỤC')),
                  Expanded(flex: 2, child: _headerText('GIÁ BÁN')),
                  Expanded(flex: 2, child: _headerText('TRẠNG THÁI')),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (products.isEmpty)
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
                itemCount: products.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppTheme.borderLight),
                itemBuilder: (context, index) {
                  return _buildDataRow(context, products[index]);
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
        );
      },
    );
  }

  Text _headerText(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  void _showProductDetail(BuildContext context, ProductResponseModel product) {
    showDialog(
      context: context,
      builder: (_) => ProductDetailDialog(
        productId: product.id,
        onManageVariants: (details) =>
            MainScreen.of(context).navigate('/product-variants', details),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, ProductResponseModel product) {
    final statusDisplay = product.isActive ? 'Hoạt động' : 'Đã ẩn';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(context, product),
        hoverColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              ZellaCheckbox(
                value: selectedIds.contains(product.id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selectedIds.add(product.id);
                    } else {
                      selectedIds.remove(product.id);
                    }
                  });
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          product.name.isNotEmpty
                              ? product.name.substring(0, 1).toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
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
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.slug,
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
                child: Text(
                  product.categoryName,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _fmtVND(product.basePrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    text: statusDisplay,
                    textColor: product.isActive
                        ? AppTheme.success
                        : AppTheme.danger,
                    backgroundColor: product.isActive
                        ? AppTheme.success.withAlpha(25)
                        : AppTheme.danger.withAlpha(25),
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
                    if (context.watch<AuthProvider>().hasRole('MARKETING'))
                      const ActionMenuItem(
                        value: 'content',
                        label: 'Sửa nội dung',
                        icon: Symbols.edit,
                      ),
                    if (context.watch<AuthProvider>().hasRole('ADMIN'))
                      const ActionMenuItem(
                        value: 'edit',
                        label: 'Chỉnh sửa',
                        icon: Symbols.edit,
                      ),
                    if (context.watch<AuthProvider>().hasRole('ADMIN') ||
                        context.watch<AuthProvider>().hasRole('WAREHOUSE'))
                      const ActionMenuItem(
                        value: 'variants',
                        label: 'Quản lý biến thể',
                        icon: Symbols.inventory_2,
                      ),
                    // ActionMenuItem.divider(),
                    // const ActionMenuItem(
                    //   value: 'delete',
                    //   label: 'Xóa sản phẩm',
                    //   icon: Symbols.delete,
                    //   color: AppTheme.danger,
                    // ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      _showProductDetail(context, product);
                    } else if (value == 'content') {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            ProductContentDialog(product: product.toJson()),
                      );
                    } else if (value == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            ProductFormDialog(product: product.toJson()),
                      );
                    } else if (value == 'variants') {
                      MainScreen.of(context)
                          .navigate('/product-variants', product.toJson());
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
