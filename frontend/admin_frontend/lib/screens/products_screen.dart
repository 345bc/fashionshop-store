import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/detail_drawer.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 248},
    {'id': 'fw', 'label': 'BST Thu Đông', 'count': 84},
    {'id': 'rtw', 'label': 'Ready-to-Wear', 'count': 96},
    {'id': 'bespoke', 'label': 'Bespoke & Atelier', 'count': 42},
    {'id': 'accessories', 'label': 'Phụ kiện', 'count': 26},
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'id': 'MA-COAT-01',
      'name': 'Cashmere Double-Breasted Coat',
      'desc': '100% Cashmere Loro Piana',
      'image': 'https://images.unsplash.com/photo-1539533113208-f6df8cc8b543?w=80&q=80',
      'category': 'BST Thu Đông / Nữ',
      'costPrice': 28500000,
      'sellingPrice': 48500000,
      'stock': 12,
      'status': 'active',
      'variants': [
        {'sku': 'MA-COAT-01-S-BLK', 'size': 'S', 'color': 'Đen', 'stock': 3},
        {'sku': 'MA-COAT-01-M-BLK', 'size': 'M', 'color': 'Đen', 'stock': 5},
        {'sku': 'MA-COAT-01-L-BLK', 'size': 'L', 'color': 'Đen', 'stock': 2},
        {'sku': 'MA-COAT-01-S-CAM', 'size': 'S', 'color': 'Camel', 'stock': 1},
        {'sku': 'MA-COAT-01-M-CAM', 'size': 'M', 'color': 'Camel', 'stock': 1},
      ]
    },
    {
      'id': 'LEA-BAG-09',
      'name': 'Smooth Calfskin Shoulder Bag',
      'desc': 'Da bê Pháp với khóa vàng 24k',
      'image': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=80&q=80',
      'category': 'Phụ kiện da cao cấp',
      'costPrice': 19000000,
      'sellingPrice': 32000000,
      'stock': 4,
      'status': 'low',
      'variants': [
        {'sku': 'LEA-BAG-09-BLK', 'size': 'One Size', 'color': 'Đen', 'stock': 1},
        {'sku': 'LEA-BAG-09-BRN', 'size': 'One Size', 'color': 'Nâu Cognac', 'stock': 3},
      ]
    },
    {
      'id': 'FTW-DRB-42',
      'name': 'Sculpted Derby Shoes',
      'desc': 'Đế Goodyear Welted',
      'image': 'https://images.unsplash.com/photo-1614252339460-54f38eb4fb95?w=80&q=80',
      'category': 'Giày nam Florence',
      'costPrice': 15000000,
      'sellingPrice': 24500000,
      'stock': 18,
      'status': 'active',
      'variants': [
        {'sku': 'FTW-DRB-42-40', 'size': '40', 'color': 'Nâu đậm', 'stock': 5},
        {'sku': 'FTW-DRB-42-41', 'size': '41', 'color': 'Nâu đậm', 'stock': 6},
        {'sku': 'FTW-DRB-42-42', 'size': '42', 'color': 'Nâu đậm', 'stock': 7},
      ]
    },
    {
      'id': 'RTW-DRS-07',
      'name': 'Silk Wrap Midi Dress',
      'desc': 'Lụa tơ tằm 100% Hà Đông',
      'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=80&q=80',
      'category': 'Ready-to-Wear / Nữ',
      'costPrice': 5500000,
      'sellingPrice': 11200000,
      'stock': 0,
      'status': 'out',
      'variants': [
        {'sku': 'RTW-DRS-07-S-RED', 'size': 'S', 'color': 'Đỏ', 'stock': 0},
        {'sku': 'RTW-DRS-07-M-RED', 'size': 'M', 'color': 'Đỏ', 'stock': 0},
      ]
    },
  ];

  final Map<String, Map<String, dynamic>> _statusMap = {
    'active': {'label': 'Đang bán', 'color': AppTheme.success},
    'low': {'label': 'Tồn ít', 'color': AppTheme.warning},
    'out': {'label': 'Hết hàng', 'color': AppTheme.danger},
    'draft': {'label': 'Nháp', 'color': AppTheme.textSecondary},
  };

  String _fmtVND(int n) {
    return '${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  String _margin(int cost, int sell) {
    return '${(((sell - cost) / sell) * 100).toStringAsFixed(1)}%';
  }

  void _openProductDrawer(Map<String, dynamic> product) {
    MainScreen.of(context).openDrawer(
      DetailDrawer(
        title: 'Chi tiết Sản phẩm\n${product['id']} — ${product['name']}',
        onClose: () => MainScreen.of(context).closeDrawer(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Danh mục', product['category']),
            _buildInfoRow('Giá bán', _fmtVND(product['sellingPrice']), valueStyle: const TextStyle(fontWeight: FontWeight.bold)),
            _buildInfoRow('Giá nhập', _fmtVND(product['costPrice'])),
            _buildInfoRow('Biên lợi nhuận', _margin(product['costPrice'], product['sellingPrice']), valueStyle: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Biến thể (${(product['variants'] as List).length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Thêm biến thể'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVariantsTable(product['variants']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildVariantsTable(List variants) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 40,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 12),
        dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.text),
        dividerThickness: 1,
        columns: const [
          DataColumn(label: Text('SKU Biến thể')),
          DataColumn(label: Text('Size')),
          DataColumn(label: Text('Màu sắc')),
          DataColumn(label: Text('Tồn kho')),
        ],
        rows: variants.map((variant) {
          final stock = variant['stock'] as int;
          return DataRow(
            cells: [
              DataCell(Text(variant['sku'], style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(variant['size'])),
              DataCell(Text(variant['color'])),
              DataCell(Text(stock.toString(), style: TextStyle(fontWeight: FontWeight.w600, color: stock == 0 ? AppTheme.danger : AppTheme.text))),
            ],
          );
        }).toList(),
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
                  Text('Sản phẩm & Bộ sưu tập', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý hàng hoá, giá nhập, giá bán và biên lợi nhuận.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất danh sách'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm sản phẩm'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Filters
          Row(
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
                      color: isActive ? AppTheme.primary : AppTheme.surface,
                      border: Border.all(color: isActive ? AppTheme.primary : AppTheme.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          f['label'],
                          style: TextStyle(
                            fontSize: 14,
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
          const SizedBox(height: 24),

          // Table
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                dataTextStyle: const TextStyle(color: AppTheme.text, fontSize: 14),
                dividerThickness: 1,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 70,
                columns: const [
                  DataColumn(label: Text('Sản phẩm & SKU')),
                  DataColumn(label: Text('Danh mục')),
                  DataColumn(label: Text('Giá bán'), numeric: true),
                  DataColumn(label: Text('Biên LN'), numeric: true),
                  DataColumn(label: Text('Tồn kho'), numeric: true),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text(''), numeric: true),
                ],
                rows: _products.map((product) {
                  final status = _statusMap[product['status']]!;
                  return DataRow(
                    cells: [
                      DataCell(Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(product['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(product['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${product['id']} • ${product['desc']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      )),
                      DataCell(Text(product['category'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(_fmtVND(product['sellingPrice']), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                        _margin(product['costPrice'], product['sellingPrice']),
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                      )),
                      DataCell(Text(
                        product['stock'] == 0 ? '—' : product['stock'].toString(),
                        style: TextStyle(fontWeight: FontWeight.w500, color: (product['stock'] as int) <= 5 ? AppTheme.warning : AppTheme.text),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (status['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status['label'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status['color'] as Color),
                          ),
                        ),
                      ),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.grid_view, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () => _openProductDrawer(product),
                            tooltip: 'Quản lý biến thể',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () {},
                            tooltip: 'Sửa',
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
