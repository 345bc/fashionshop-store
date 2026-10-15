import '../../../auth/presentation/provider/auth_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../../../widgets/dialogs/operation_note_dialog.dart';
import '../../../../widgets/dialogs/quantity_selection_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../data/models/order_response_model.dart';
import '../providers/orders_provider.dart';
import 'receive_return_dialog.dart';
import '../widgets/payment_reservation_status.dart';
import '../../../../theme/app_theme.dart';

class OrderDetailDialog extends StatefulWidget {
  final int orderId;
  const OrderDetailDialog({super.key, required this.orderId});
  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  late Future<
    ({
      OrderResponseModel order,
      List<ReturnResponseModel> returns,
      bool simulationEnabled,
    })
  >
  _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final provider = context.read<OrdersProvider>();
    _future = (() async => (
      order: await provider.loadDetail(widget.orderId),
      returns: await provider.returns(widget.orderId),
      simulationEnabled: await provider.paymentSimulationEnabled(),
    ))();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<InventoryProvider>().loadItems();
    setState(_load);
  }

  Future<void> _confirm(
    String title,
    String description,
    Future<void> Function() submit,
  ) async {
    if (_busy) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ZellaConfirmDialog(
        title: title,
        content: Text(description),
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (agreed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await submit();
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _note(
    String title,
    String description,
    Future<void> Function(String, String) submit, {
    Map<String, String>? methods,
  }) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => OperationNoteDialog(
        title: title,
        description: description,
        methods: methods,
        onSubmit: submit,
      ),
    );
    if (done == true) _refresh();
  }

  Future<void> _createReturn(OrderResponseModel order) async {
    final choices = order.items
        .where((i) => (i['quantity'] as int) > (i['returnedQuantity'] as int))
        .map(
          (i) => QuantityChoice(
            id: i['id'] as int,
            maximum: (i['quantity'] as int) - (i['returnedQuantity'] as int),
            label: '${i["productName"]} — ${i["sku"]}',
          ),
        )
        .toList();
    final provider = context.read<OrdersProvider>();
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => QuantitySelectionDialog(
        title: order.status == 'SHIPPED'
            ? 'Nhận lại kiện giao không thành công'
            : 'Lập phiếu trả hàng',
        description: 'Lập phiếu chưa cộng tồn. Sau khi duyệt, nhận hàng thực tế và kiểm tra mới cập nhật kho.',
        choices: choices,
        requireAll: order.status == 'SHIPPED',
        onSubmit: (reason, quantities) => provider.createReturn({
          'orderId': order.id,
          'reason': reason,
          'items': quantities.entries
              .map((e) => {'orderItemId': e.key, 'quantity': e.value})
              .toList(),
        }),
      ),
    );
    if (done == true) _refresh();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Color _getReturnStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppTheme.success;
      case 'CANCELLED':
      case 'REJECTED':
        return AppTheme.danger;
      default:
        return Colors.orange;
    }
  }

  Widget _buildLeftColumn(
    OrderResponseModel order,
    List<ReturnResponseModel> returns,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Danh sách sản phẩm', Symbols.inventory_2),
        _buildItemsList(order),
        const SizedBox(height: 24),
        if (returns.isNotEmpty) ...[
          _buildSectionHeader('Phiếu trả hàng', Symbols.assignment_return),
          ...returns.map(_returnCard),
          const SizedBox(height: 24),
        ],
        _buildSectionHeader('Lịch sử đơn hàng', Symbols.history),
        _buildHistoryList(order),
      ],
    );
  }

  Widget _buildRightColumn(
    OrderResponseModel order,
    List<ReturnResponseModel> returns,
    bool canReturn,
    bool simulationEnabled,
  ) {
    final actions = _buildActionButtons(
      order,
      returns,
      canReturn,
      simulationEnabled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _statusBadge(
              orderStatuses[order.status] ?? order.status,
              _getStatusColor(order.status),
            ),
            _statusBadge(
              orderPaymentStatuses[order.paymentStatus] ?? order.paymentStatus,
              _getPaymentStatusColor(order.paymentStatus),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Thông tin khách hàng', Symbols.person),
        _buildCustomerInfo(order),
        const SizedBox(height: 24),
        _buildSectionHeader('Thanh toán', Symbols.payments),
        _buildPaymentSummary(order),
        const SizedBox(height: 24),
        _buildSectionHeader('Thao tác', Symbols.touch_app),
        if (actions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Text(
              'Không có thao tác nào khả dụng.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
      ],
    );
  }

  Widget _buildCustomerInfo(OrderResponseModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Symbols.person, 'Người nhận', order.recipientName),
          const SizedBox(height: 12),
          _infoRow(Symbols.call, 'Số điện thoại', order.recipientPhone),
          const SizedBox(height: 12),
          _infoRow(Symbols.location_on, 'Địa chỉ', order.address),
          if (order.note?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _infoRow(Symbols.notes, 'Ghi chú', order.note!),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(OrderResponseModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(money(order.totalAmount - order.shippingFee)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phí vận chuyển',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(money(order.shippingFee)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                money(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(OrderResponseModel order) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: order.items.asMap().entries.map((e) {
          final i = e.value;
          final isLast = e.key == order.items.length - 1;
          final returnedQty = i['returnedQuantity'] as int;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Symbols.inventory_2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i['productName'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${i["sku"]}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (returnedQty > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Đã trả hàng: $returnedQty',
                                style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          money(i['subtotal'] as num),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${i["quantity"]} × ${money(i["unitPrice"] as num)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(OrderResponseModel order) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: order.histories.asMap().entries.map((e) {
          final h = e.value;
          final isLast = e.key == order.histories.length - 1;
          return Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surface,
                  child: Icon(
                    Symbols.history,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                title: Text(h['note']?.toString() ?? ''),
                subtitle: Text(
                  '${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.parse(h["createdAt"] as String).toLocal())} • ${h["createdBy"]}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    OrderResponseModel order,
    List<ReturnResponseModel> returns,
    bool canReturn,
    bool simulationEnabled,
  ) {
    final provider = context.read<OrdersProvider>();
    final List<Widget> actions = [];

    if (order.status == 'PENDING' && order.paymentExpiresAt != null) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PaymentReservationStatus(
            expiresAt: order.paymentExpiresAt!,
            onExpired: _refresh,
          ),
        ),
      );
    }

    if (!order.inventoryManaged) {
      actions.add(
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Đơn cũ chưa theo dõi kho, chỉ xem thông tin.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (order.inventoryManaged) {
      if (context.watch<AuthProvider>().hasRole('ADMIN') && simulationEnabled &&
          order.status == 'PENDING' &&
          order.paymentStatus == 'PENDING') {
        actions.add(
          _actionButton(
            'TEST • Xác nhận đơn',
            Symbols.science,
            Colors.purple,
            () => _confirm(
              'Giả lập thanh toán thành công',
              'Chỉ để test: giả lập đã thanh toán đủ tiền và tự xác nhận đơn. Hạn 5 phút vẫn được kiểm tra.',
              () => provider.simulatePayment(order.id),
            ),
          ),
        );
      }
      if ((context.watch<AuthProvider>().hasRole('ADMIN') || context.watch<AuthProvider>().hasRole('SALES')) && order.status == 'CONFIRMED' && order.paymentStatus == 'PAID') {
        actions.add(
          _actionButton(
            'Xuất kho',
            Symbols.local_shipping,
            AppTheme.primary,
            () => _confirm(
              'Xuất kho',
              'Hàng đã đóng gói và bàn giao vận chuyển? Xác nhận sẽ trừ tồn thực tế.',
              () => provider.action(order.id, 'ship'),
            ),
          ),
        );
      }
      if ((context.watch<AuthProvider>().hasRole('ADMIN') || context.watch<AuthProvider>().hasRole('SALES')) && order.status == 'SHIPPED' &&
          returns.every(
            (r) => r.status == 'CANCELLED' || r.status == 'REJECTED',
          )) {
        actions.add(
          _actionButton(
            'Giao thành công',
            Symbols.check_circle,
            AppTheme.success,
            () => _confirm(
              'Giao thành công',
              'Xác nhận khách đã nhận hàng?',
              () => provider.action(order.id, 'deliver'),
            ),
          ),
        );
      }
      if ((context.watch<AuthProvider>().hasRole('ADMIN') || context.watch<AuthProvider>().hasRole('SALES')) && (order.status == 'PENDING' || order.status == 'CONFIRMED')) {
        actions.add(
          _actionButton(
            'Hủy đơn',
            Symbols.cancel,
            AppTheme.danger,
            () => _note(
              'Hủy đơn',
              'Hủy sẽ giải phóng hàng đã giữ. Đơn đã thu tiền sẽ chờ hoàn.',
              (note, _) =>
                  provider.action(order.id, 'cancel', data: {'note': note}),
            ),
            isOutlined: true,
          ),
        );
      }
      if (context.watch<AuthProvider>().hasRole('ADMIN') && order.paymentStatus == 'REFUND_PENDING') {
        actions.add(
          _actionButton(
            'Ghi nhận đã hoàn tiền',
            Symbols.payments,
            AppTheme.success,
            () => _note(
              'Hoàn tiền đơn hủy',
              'Chỉ xác nhận sau khi đã hoàn đủ ${money(order.totalAmount)}.',
              (note, _) =>
                  provider.action(order.id, 'refunded', data: {'note': note}),
            ),
          ),
        );
      }
      if ((context.watch<AuthProvider>().hasRole('ADMIN') || context.watch<AuthProvider>().hasRole('CUSTOMER_SUPPORT')) && (order.status == 'SHIPPED' || order.status == 'DELIVERED') &&
          canReturn) {
        actions.add(
          _actionButton(
            order.status == 'SHIPPED'
                ? 'Giao thất bại / nhận lại hàng'
                : 'Lập phiếu trả hàng',
            Symbols.assignment_return,
            Colors.orange,
            () => _createReturn(order),
            isOutlined: true,
          ),
        );
      }
    }

    return actions;
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback action, {
    bool isOutlined = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: _busy ? null : action,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _busy ? null : action,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
    );
  }

  Widget _returnCard(ReturnResponseModel r) {
    final provider = context.read<OrdersProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r.code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _statusBadge(
                  returnStatuses[r.status] ?? r.status,
                  _getReturnStatusColor(r.status),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow(Symbols.help, 'Lý do', r.reason),
                const SizedBox(height: 12),
                const Text(
                  'Sản phẩm:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...r.items.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        Expanded(
                          child: Text(
                            '${i["productName"]} • ${i["sku"]} × ${i["quantity"]}'
                            '${i["condition"] == null
                                ? ""
                                : i["condition"] == "INTACT"
                                ? " • Nguyên vẹn"
                                : " • Hỏng"}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow(Symbols.payments, 'Tiền hoàn', money(r.refundAmount)),
                if (r.adminNote != null) ...[
                  const SizedBox(height: 12),
                  _infoRow(Symbols.notes, 'Ghi nhận hoàn tiền', r.adminNote!),
                ],
                if (r.status == 'PENDING' ||
                    r.status == 'APPROVED' ||
                    r.status == 'RECEIVED') ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (context.watch<AuthProvider>().hasRole('ADMIN') && r.status == 'PENDING')
                        ElevatedButton(
                          onPressed: _busy
                              ? null
                              : () => _confirm(
                                  'Duyệt phiếu trả',
                                  'Chấp nhận nhận hàng trả?',
                                  () => provider.returnAction(r.id, 'approve'),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Duyệt'),
                        ),
                      if (context.watch<AuthProvider>().hasRole('ADMIN') && r.status == 'PENDING')
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _note(
                                  'Từ chối phiếu trả',
                                  'Nhập lý do từ chối.',
                                  (note, _) => provider.returnAction(
                                    r.id,
                                    'reject',
                                    data: {'note': note},
                                  ),
                                ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      if (context.watch<AuthProvider>().hasRole('ADMIN') && (r.status == 'PENDING' || r.status == 'APPROVED'))
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _note(
                                  'Hủy phiếu trả',
                                  'Hủy phiếu chưa nhận hàng.',
                                  (note, _) => provider.returnAction(
                                    r.id,
                                    'cancel',
                                    data: {'note': note},
                                  ),
                                ),
                          child: const Text('Hủy phiếu'),
                        ),
                      if ((context.watch<AuthProvider>().hasRole('ADMIN') || context.watch<AuthProvider>().hasRole('WAREHOUSE')) && r.status == 'APPROVED')
                        ElevatedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final done = await showDialog<bool>(
                                    context: context,
                                    builder: (_) =>
                                        ReceiveReturnDialog(document: r),
                                  );
                                  if (done == true) _refresh();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Nhận hàng'),
                        ),
                      if (context.watch<AuthProvider>().hasRole('ADMIN') && r.status == 'RECEIVED')
                        ElevatedButton(
                          onPressed: _busy
                              ? null
                              : () => _note(
                                  'Hoàn tất phiếu trả',
                                  r.refundAmount > 0
                                      ? 'Chỉ xác nhận sau khi đã hoàn ${money(r.refundAmount)} cho khách.'
                                      : 'Không có khoản tiền cần hoàn.',
                                  (note, method) => provider.returnAction(
                                    r.id,
                                    'complete',
                                    data: {
                                      'note': note,
                                      'refundMethod': method,
                                    },
                                  ),
                                  methods: r.refundAmount > 0
                                      ? {
                                          'BANK_TRANSFER': 'Chuyển khoản',
                                          'CASH': 'Tiền mặt',
                                        }
                                      : {'NO_REFUND': 'Không hoàn tiền'},
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hoàn tất / Ghi nhận hoàn tiền'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZellaDialog(
      width: MediaQuery.sizeOf(context).width * 2 / 3,
      height: MediaQuery.sizeOf(context).height * .85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                icon: const Icon(Symbols.close),
              ),
            ],
          ),
          const Divider(),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(snapshot.error.toString()),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final order = snapshot.data!.order;
                final returns = snapshot.data!.returns;
                final canReturn = order.items.any(
                  (i) =>
                      (i['quantity'] as int) > (i['returnedQuantity'] as int),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            order.code,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Ngày tạo: ${DateFormat("dd/MM/yyyy HH:mm").format(order.createdAt)}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildLeftColumn(order, returns),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _buildRightColumn(
                                order,
                                returns,
                                canReturn,
                                snapshot.data!.simulationEnabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
