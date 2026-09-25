import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/pagination_footer.dart';

import '../providers/products_provider.dart';
import '../../data/models/product_response_model.dart';
import '../dialogs/product_edit_dialog.dart';
import '../dialogs/product_create_dialog.dart';
import '../../../../main.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().loadItems();
    });
  }

  String _fmtVND(double n) {
    return '${n.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by AppLayout
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeatureHeader(
              title: 'Sản phẩm & Bộ sưu tập',
              subtitle: 'Quản lý hàng hoá, giá bán và thuộc tính',
              actionLabel: 'Thêm sản phẩm',
              actionIcon: Icons.add,
              onExportPressed: () {},
              onActionPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ProductCreateDialog(),
                );
              },
            ),
            const SizedBox(height: 32),
            FeatureToolbar(
              searchHint: 'Tìm kiếm sản phẩm theo tên...',
              onSearchChanged: (query) {
                context.read<ProductsProvider>().loadItems(
                  query: query,
                  page: 0,
                );
              },
              initialSearchText: context.read<ProductsProvider>().currentQuery,
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
    );
  }

  Widget _buildTable(BuildContext context) {
    return Consumer<ProductsProvider>(
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
                  Expanded(flex: 3, child: _headerText('SẢN PHẨM')),
                  Expanded(flex: 2, child: _headerText('DANH MỤC')),
                  Expanded(flex: 2, child: _headerText('GIÁ BÁN')),
                  Expanded(flex: 2, child: _headerText('PHONG CÁCH')),
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

  Widget _buildDataRow(BuildContext context, ProductResponseModel product) {
    final statusDisplay = product.isActive ? 'Hoạt động' : 'Đã ẩn';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
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
                  product.category?.name ?? '—',
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
                child: Text(
                  product.style.isNotEmpty ? product.style : '—',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
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
                      icon: Icons.visibility_outlined,
                    ),
                    const ActionMenuItem(
                      value: 'edit',
                      label: 'Chỉnh sửa',
                      icon: Icons.edit_outlined,
                    ),
                    // ActionMenuItem.divider(),
                    // const ActionMenuItem(
                    //   value: 'delete',
                    //   label: 'Xóa sản phẩm',
                    //   icon: Icons.delete_outline,
                    //   color: AppTheme.danger,
                    // ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      MainScreen.of(context)
                          .navigate('/product-detail', product.toJson());
                    } else if (value == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            ProductEditDialog(product: product.toJson()),
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
}
