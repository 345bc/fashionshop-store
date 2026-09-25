import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../main.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? product;

  const ProductDetailScreen({super.key, required this.product});

  String _fmtVND(double n) {
    return '${n.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Center(child: Text('Không tìm thấy thông tin Sản phẩm'));
    }

    final double price = (product!['basePrice'] is num) ? (product!['basePrice'] as num).toDouble() : 0.0;
    final catData = product!['category'] ?? product!['categoryId'];
    final categoryName = (catData is Map) ? catData['name'] : '—';
    final supplierData = product!['supplier'] ?? product!['supplierId'];
    final supplierName = (supplierData is Map) ? supplierData['name'] : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInfoCard(categoryName, supplierName, price),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildActionCard(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'Chi tiết Sản phẩm: ${product!['name']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã SP: ${product!['id']} • Slug: ${product!['slug']}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (product!['isActive'] == true)
                  ? AppTheme.success.withAlpha(25)
                  : AppTheme.danger.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (product!['isActive'] == true) ? 'Đang hoạt động' : 'Đã ẩn',
              style: TextStyle(
                color: (product!['isActive'] == true)
                    ? AppTheme.success
                    : AppTheme.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String categoryName, String supplierName, double price) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Tên sản phẩm', product!['name']),
          const Divider(height: 32),
          _buildInfoRow('Mô tả', product!['description']?.isEmpty ?? true ? '—' : product!['description']),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Danh mục', categoryName)),
              Expanded(child: _buildInfoRow('Nhà cung cấp', supplierName)),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Phong cách', product!['style']?.isEmpty ?? true ? '—' : product!['style'])),
              Expanded(child: _buildInfoRow('Dịp', product!['occasion']?.isEmpty ?? true ? '—' : product!['occasion'])),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow('Giá bán cơ bản', _fmtVND(price), valueColor: AppTheme.primary, isBold: true),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Biến thể & Tồn kho',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quản lý các tuỳ chọn màu sắc, kích thước và theo dõi số lượng tồn kho của sản phẩm này.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              MainScreen.of(context).navigate('/product-variants', product);
            },
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Quản lý biến thể'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.text,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
