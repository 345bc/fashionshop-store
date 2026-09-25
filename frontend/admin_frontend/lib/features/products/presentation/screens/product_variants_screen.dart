import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../main.dart';
import '../dialogs/variant_create_dialog.dart';
import '../dialogs/variant_edit_dialog.dart';

class ProductVariantsScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductVariantsScreen({super.key, required this.product});

  @override
  State<ProductVariantsScreen> createState() => _ProductVariantsScreenState();
}

class _ProductVariantsScreenState extends State<ProductVariantsScreen> {
  final List<Map<String, dynamic>> _variants = [
    {
      'id': 1,
      'sku': 'MA-COAT-01-S-BLK',
      'size_id': 1, // S
      'color_id': 1, // Black
      'price': 48500000,
      'cost_price': 28500000,
      'stock_quantity': 15,
      'reserved_quantity': 2,
      'model_3d_url': null,
      'is_active': true,
    },
    {
      'id': 2,
      'sku': 'MA-COAT-01-M-BLK',
      'size_id': 2, // M
      'color_id': 1, // Black
      'price': 48500000,
      'cost_price': 28500000,
      'stock_quantity': 0,
      'reserved_quantity': 0,
      'model_3d_url': 'https://example.com/model.glb',
      'is_active': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.product == null) {
      return const Center(child: Text('Không tìm thấy thông tin Sản phẩm'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildToolbar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              MainScreen.of(context).navigate('/products');
            },
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý Biến thể: ${widget.product!['name']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã SP: ${widget.product!['id']}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => VariantCreateDialog(
                  productId: widget.product!['id'].toString(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm biến thể'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.text,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(children: [_buildTableHeader(), _buildTableRows()]),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'SKU / INFO',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'GIÁ BÁN / VỐN',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TỒN KHO',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TRẠNG THÁI',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 48), // For Actions
        ],
      ),
    );
  }

  Widget _buildTableRows() {
    if (_variants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Text(
            'Chưa có biến thể nào',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _variants.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppTheme.borderLight),
      itemBuilder: (context, index) {
        final variant = _variants[index];
        final isActive = variant['is_active'] == true;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant['sku'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size ID: ${variant['size_id']} • Color ID: ${variant['color_id']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (variant['model_3d_url'] != null)
                      const Text(
                        'Có Model 3D',
                        style: TextStyle(color: AppTheme.primary, fontSize: 12),
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
                      '${variant['price']} ₫',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vốn: ${variant['cost_price']} ₫',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
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
                    Text(
                      '${variant['stock_quantity']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: variant['stock_quantity'] > 0
                            ? AppTheme.text
                            : AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đã đặt: ${variant['reserved_quantity']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.success.withAlpha(25)
                        : AppTheme.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Đang bán' : 'Ngừng bán',
                    style: TextStyle(
                      color: isActive ? AppTheme.success : AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(const Duration(seconds: 0), () async {
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (_) => VariantEditDialog(variant: variant),
                          );
                        });
                      },
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.danger,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Xóa biến thể',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
