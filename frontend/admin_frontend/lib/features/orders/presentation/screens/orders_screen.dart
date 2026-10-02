import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/warehouse_table.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/models/order_response_model.dart';
import '../providers/orders_provider.dart';
import '../dialogs/order_form_dialog.dart';
import '../dialogs/order_detail_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<OrdersProvider>(
    builder: (context, p, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureHeader(
            title: 'Đơn hàng',
            subtitle: 'Quản lý đơn bán, giữ hàng, xuất kho và trả hàng',
            actionLabel: 'Tạo đơn hàng',
            actionIcon: Icons.add,
            onActionPressed: () => showDialog(
              context: context,
              builder: (_) => const OrderFormDialog(),
            ),
          ),
          const SizedBox(height: 24),
          FeatureToolbar(
            searchHint: 'Tìm mã đơn, tên khách, số điện thoại...',
            initialSearchText: p.query,
            onSearchChanged: p.search,
            filterWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: p.status,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    ...orderStatuses.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (v) => p.filter(v ?? 'all'),
                ),
                IconButton(
                  onPressed: p.loadItems,
                  tooltip: 'Làm mới',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WarehouseTable(
            headers: const [
              'ĐƠN HÀNG',
              'KHÁCH HÀNG',
              'TỔNG TIỀN',
              'TRẠNG THÁI',
              'THANH TOÁN',
            ],
            rows: p.pageItems.map(_row).toList(),
            loading: p.isLoading,
            error: p.error,
            page: p.currentPage,
            total: p.filtered.length,
            pageSize: p.pageSize,
            onPage: p.page,
            onRetry: p.loadItems,
          ),
        ],
      ),
    ),
  );
  Widget _row(OrderResponseModel order) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => OrderDetailDialog(orderId: order.id),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text('${order.customerName}\n${order.recipientPhone}'),
            ),
            Expanded(child: Text(money(order.totalAmount))),
            Expanded(child: Text(orderStatuses[order.status] ?? order.status)),
            Expanded(
              child: Text(
                orderPaymentStatuses[order.paymentStatus] ??
                    order.paymentStatus,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
