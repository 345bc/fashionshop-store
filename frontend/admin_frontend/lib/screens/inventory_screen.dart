import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeFilter = 'all';
  String _activeSection = 'stock'; // 'stock' or 'bestsellers'

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 85},
    {'id': 'ok', 'label': 'Đang có', 'count': 68},
    {'id': 'low', 'label': 'Tồn ít', 'count': 12},
    {'id': 'out', 'label': 'Hết hàng', 'count': 5},
  ];

  final List<Map<String, dynamic>> _items = [
    {'sku': 'MA-COAT-01', 'name': 'Cashmere Double-Breasted Coat', 'category': 'Áo khoác', 'warehouse': 'HN-01', 'qty': 12, 'reserved': 2, 'reorderPoint': 5, 'stockStatus': 'ok', 'updatedAt': '14 Sep'},
    {'sku': 'LEA-BAG-09', 'name': 'Smooth Calfskin Shoulder Bag', 'category': 'Phụ kiện', 'warehouse': 'HCM-02', 'qty': 4, 'reserved': 1, 'reorderPoint': 6, 'stockStatus': 'low', 'updatedAt': '13 Sep'},
    {'sku': 'FTW-DRB-42', 'name': 'Sculpted Derby Shoes', 'category': 'Giày', 'warehouse': 'HN-01', 'qty': 18, 'reserved': 3, 'reorderPoint': 5, 'stockStatus': 'ok', 'updatedAt': '12 Sep'},
    {'sku': 'RTW-DRS-07', 'name': 'Silk Wrap Midi Dress', 'category': 'RTW', 'warehouse': 'HCM-02', 'qty': 0, 'reserved': 0, 'reorderPoint': 4, 'stockStatus': 'out', 'updatedAt': '10 Sep'},
    {'sku': 'ACC-SCF-15', 'name': 'Cashmere Houndstooth Scarf', 'category': 'Phụ kiện', 'warehouse': 'HN-01', 'qty': 3, 'reserved': 0, 'reorderPoint': 5, 'stockStatus': 'low', 'updatedAt': '09 Sep'},
    {'sku': 'RTW-JKT-22', 'name': 'Wool-Blend Structured Jacket', 'category': 'RTW', 'warehouse': 'HN-01', 'qty': 21, 'reserved': 4, 'reorderPoint': 5, 'stockStatus': 'ok', 'updatedAt': '08 Sep'},
  ];

  final List<Map<String, dynamic>> _bestsellers = [
    {'rank': 1, 'sku': 'MA-COAT-01', 'name': 'Cashmere Double-Breasted Coat', 'category': 'Áo khoác', 'sold30d': 9, 'revenue30d': '436.500.000 ₫', 'velocity': 'Nhanh'},
    {'rank': 2, 'sku': 'RTW-JKT-22', 'name': 'Wool-Blend Structured Jacket', 'category': 'RTW', 'sold30d': 7, 'revenue30d': '209.300.000 ₫', 'velocity': 'Nhanh'},
    {'rank': 3, 'sku': 'LEA-BAG-09', 'name': 'Smooth Calfskin Shoulder Bag', 'category': 'Phụ kiện', 'sold30d': 6, 'revenue30d': '192.000.000 ₫', 'velocity': 'TB'},
    {'rank': 4, 'sku': 'FTW-DRB-42', 'name': 'Sculpted Derby Shoes', 'category': 'Giày', 'sold30d': 5, 'revenue30d': '122.500.000 ₫', 'velocity': 'TB'},
    {'rank': 5, 'sku': 'ACC-SCF-15', 'name': 'Cashmere Houndstooth Scarf', 'category': 'Phụ kiện', 'sold30d': 4, 'revenue30d': '48.000.000 ₫', 'velocity': 'Chậm'},
  ];

  final Map<String, Map<String, dynamic>> _stockBadge = {
    'ok': {'label': 'Đang có', 'color': AppTheme.success},
    'low': {'label': 'Tồn ít', 'color': AppTheme.warning},
    'out': {'label': 'Hết hàng', 'color': AppTheme.danger},
  };

  final Map<String, Color> _velocityColor = {
    'Nhanh': AppTheme.success,
    'TB': AppTheme.warning,
    'Chậm': AppTheme.danger,
  };

  Widget _buildSubTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _buildSubTabBtn('stock', '📦 Tồn kho theo SKU'),
          _buildSubTabBtn('bestsellers', '📈 Hàng bán chạy (30 ngày)'),
        ],
      ),
    );
  }

  Widget _buildSubTabBtn(String id, String label) {
    final isActive = _activeSection == id;
    return InkWell(
      onTap: () => setState(() => _activeSection = id),
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
    final visibleItems = _activeFilter == 'all'
        ? _items
        : _items.where((i) => i['stockStatus'] == _activeFilter).toList();

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
                  Text('Tồn kho & Kho hàng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Theo dõi mức tồn kho và sản phẩm bán chạy nhất.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Nhập kho'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Alert
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3), // warning-bg equivalent
              border: Border.all(color: const Color(0xFFFCD34D)), // warning border
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF92400E)),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                    children: [
                      TextSpan(text: '4 sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' đang tồn kho thấp — cần đặt hàng bổ sung.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubTabBar(),
                
                if (_activeSection == 'stock') ...[
                  // Filters for stock
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: _filters.map((f) {
                        final isActive = _activeFilter == f['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _activeFilter = f['id']),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    f['label'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      color: isActive ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${f['count']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive ? Colors.white70 : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  
                  // Stock Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                      dataTextStyle: const TextStyle(color: AppTheme.text, fontSize: 14),
                      dividerThickness: 1,
                      columns: const [
                        DataColumn(label: Text('SKU')),
                        DataColumn(label: Text('Tên sản phẩm')),
                        DataColumn(label: Text('Danh mục')),
                        DataColumn(label: Text('Kho')),
                        DataColumn(label: Text('Có sẵn'), numeric: true),
                        DataColumn(label: Text('Đặt giữ'), numeric: true),
                        DataColumn(label: Text('Thực tế'), numeric: true),
                        DataColumn(label: Text('Mức tái đặt'), numeric: true),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Cập nhật')),
                      ],
                      rows: visibleItems.map((item) {
                        final avail = item['qty'] - item['reserved'];
                        final badge = _stockBadge[item['stockStatus']]!;
                        final badgeColor = badge['color'] as Color;
                        
                        return DataRow(
                          cells: [
                            DataCell(Text(item['sku'], style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(item['category'], style: const TextStyle(color: AppTheme.textSecondary))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item['warehouse'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              ),
                            ),
                            DataCell(Text(
                              avail.toString(), 
                              style: TextStyle(
                                fontWeight: FontWeight.w600, 
                                color: avail <= 0 ? AppTheme.danger : (avail < item['reorderPoint'] ? AppTheme.warning : AppTheme.text),
                              ),
                            )),
                            DataCell(Text(item['reserved'].toString(), style: const TextStyle(color: AppTheme.textSecondary))),
                            DataCell(Text(item['qty'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(item['reorderPoint'].toString(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge['label'] as String,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                                ),
                              ),
                            ),
                            DataCell(Text(item['updatedAt'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ]
                else if (_activeSection == 'bestsellers') ...[
                  // Bestsellers Table
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
                        DataColumn(label: Text('Đã bán (30 ngày)'), numeric: true),
                        DataColumn(label: Text('Doanh thu (30 ngày)'), numeric: true),
                        DataColumn(label: Text('Tốc độ bán'), numeric: true),
                      ],
                      rows: _bestsellers.map((p) {
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
                            DataCell(Text(p['sold30d'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(p['revenue30d'], style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(
                              p['velocity'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _velocityColor[p['velocity']]),
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
