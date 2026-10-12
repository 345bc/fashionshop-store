import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../../widgets/common/warehouse_table.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/models/order_response_model.dart';
import '../providers/orders_provider.dart';
import '../dialogs/return_management_dialog.dart';
import '../dialogs/order_detail_dialog.dart';
import '../../../../theme/app_theme.dart';

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
            actionLabel: 'Quản lý hoàn hàng',
            actionIcon: Symbols.assignment_return,
            onActionPressed: () => showDialog(
              context: context,
              builder: (_) => const ReturnManagementDialog(),
            ),
          ),
          const SizedBox(height: 24),
          FeatureToolbar(
            searchHint: 'Tìm theo mã đơn, tên/SĐT người nhận, tên/tài khoản KH',
            initialSearchText: p.query,
            onSearchChanged: p.search,
            filterWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilterDropdown<String>(
                  label: 'Trạng thái',
                  searchHint: 'Tìm trạng thái',
                  value: p.status,
                  defaultValue: 'all',
                  options: orderStatuses.entries
                      .map((e) => FilterOption(value: e.key, label: e.value))
                      .toList(),
                  onChanged: (v) => p.filter(v),
                ),
                IconButton(
                  onPressed: p.loadItems,
                  tooltip: 'Làm mới',
                  icon: const Icon(Symbols.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WarehouseTable(
            flexes: const [2, 2, 1, 1, 1],
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
            total: p.totalElements,
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
      hoverColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName.isEmpty
                          ? order.recipientName
                          : order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.recipientPhone,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  money(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _statusBadge(
                    orderStatuses[order.status] ?? order.status,
                    _getStatusColor(order.status),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(
                  orderPaymentStatuses[order.paymentStatus] ??
                      order.paymentStatus,
                  _getPaymentStatusColor(order.paymentStatus),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      case 'SHIPPED':
        return Colors.blue;
      case 'CONFIRMED':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'PAID':
        return AppTheme.success;
      case 'REFUNDED':
        return AppTheme.textSecondary;
      case 'REFUND_PENDING':
        return AppTheme.danger;
      default:
        return Colors.orange;
    }
  }
}
