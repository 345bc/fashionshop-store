import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/detail_drawer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả khách hàng', 'count': 45},
    {'id': 'vip', 'label': 'VIP / Khách sỉ', 'count': 12},
    {'id': 'regular', 'label': 'Khách thường', 'count': 28},
    {'id': 'new', 'label': 'Khách mới (30d)', 'count': 5},
  ];

  final List<Map<String, dynamic>> _customers = [
    {
      'id': 'CLT-001',
      'name': 'Nguyễn Lan Phương',
      'email': 'lanphuong@email.com',
      'phone': '0912 345 678',
      'tier': 'vip',
      'totalOrders': 14,
      'totalSpend': '42.500.000 ₫',
      'lastOrder': '14 Sep 2026',
      'orderHistory': [
        {'id': 'ORD-1042', 'date': '14 Sep 2026', 'total': '3.100.000 ₫', 'status': 'Đã giao', 'statusColor': AppTheme.success},
        {'id': 'ORD-1011', 'date': '01 Aug 2026', 'total': '12.500.000 ₫', 'status': 'Đã giao', 'statusColor': AppTheme.success},
        {'id': 'ORD-0955', 'date': '15 Jul 2026', 'total': '8.200.000 ₫', 'status': 'Đã giao', 'statusColor': AppTheme.success},
      ]
    },
    {
      'id': 'CLT-002',
      'name': 'Trần Hải Đăng',
      'email': 'haidang@email.com',
      'phone': '0908 765 432',
      'tier': 'regular',
      'totalOrders': 5,
      'totalSpend': '12.800.000 ₫',
      'lastOrder': '13 Sep 2026',
      'orderHistory': [
        {'id': 'ORD-1041', 'date': '13 Sep 2026', 'total': '2.500.000 ₫', 'status': 'Đang chuẩn bị', 'statusColor': AppTheme.warning},
        {'id': 'ORD-0920', 'date': '10 Jun 2026', 'total': '10.300.000 ₫', 'status': 'Đã giao', 'statusColor': AppTheme.success},
      ]
    },
    {
      'id': 'CLT-003',
      'name': 'Hoàng Mai Ly',
      'email': 'maily@email.com',
      'phone': '0934 111 222',
      'tier': 'new',
      'totalOrders': 1,
      'totalSpend': '1.200.000 ₫',
      'lastOrder': '12 Sep 2026',
      'orderHistory': [
        {'id': 'ORD-1040', 'date': '12 Sep 2026', 'total': '1.200.000 ₫', 'status': 'Chờ xử lý', 'statusColor': AppTheme.info},
      ]
    },
  ];

  Map<String, dynamic> _getTierBadge(String tier) {
    switch (tier) {
      case 'vip':
        return {'label': 'VIP', 'color': const Color(0xFF9333EA)}; // Purple
      case 'new':
        return {'label': 'Mới', 'color': const Color(0xFF2563EB)}; // Blue
      default:
        return {'label': 'Thường', 'color': AppTheme.textSecondary};
    }
  }

  void _openCustomerDrawer(Map<String, dynamic> customer) {
    final badge = _getTierBadge(customer['tier']);
    MainScreen.of(context).openDrawer(
      DetailDrawer(
        title: 'Hồ sơ Khách hàng\n${customer['id']}',
        onClose: () => MainScreen.of(context).closeDrawer(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Họ và tên', customer['name']),
            _buildInfoRow('Email', customer['email']),
            _buildInfoRow('Số điện thoại', customer['phone']),
            _buildInfoRow('Hạng', badge['label'], valueStyle: TextStyle(color: badge['color'], fontWeight: FontWeight.bold)),
            _buildInfoRow('Tổng chi tiêu', customer['totalSpend'], valueStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 32),
            Text('Lịch sử Đơn hàng (${(customer['orderHistory'] as List).length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOrderHistoryTable(customer['orderHistory']),
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

  Widget _buildOrderHistoryTable(List orders) {
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
          DataColumn(label: Text('Mã ĐH')),
          DataColumn(label: Text('Ngày đặt')),
          DataColumn(label: Text('Giá trị')),
          DataColumn(label: Text('Trạng thái')),
        ],
        rows: orders.map((order) {
          return DataRow(
            cells: [
              DataCell(Text(order['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(order['date'], style: const TextStyle(color: AppTheme.textSecondary))),
              DataCell(Text(order['total'], style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(order['status'], style: TextStyle(fontWeight: FontWeight.w600, color: order['statusColor']))),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCustomers = _activeFilter == 'all'
        ? _customers
        : _customers.where((c) => c['tier'] == _activeFilter).toList();

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
                  Text('Khách hàng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý hồ sơ khách hàng, phân hạng và lịch sử mua sắm.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất file'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm KH'),
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
                  DataColumn(label: Text('Mã KH')),
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Liên hệ')),
                  DataColumn(label: Text('Hạng')),
                  DataColumn(label: Text('Số đơn'), numeric: true),
                  DataColumn(label: Text('Tổng chi tiêu'), numeric: true),
                  DataColumn(label: Text('Đơn gần nhất')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: visibleCustomers.map((customer) {
                  final badge = _getTierBadge(customer['tier']);
                  return DataRow(
                    cells: [
                      DataCell(Text(customer['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(customer['email'], style: const TextStyle(fontSize: 13)),
                          Text(customer['phone'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (badge['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge['label'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge['color'] as Color),
                          ),
                        ),
                      ),
                      DataCell(Text(customer['totalOrders'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(customer['totalSpend'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(customer['lastOrder'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        color: AppTheme.textSecondary,
                        onPressed: () => _openCustomerDrawer(customer),
                        tooltip: 'Xem hồ sơ & Lịch sử',
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
