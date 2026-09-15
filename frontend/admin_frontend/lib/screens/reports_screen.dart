import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'month';
  String _subTab = 'revenue'; // 'revenue' | 'products'

  final List<Map<String, dynamic>> _periods = [
    {'id': 'week', 'label': 'Tuần này'},
    {'id': 'month', 'label': 'Tháng này'},
    {'id': 'quarter', 'label': 'Quý này'},
    {'id': 'year', 'label': 'Năm nay'},
  ];

  final List<Map<String, dynamic>> _kpis = [
    {'label': 'Tổng doanh thu', 'value': '145.000.000 ₫', 'change': '+8.5%', 'trend': 'up', 'icon': Icons.trending_up},
    {'label': 'Đơn hoàn thành', 'value': '38', 'change': '+12%', 'trend': 'up', 'icon': Icons.shopping_bag_outlined},
    {'label': 'Khách mới', 'value': '5', 'change': '-2', 'trend': 'down', 'icon': Icons.group_outlined},
    {'label': 'Giá trị ĐH bình quân', 'value': '3.815.000 ₫', 'change': '+3.2%', 'trend': 'up', 'icon': Icons.inventory_2_outlined},
  ];

  final List<Map<String, dynamic>> _revenueByTime = [
    {'period': 'Tháng 4', 'revenue': '98.000.000 ₫', 'orders': 24, 'growth': '+5.2%'},
    {'period': 'Tháng 5', 'revenue': '112.000.000 ₫', 'orders': 29, 'growth': '+14.3%'},
    {'period': 'Tháng 6', 'revenue': '88.000.000 ₫', 'orders': 21, 'growth': '-21.4%'},
    {'period': 'Tháng 7', 'revenue': '125.500.000 ₫', 'orders': 32, 'growth': '+42.6%'},
    {'period': 'Tháng 8', 'revenue': '133.200.000 ₫', 'orders': 35, 'growth': '+6.1%'},
    {'period': 'Tháng 9', 'revenue': '145.000.000 ₫', 'orders': 38, 'growth': '+8.9%'},
  ];

  final List<Map<String, dynamic>> _revenueByProduct = [
    {'rank': 1, 'sku': 'MA-COAT-01', 'name': 'Cashmere Double-Breasted Coat', 'category': 'Áo khoác', 'unitsSold': 9, 'revenue': '436.500.000 ₫', 'share': '32%'},
    {'rank': 2, 'sku': 'RTW-JKT-22', 'name': 'Wool-Blend Structured Jacket', 'category': 'RTW', 'unitsSold': 7, 'revenue': '209.300.000 ₫', 'share': '21%'},
    {'rank': 3, 'sku': 'LEA-BAG-09', 'name': 'Smooth Calfskin Shoulder Bag', 'category': 'Phụ kiện', 'unitsSold': 6, 'revenue': '192.000.000 ₫', 'share': '19%'},
    {'rank': 4, 'sku': 'FTW-DRB-42', 'name': 'Sculpted Derby Shoes', 'category': 'Giày', 'unitsSold': 5, 'revenue': '122.500.000 ₫', 'share': '12%'},
    {'rank': 5, 'sku': 'ACC-SCF-15', 'name': 'Cashmere Houndstooth Scarf', 'category': 'Phụ kiện', 'unitsSold': 4, 'revenue': '48.000.000 ₫', 'share': '6%'},
  ];

  Widget _buildSubTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _buildSubTabBtn('revenue', '📅 Doanh thu theo thời gian'),
          _buildSubTabBtn('products', '📦 Doanh thu theo sản phẩm'),
        ],
      ),
    );
  }

  Widget _buildSubTabBtn(String id, String label) {
    final isActive = _subTab == id;
    return InkWell(
      onTap: () => setState(() => _subTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

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
                  Text('Báo cáo & Thống kê', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Phân tích doanh thu theo thời gian và theo sản phẩm.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: _periods.map((p) {
                        final isActive = _period == p['id'];
                        final isLast = _periods.last == p;
                        return InkWell(
                          onTap: () => setState(() => _period = p['id']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.primary : Colors.transparent,
                              border: isLast ? null : const Border(right: BorderSide(color: AppTheme.border)),
                            ),
                            child: Text(
                              p['label'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất báo cáo'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Grid
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2, // Adjust based on content
            children: _kpis.map((kpi) {
              final isUp = kpi['trend'] == 'up';
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(kpi['label'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(kpi['icon'], size: 15, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(kpi['value'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(
                      '${kpi['change']} so với kỳ trước',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUp ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Main Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubTabBar(),
                
                if (_subTab == 'revenue') ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Doanh thu theo tháng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Tổng hợp doanh thu và số đơn theo từng tháng trong kỳ.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                      dataTextStyle: const TextStyle(color: AppTheme.text, fontSize: 14),
                      dividerThickness: 1,
                      columns: const [
                        DataColumn(label: Text('Kỳ')),
                        DataColumn(label: Text('Doanh thu'), numeric: true),
                        DataColumn(label: Text('Số đơn'), numeric: true),
                        DataColumn(label: Text('Tăng trưởng'), numeric: true),
                      ],
                      rows: _revenueByTime.map((r) {
                        final isUp = r['growth'].startsWith('+');
                        return DataRow(
                          cells: [
                            DataCell(Text(r['period'], style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(r['revenue'], style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(r['orders'].toString())),
                            DataCell(Text(
                              r['growth'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isUp ? AppTheme.success : AppTheme.danger,
                              ),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ]
                else if (_subTab == 'products') ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top sản phẩm theo doanh thu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Xếp hạng sản phẩm đóng góp doanh thu trong kỳ được chọn.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                      dataTextStyle: const TextStyle(color: AppTheme.text, fontSize: 14),
                      dividerThickness: 1,
                      columns: const [
                        DataColumn(label: Text('#'), numeric: true),
                        DataColumn(label: Text('SKU')),
                        DataColumn(label: Text('Tên sản phẩm')),
                        DataColumn(label: Text('Danh mục')),
                        DataColumn(label: Text('Đã bán'), numeric: true),
                        DataColumn(label: Text('Doanh thu'), numeric: true),
                        DataColumn(label: Text('Tỷ trọng'), numeric: true),
                      ],
                      rows: _revenueByProduct.map((p) {
                        final isTop = p['rank'] <= 3;
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isTop ? const Color(0xFFFEF3C7) : AppTheme.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p['rank'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isTop ? const Color(0xFF92400E) : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(p['sku'], style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(p['category'], style: const TextStyle(color: AppTheme.textSecondary))),
                            DataCell(Text(p['unitsSold'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(p['revenue'], style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(
                              p['share'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
