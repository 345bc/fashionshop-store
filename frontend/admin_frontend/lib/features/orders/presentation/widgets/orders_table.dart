import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class OrdersTable extends StatelessWidget {
  final String activeTab;
  
  const OrdersTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allOrders = [
      {
        'id': 'ORD-1042',
        'customer': {'name': 'Nguyễn Lan Phương', 'email': 'lanphuong@email.com', 'phone': '0912 345 678', 'address': '123 Kim Mã, Ba Đình, Hà Nội'},
        'items': 2,
        'total': '3.100.000 ₫',
        'paymentStatus': 'Đã thanh toán',
        'status': 'Đã giao',
        'statusId': 'delivered',
        'statusColor': AppTheme.success,
        'createdAt': '14 Sep 2026',
      },
      {
        'id': 'ORD-1041',
        'customer': {'name': 'Trần Hải Đăng', 'email': 'haidang@email.com', 'phone': '0987 654 321', 'address': '45 Lê Lợi, Q1, TP.HCM'},
        'items': 1,
        'total': '2.500.000 ₫',
        'paymentStatus': 'Đã thanh toán',
        'status': 'Đang chuẩn bị',
        'statusId': 'processing',
        'statusColor': AppTheme.warning,
        'createdAt': '13 Sep 2026',
      }
    ];

    final visibleOrders = activeTab == 'all' 
        ? allOrders 
        : allOrders.where((o) => o['statusId'] == activeTab).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Mã ĐH', style: _headerStyle())),
              Expanded(flex: 3, child: Text('Khách hàng', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Tổng tiền', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Thanh toán', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Ngày đặt', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visibleOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleOrders.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final order = visibleOrders[index];
              return _buildDataRow(context, order);
            },
          ),
        // Pagination Footer
        const Divider(height: 1, color: AppTheme.borderLight),
        _buildPagination(),
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

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> order) {
    return InkWell(
      onTap: () {},
      hoverColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                order['id'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['customer']['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    order['customer']['email'],
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['total'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${order['items']} sản phẩm',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (order['paymentStatus'] == 'Đã thanh toán' ? AppTheme.success : AppTheme.warning).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['paymentStatus'],
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600, 
                      color: order['paymentStatus'] == 'Đã thanh toán' ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (order['statusColor'] as Color).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: order['statusColor'] as Color),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order['createdAt'],
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Xem chi tiết'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hiển thị 1-10 trong số 38 đơn hàng',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageBtn(Icons.chevron_left, null),
              const SizedBox(width: 8),
              _buildPageBtn('1', true),
              const SizedBox(width: 8),
              _buildPageBtn('2', false),
              const SizedBox(width: 8),
              _buildPageBtn('3', false),
              const SizedBox(width: 8),
              _buildPageBtn(Icons.chevron_right, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageBtn(dynamic content, dynamic actionOrIsActive) {
    final bool isActive = actionOrIsActive == true;
    final bool isDisabled = actionOrIsActive == null;

    return InkWell(
      onTap: isDisabled || isActive ? null : (actionOrIsActive is Function ? actionOrIsActive as void Function() : () {}),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppTheme.primary : (isDisabled ? Colors.transparent : AppTheme.borderLight)),
        ),
        alignment: Alignment.center,
        child: content is IconData
            ? Icon(content, size: 18, color: isDisabled ? AppTheme.textMuted : AppTheme.textSecondary)
            : Text(
                content.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}
