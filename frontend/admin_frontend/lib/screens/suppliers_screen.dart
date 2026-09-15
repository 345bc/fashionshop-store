import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/detail_drawer.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 8},
    {'id': 'active', 'label': 'Đang hợp tác', 'count': 6},
    {'id': 'inactive', 'label': 'Ngừng hợp tác', 'count': 2},
  ];

  final List<Map<String, dynamic>> _suppliers = [
    {
      'id': 'SUP-001',
      'name': 'Công ty Vải Hà Nội',
      'contactPerson': 'Nguyễn Văn Hùng',
      'phone': '024 3827 1234',
      'email': 'import@vaihani.vn',
      'category': 'Vải cao cấp',
      'totalReceipts': 14,
      'totalValue': '312.000.000 ₫',
      'lastReceipt': '13 Sep 2026',
      'status': 'active',
      'purchaseHistory': [
        {'id': 'PO-2026-024', 'date': '13 Sep 2026', 'items': 5, 'total': '48.500.000 ₫', 'status': 'Đã nhận', 'statusColor': AppTheme.success},
        {'id': 'PO-2026-020', 'date': '01 Sep 2026', 'items': 2, 'total': '14.000.000 ₫', 'status': 'Đã hủy', 'statusColor': AppTheme.danger},
        {'id': 'PO-2026-015', 'date': '15 Aug 2026', 'items': 10, 'total': '98.200.000 ₫', 'status': 'Đã nhận', 'statusColor': AppTheme.success},
      ]
    },
    {
      'id': 'SUP-002',
      'name': 'Milano Fabrics Import',
      'contactPerson': 'Marco Rossi',
      'phone': '+39 02 1234 5678',
      'email': 'sales@milanofabrics.it',
      'category': 'Vải Ý nhập khẩu',
      'totalReceipts': 6,
      'totalValue': '187.500.000 ₫',
      'lastReceipt': '01 Sep 2026',
      'status': 'active',
      'purchaseHistory': [
        {'id': 'PO-2026-023', 'date': '14 Sep 2026', 'items': 3, 'total': '32.000.000 ₫', 'status': 'Chờ nhận', 'statusColor': AppTheme.warning},
        {'id': 'PO-2026-018', 'date': '01 Sep 2026', 'items': 5, 'total': '45.000.000 ₫', 'status': 'Đã nhận', 'statusColor': AppTheme.success},
      ]
    },
    {
      'id': 'SUP-003',
      'name': 'Leather House HCM',
      'contactPerson': 'Trần Thị Mai',
      'phone': '028 3894 5678',
      'email': 'orders@leatherhouse.vn',
      'category': 'Da thuộc',
      'totalReceipts': 9,
      'totalValue': '241.000.000 ₫',
      'lastReceipt': '10 Sep 2026',
      'status': 'active',
      'purchaseHistory': [
        {'id': 'PO-2026-022', 'date': '10 Sep 2026', 'items': 8, 'total': '76.200.000 ₫', 'status': 'Đã nhận', 'statusColor': AppTheme.success},
      ]
    },
    {
      'id': 'SUP-005',
      'name': 'Korea Fabric Ltd.',
      'contactPerson': 'Kim Ji-Hoon',
      'phone': '+82 2 1234 5678',
      'email': 'trade@koreafabric.kr',
      'category': 'Vải Hàn Quốc',
      'totalReceipts': 3,
      'totalValue': '95.000.000 ₫',
      'lastReceipt': '22 Jul 2026',
      'status': 'inactive',
      'purchaseHistory': []
    },
  ];

  void _openSupplierDrawer(Map<String, dynamic> supplier) {
    MainScreen.of(context).openDrawer(
      DetailDrawer(
        title: 'Hồ sơ Nhà cung cấp\n${supplier['id']}',
        onClose: () => MainScreen.of(context).closeDrawer(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Tên Công ty', supplier['name'], valueStyle: const TextStyle(fontWeight: FontWeight.bold)),
            _buildInfoRow('Người liên hệ', supplier['contactPerson']),
            _buildInfoRow('Danh mục cung cấp', supplier['category']),
            _buildInfoRow('Số điện thoại', supplier['phone']),
            _buildInfoRow('Email', supplier['email']),
            
            const SizedBox(height: 32),
            const Text('Lịch sử nhập hàng từ NCC này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPurchaseHistoryTable(supplier['purchaseHistory']),
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
          Flexible(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistoryTable(List history) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Chưa có lịch sử nhập hàng', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 45,
        dataRowMaxHeight: 45,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 12),
        dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.text),
        dividerThickness: 1,
        columns: const [
          DataColumn(label: Text('Mã Phiếu')),
          DataColumn(label: Text('Ngày lập')),
          DataColumn(label: Text('Mặt hàng')),
          DataColumn(label: Text('Tổng tiền')),
          DataColumn(label: Text('Trạng thái')),
        ],
        rows: history.map((po) {
          return DataRow(
            cells: [
              DataCell(Text(po['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(po['date'], style: const TextStyle(color: AppTheme.textSecondary))),
              DataCell(Text(po['items'].toString())),
              DataCell(Text(po['total'], style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(po['status'], style: TextStyle(fontWeight: FontWeight.w600, color: po['statusColor']))),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuppliers = _activeFilter == 'all'
        ? _suppliers
        : _suppliers.where((s) => s['status'] == _activeFilter).toList();

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
                  Text('Nhà cung cấp', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý danh sách nhà cung cấp và lịch sử hợp tác.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm NCC'),
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
                columns: const [
                  DataColumn(label: Text('Mã NCC')),
                  DataColumn(label: Text('Tên nhà cung cấp')),
                  DataColumn(label: Text('Người liên hệ')),
                  DataColumn(label: Text('Danh mục')),
                  DataColumn(label: Text('Phiếu nhập'), numeric: true),
                  DataColumn(label: Text('Tổng giá trị'), numeric: true),
                  DataColumn(label: Text('Lần nhập cuối')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('')),
                ],
                rows: visibleSuppliers.map((supplier) {
                  final isActive = supplier['status'] == 'active';
                  return DataRow(
                    cells: [
                      DataCell(Text(supplier['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(supplier['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(supplier['contactPerson'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(supplier['phone'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      )),
                      DataCell(Text(supplier['category'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(supplier['totalReceipts'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(supplier['totalValue'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(supplier['lastReceipt'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ? AppTheme.success : AppTheme.textSecondary).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Đang hợp tác' : 'Ngừng',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? AppTheme.success : AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () => _openSupplierDrawer(supplier),
                            tooltip: 'Hồ sơ & Lịch sử',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () {},
                            tooltip: 'Sửa thông tin',
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
