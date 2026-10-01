import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/status_badge.dart';
import '../dialogs/variant_create_dialog.dart';
import '../dialogs/variant_edit_dialog.dart';
import '../dialogs/variant_detail_dialog.dart';
import '../providers/product_variants_provider.dart';

class ProductVariantsScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductVariantsScreen({super.key, required this.product});

  @override
  State<ProductVariantsScreen> createState() => _ProductVariantsScreenState();
}

class _ProductVariantsScreenState extends State<ProductVariantsScreen> {
  int? get _productId => (widget.product?['id'] as num?)?.toInt();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productId != null) {
        context.read<ProductVariantsProvider>().loadItems(
          productId: _productId!,
        );
      }
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
    return '$digits ₫';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Về sản phẩm',
                onPressed: () => MainScreen.of(context).navigate('/products'),
                icon: const Icon(Icons.arrow_back),
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
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => VariantCreateDialog(productId: id),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm biến thể'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FeatureToolbar(
            searchHint: 'Tìm biến thể theo SKU...',
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _row(id, provider.items[index]),
                      ),
                    const Divider(height: 1),
                    PaginationFooter(
                      currentPage: provider.currentPage,
                      totalPages: provider.totalElements == 0
                          ? 1
                          : (provider.totalElements / provider.pageSize).ceil(),
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

  Widget _row(int productId, Map<String, dynamic> variant) {
    final isActive = variant['isActive'] == true;
    final stock = (variant['stockQuantity'] as num?)?.toInt() ?? 0;
    final reserved = (variant['reservedQuantity'] as num?)?.toInt() ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: AppTheme.surface,
        onTap: () => showDialog(
          context: context,
          builder: (_) =>
              VariantDetailDialog(variantId: (variant['id'] as num).toInt()),
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
                      variant['sku']?.toString() ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${variant['sizeName'] ?? '—'} · ${variant['colorName'] ?? '—'}',
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
                        (isActive ? AppTheme.success : AppTheme.danger)
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
                        builder: (_) => VariantDetailDialog(
                          variantId: (variant['id'] as num).toInt(),
                        ),
                      );
                    } else if (value == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) => VariantEditDialog(
                          productId: productId,
                          variant: variant,
                        ),
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
