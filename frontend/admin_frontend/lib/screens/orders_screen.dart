import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/detail_drawer.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả đơn hàng', 'count': 38},
    {'id': 'pending', 'label': 'Chờ xử lý', 'count': 6},
    {'id': 'processing', 'label': 'Đang chuẩn bị', 'count': 8},
    {'id': 'shipped', 'label': 'Đang giao', 'count': 11},
    {'id': 'delivered', 'label': 'Đã giao', 'count': 10},
    {'id': 'cancelled', 'label': 'Đã hủy', 'count': 3},
  ];

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-1042',
      'customer': {'name': 'Nguyễn Lan Phương', 'email': 'lanphuong@email.com', 'phone': '0912 345 678', 'address': '123 Kim Mã, Ba Đình, Hà Nội'},
      'items': 2,
      'total': '3.100.000 ₫',
      'paymentStatus': 'Đã thanh toán',
      'status': 'Đã giao',
      'statusColor': AppTheme.success,
      'createdAt': '14 Sep 2026',
      'orderItems': [
        {'sku': 'MA-COAT-01-S-BLK', 'name': 'Cashmere Double-Breasted Coat', 'size': 'S', 'color': 'Đen', 'qty': 1, 'price': '2.500.000 ₫'},
        {'sku': 'LEA-BAG-09-BLK', 'name': 'Smooth Calfskin Shoulder Bag', 'size': 'One Size', 'color': 'Đen', 'qty': 1, 'price': '600.000 ₫'}
      ]
    },
    {
      'id': 'ORD-1041',
      'customer': {'name': 'Trần Hải Đăng', 'email': 'haidang@email.com', 'phone': '0987 654 321', 'address': '45 Lê Lợi, Q1, TP.HCM'},
      'items': 1,
      'total': '2.500.000 ₫',
      'paymentStatus': 'Đã thanh toán',
      'status': 'Đang chuẩn bị',
      'statusColor': AppTheme.warning,
      'createdAt': '13 Sep 2026',
      'orderItems': [
        {'sku': 'FTW-DRB-42-41', 'name': 'Sculpted Derby Shoes', 'size': '41', 'color': 'Nâu đậm', 'qty': 1, 'price': '2.500.000 ₫'}
      ]
    },
    {
      'id': 'ORD-1040',
      'customer': {'name': 'Hoàng Mai Ly', 'email': 'maily@email.com', 'phone': '0901 234 567', 'address': '88 Nguyễn Văn Linh, Đà Nẵng'},
      'items': 3,
      'total': '1.200.000 ₫',
      'paymentStatus': 'Chưa thanh toán',
      'status': 'Chờ xử lý',
      'statusColor': AppTheme.info,
      'createdAt': '12 Sep 2026',
      'orderItems': [
        {'sku': 'RTW-DRS-07-M-RED', 'name': 'Silk Wrap Midi Dress', 'size': 'M', 'color': 'Đỏ', 'qty': 1, 'price': '800.000 ₫'},
        {'sku': 'ACC-SCF-15', 'name': 'Cashmere Houndstooth Scarf', 'size': 'One Size', 'color': 'Kẻ', 'qty': 2, 'price': '200.000 ₫'}
      ]
    },
  ];

  void _openOrderDrawer(Map<String, dynamic> order) {
    MainScreen.of(context).openDrawer(
      DetailDrawer(
        title: 'Chi tiết Đơn hàng\n${order['id']}',
        onClose: () => MainScreen.of(context).closeDrawer(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin khách hàng & Giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Khách hàng', order['customer']['name']),
            _buildInfoRow('Liên hệ', '${order['customer']['phone']} • ${order['customer']['email']}'),
            _buildInfoRow('Địa chỉ giao hàng', order['customer']['address']),
            _buildInfoRow('Trạng thái Thanh toán', order['paymentStatus'], valueStyle: TextStyle(color: order['paymentStatus'] == 'Đã thanh toán' ? AppTheme.success : AppTheme.warning, fontWeight: FontWeight.bold)),
            _buildInfoRow('Trạng thái Giao hàng', order['status'], valueStyle: TextStyle(color: order['statusColor'], fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 32),
            Text('Mặt hàng (${(order['orderItems'] as List).length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOrderItemsTable(order['orderItems'], order['total']),
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
          Flexible(child: Text(value, style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildOrderItemsTable(List items, String total) {
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
              DataColumn(label: Text('Sản phẩm')),
              DataColumn(label: Text('Thuộc tính')),
              DataColumn(label: Text('SL')),
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
                  DataCell(Text('${item['size']} • ${item['color']}', style: const TextStyle(color: AppTheme.textSecondary))),
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
                const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.w600)),
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
    final visibleOrders = _activeFilter == 'all'
        ? _orders
        : _orders.where((o) {
            final filterMap = {
              'pending': 'Chờ xử lý',
              'processing': 'Đang chuẩn bị',
              'shipped': 'Đang giao',
              'delivered': 'Đã giao',
              'cancelled': 'Đã hủy'
            };
            return o['status'] == filterMap[_activeFilter];
          }).toList();

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
                  Text('Quản lý Đơn hàng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Theo dõi, quản lý và xử lý tất cả đơn hàng của khách.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                    label: const Text('Tạo đơn hàng'),
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
                  DataColumn(label: Text('Mã ĐH')),
                  DataColumn(label: Text('Khách hàng')),
                  DataColumn(label: Text('Số SP'), numeric: true),
                  DataColumn(label: Text('Tổng tiền'), numeric: true),
                  DataColumn(label: Text('Thanh toán')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Ngày đặt')),
                  DataColumn(label: Text('')),
                ],
                rows: visibleOrders.map((order) {
                  return DataRow(
                    cells: [
                      DataCell(Text(order['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(order['customer']['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(order['customer']['email'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      )),
                      DataCell(Text(order['items'].toString(), style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(order['total'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (order['paymentStatus'] == 'Đã thanh toán' ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order['paymentStatus'],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: order['paymentStatus'] == 'Đã thanh toán' ? AppTheme.success : AppTheme.warning),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (order['statusColor'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order['status'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: order['statusColor'] as Color),
                          ),
                        ),
                      ),
                      DataCell(Text(order['createdAt'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        color: AppTheme.textSecondary,
                        onPressed: () => _openOrderDrawer(order),
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
