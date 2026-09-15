import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/detail_drawer.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 24},
    {'id': 'pending', 'label': 'Chờ nhận', 'count': 4},
    {'id': 'received', 'label': 'Đã nhận', 'count': 18},
    {'id': 'cancelled', 'label': 'Đã hủy', 'count': 2},
  ];

  final List<Map<String, dynamic>> _receipts = [
    {
      'id': 'PO-2026-024',
      'supplier': 'Công ty Vải Hà Nội',
      'items': 5,
      'totalCost': '48.500.000 ₫',
      'status': 'received',
      'receivedAt': '13 Sep 2026',
      'note': 'Lô cashmere FW26',
      'receiptItems': [
        {'sku': 'RAW-CASH-BLK', 'name': 'Vải Cashmere Đen', 'unit': 'Mét', 'qty': 50, 'price': '600.000 ₫'},
        {'sku': 'RAW-CASH-CAM', 'name': 'Vải Cashmere Camel', 'unit': 'Mét', 'qty': 30, 'price': '616.666 ₫'}
      ]
    },
    {
      'id': 'PO-2026-023',
      'supplier': 'Milano Fabrics Import',
      'items': 3,
      'totalCost': '32.000.000 ₫',
      'status': 'pending',
      'receivedAt': '—',
      'note': 'Vải len Biella cao cấp',
      'receiptItems': [
        {'sku': 'RAW-WOOL-NVY', 'name': 'Len Biella Navy', 'unit': 'Mét', 'qty': 80, 'price': '400.000 ₫'}
      ]
    },
    {
      'id': 'PO-2026-022',
      'supplier': 'Leather House HCM',
      'items': 8,
      'totalCost': '76.200.000 ₫',
      'status': 'received',
      'receivedAt': '10 Sep 2026',
      'note': 'Da bê thuộc Pháp',
      'receiptItems': [
        {'sku': 'RAW-CALF-BRN', 'name': 'Da bê nguyên tấm Nâu', 'unit': 'Pia', 'qty': 120, 'price': '635.000 ₫'}
      ]
    },
  ];

  final Map<String, Map<String, dynamic>> _statusMap = {
    'received': {'label': 'Đã nhận', 'color': AppTheme.success},
    'pending': {'label': 'Chờ nhận', 'color': AppTheme.warning},
    'cancelled': {'label': 'Đã hủy', 'color': AppTheme.danger},
  };

  void _openReceiptDrawer(Map<String, dynamic> receipt) {
    final statusInfo = _statusMap[receipt['status']]!;
    
    MainScreen.of(context).openDrawer(
      DetailDrawer(
        title: 'Chi tiết Phiếu nhập\n${receipt['id']}',
        onClose: () => MainScreen.of(context).closeDrawer(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Nhà cung cấp', receipt['supplier']),
            _buildInfoRow('Trạng thái', statusInfo['label'], valueStyle: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold)),
            _buildInfoRow('Ngày nhận hàng', receipt['receivedAt']),
            _buildInfoRow('Ghi chú', receipt['note']),
            
            const SizedBox(height: 32),
            const Text('Danh sách mặt hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildReceiptItemsTable(receipt['receiptItems'], receipt['totalCost']),
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

  Widget _buildReceiptItemsTable(List items, String total) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 50,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 12),
            dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.text),
            dividerThickness: 1,
            columns: const [
              DataColumn(label: Text('Vật tư / Nguyên liệu')),
              DataColumn(label: Text('Đơn vị')),
              DataColumn(label: Text('SL Nhập')),
              DataColumn(label: Text('Đơn giá')),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(item['sku'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  )),
                  DataCell(Text(item['unit'], style: const TextStyle(color: AppTheme.textSecondary))),
                  DataCell(Text(item['qty'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(item['price'], style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              );
            }).toList(),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Tổng giá trị:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text(total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleReceipts = _activeFilter == 'all'
        ? _receipts
        : _receipts.where((r) => r['status'] == _activeFilter).toList();

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
                  Text('Nhập hàng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý phiếu nhập và lịch sử nhập hàng từ nhà cung cấp.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất Excel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tạo phiếu nhập'),
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
                  DataColumn(label: Text('Mã phiếu')),
                  DataColumn(label: Text('Nhà cung cấp')),
                  DataColumn(label: Text('Ghi chú')),
                  DataColumn(label: Text('Số mặt hàng'), numeric: true),
                  DataColumn(label: Text('Tổng tiền nhập'), numeric: true),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Ngày nhận')),
                  DataColumn(label: Text('')),
                ],
                rows: visibleReceipts.map((receipt) {
                  final statusInfo = _statusMap[receipt['status']]!;
                  return DataRow(
                    cells: [
                      DataCell(Text(receipt['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(receipt['supplier'], style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(receipt['note'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                      DataCell(Text(receipt['items'].toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(receipt['totalCost'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (statusInfo['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusInfo['label'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusInfo['color'] as Color),
                          ),
                        ),
                      ),
                      DataCell(Text(receipt['receivedAt'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        color: AppTheme.textSecondary,
                        onPressed: () => _openReceiptDrawer(receipt),
                        tooltip: 'Xem chi tiết',
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
