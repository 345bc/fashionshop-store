import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ReportsTable extends StatelessWidget {
  final String activeTab;

  const ReportsTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeTab == 'revenue') _buildRevenueTable(),
        if (activeTab == 'products') _buildProductsTable(),
      ],
    );
  }

  Widget _buildRevenueTable() {
    final List<Map<String, dynamic>> revenueByTime = [
      {'period': 'Tháng 4', 'revenue': '98.000.000 ₫', 'orders': 24, 'growth': '+5.2%'},
      {'period': 'Tháng 5', 'revenue': '112.000.000 ₫', 'orders': 29, 'growth': '+14.3%'},
      {'period': 'Tháng 6', 'revenue': '88.000.000 ₫', 'orders': 21, 'growth': '-21.4%'},
      {'period': 'Tháng 7', 'revenue': '125.500.000 ₫', 'orders': 32, 'growth': '+42.6%'},
      {'period': 'Tháng 8', 'revenue': '133.200.000 ₫', 'orders': 35, 'growth': '+6.1%'},
      {'period': 'Tháng 9', 'revenue': '145.000.000 ₫', 'orders': 38, 'growth': '+8.9%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Thời gian', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Doanh thu', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Đơn hàng', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Tăng trưởng', style: _headerStyle())),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: revenueByTime.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
          itemBuilder: (context, index) {
            final row = revenueByTime[index];
            final isPositive = row['growth'].startsWith('+');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(row['period'], style: const TextStyle(fontWeight: FontWeight.w500))),
                  Expanded(flex: 2, child: Text(row['revenue'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('${row['orders']}')),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['growth'],
                      style: TextStyle(
                        color: isPositive ? AppTheme.success : AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    final List<Map<String, dynamic>> revenueByProduct = [
      {'rank': 1, 'sku': 'MA-COAT-01', 'name': 'Cashmere Double-Breasted Coat', 'category': 'Áo khoác', 'unitsSold': 9, 'revenue': '436.500.000 ₫', 'share': '32%'},
      {'rank': 2, 'sku': 'RTW-JKT-22', 'name': 'Wool-Blend Structured Jacket', 'category': 'RTW', 'unitsSold': 7, 'revenue': '209.300.000 ₫', 'share': '21%'},
      {'rank': 3, 'sku': 'LEA-BAG-09', 'name': 'Smooth Calfskin Shoulder Bag', 'category': 'Phụ kiện', 'unitsSold': 6, 'revenue': '192.000.000 ₫', 'share': '19%'},
      {'rank': 4, 'sku': 'FTW-DRB-42', 'name': 'Sculpted Derby Shoes', 'category': 'Giày', 'unitsSold': 5, 'revenue': '122.500.000 ₫', 'share': '12%'},
      {'rank': 5, 'sku': 'ACC-SCF-15', 'name': 'Cashmere Houndstooth Scarf', 'category': 'Phụ kiện', 'unitsSold': 4, 'revenue': '48.000.000 ₫', 'share': '6%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
          child: Row(
            children: [
              const SizedBox(width: 48, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
              Expanded(flex: 3, child: Text('Sản phẩm', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Phân loại', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Đã bán', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Doanh thu', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Tỷ trọng', style: _headerStyle())),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: revenueByProduct.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
          itemBuilder: (context, index) {
            final product = revenueByProduct[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${product['rank']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(product['sku'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(product['category'])),
                  Expanded(flex: 2, child: Text('${product['unitsSold']}')),
                  Expanded(flex: 2, child: Text(product['revenue'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text(product['share'])),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    );
  }
}
