import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Overview',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Track business activity, atelier and orders today.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Data'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Order'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // KPI Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Monthly Revenue',
                  badgeText: '+8.5%',
                  badgeColor: AppTheme.success,
                  value: '145.000.000 ₫',
                  footerText: 'Updated at 10:30 AM',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: 'Orders',
                  badgeText: 'This month',
                  badgeColor: AppTheme.border,
                  value: '38 orders',
                  footerText: '6 orders in production',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: 'Inventory',
                  badgeText: 'In stock',
                  badgeColor: AppTheme.border,
                  value: '85 items',
                  footerText: '4 products running low',
                  footerColor: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: 'New Customers',
                  badgeText: 'VIP Haute',
                  badgeColor: AppTheme.border,
                  value: '45 clients',
                  footerText: '12 private bookings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Layout Bottom
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Recent Orders & Tailoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Latest orders requiring measurements and completion', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View all orders →'),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecentOrdersTable(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Quick Actions
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildQuickAction('Add New Product'),
                        const SizedBox(height: 12),
                        _buildQuickAction('Register Customer'),
                        const SizedBox(height: 12),
                        _buildQuickAction('Update Stock'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String value,
    required String footerText,
    Color footerColor = AppTheme.textSecondary,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor == AppTheme.border ? AppTheme.borderLight : badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor == AppTheme.border ? AppTheme.textSecondary : badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(footerText, style: TextStyle(fontSize: 13, color: footerColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersTable() {
    final recentOrders = [
      {'id': '#ORD-1042', 'customer': 'Nguyễn Lan Phương', 'product': 'Áo khoác dạ nữ dáng dài', 'total': '3.100.000 ₫', 'status': 'Delivered', 'statusColor': AppTheme.success},
      {'id': '#ORD-1041', 'customer': 'Trần Hải Đăng', 'product': 'Bộ suit nam may đo cao cấp', 'total': '2.500.000 ₫', 'status': 'Processing', 'statusColor': AppTheme.warning},
      {'id': '#ORD-1040', 'customer': 'Hoàng Mai Ly', 'product': 'Đầm lụa tơ tằm cổ yếm', 'total': '1.200.000 ₫', 'status': 'Pending', 'statusColor': AppTheme.info},
      {'id': '#ORD-1039', 'customer': 'Lê Gia Bảo', 'product': 'Quần tây xếp ly Biella Wool', 'total': '850.000 ₫', 'status': 'Delivered', 'statusColor': AppTheme.success},
    ];

    return DataTable(
      headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
      dataTextStyle: const TextStyle(color: AppTheme.text, fontSize: 14),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: Text('Order ID')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Status')),
      ],
      rows: recentOrders.map((order) {
        return DataRow(
          cells: [
            DataCell(Text(order['id'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(order['customer'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(order['product'] as String, style: const TextStyle(color: AppTheme.textSecondary))),
            DataCell(Text(order['total'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (order['statusColor'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order['status'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: order['statusColor'] as Color,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuickAction(String title) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onPressed: () {},
        child: Text(title),
      ),
    );
  }
}
