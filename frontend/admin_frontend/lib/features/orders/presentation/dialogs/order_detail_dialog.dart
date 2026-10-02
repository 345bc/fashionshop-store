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
      // TEMP_ORDER_PAYMENT_SIMULATION: backend decides whether the test button is available.
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

  Widget _button(String label, VoidCallback action) =>
      OutlinedButton(onPressed: _busy ? null : action, child: Text(label));
  Widget _returnCard(ReturnResponseModel r) {
    final provider = context.read<OrdersProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${r.code} • ${returnStatuses[r.status] ?? r.status}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Lý do: ${r.reason}'),
            for (final i in r.items)
              Text(
                '${i["productName"]} • ${i["sku"]} × ${i["quantity"]}'
                '${i["condition"] == null
                    ? ""
                    : i["condition"] == "INTACT"
                    ? " • Nguyên vẹn"
                    : " • Hỏng"}',
              ),
            Text('Tiền hoàn: ${money(r.refundAmount)}'),
            if (r.adminNote != null) Text('Ghi nhận hoàn tiền: ${r.adminNote}'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (r.status == 'PENDING')
                  _button(
                    'Duyệt',
                    () => _confirm(
                      'Duyệt phiếu trả',
                      'Chấp nhận nhận hàng trả?',
                      () => provider.returnAction(r.id, 'approve'),
                    ),
                  ),
                if (r.status == 'PENDING')
                  _button(
                    'Từ chối',
                    () => _note(
                      'Từ chối phiếu trả',
                      'Nhập lý do từ chối.',
                      (note, _) => provider.returnAction(
                        r.id,
                        'reject',
                        data: {'note': note},
                      ),
                    ),
                  ),
                if (r.status == 'PENDING' || r.status == 'APPROVED')
                  _button(
                    'Hủy phiếu trả',
                    () => _note(
                      'Hủy phiếu trả',
                      'Hủy phiếu chưa nhận hàng.',
                      (note, _) => provider.returnAction(
                        r.id,
                        'cancel',
                        data: {'note': note},
                      ),
                    ),
                  ),
                if (r.status == 'APPROVED')
                  _button('Nhận hàng', () async {
                    final done = await showDialog<bool>(
                      context: context,
                      builder: (_) => ReceiveReturnDialog(document: r),
                    );
                    if (done == true) _refresh();
                  }),
                if (r.status == 'RECEIVED')
                  _button(
                    'Hoàn tất / ghi nhận hoàn tiền',
                    () => _note(
                      'Hoàn tất phiếu trả',
                      r.refundAmount > 0
                          ? 'Chỉ xác nhận sau khi đã hoàn ${money(r.refundAmount)} cho khách.'
                          : 'Không có khoản tiền cần hoàn.',
                      (note, method) => provider.returnAction(
                        r.id,
                        'complete',
                        data: {'note': note, 'refundMethod': method},
                      ),
                      methods: r.refundAmount > 0
                          ? {
                              'BANK_TRANSFER': 'Chuyển khoản',
                              'CASH': 'Tiền mặt',
                            }
                          : {'NO_REFUND': 'Không hoàn tiền'},
                    ),
                  ),
              ],
            ),
            for (final h in r.histories)
              Text(
                '${h["createdAt"]} • ${h["changedBy"]} • ${h["note"]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrdersProvider>();
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
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
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
                return ListView(
                  children: [
                    Text(
                      order.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Khách hàng: ${order.customerName}'),
                    Text(
                      'Người nhận: ${order.recipientName} • ${order.recipientPhone}',
                    ),
                    Text('Địa chỉ: ${order.address}'),
                    Text(
                      'Trạng thái: ${orderStatuses[order.status] ?? order.status} • ${orderPaymentStatuses[order.paymentStatus] ?? order.paymentStatus}',
                    ),
                    Text(
                      'Ngày tạo: ${DateFormat("dd/MM/yyyy HH:mm").format(order.createdAt)}',
                    ),
                    if (order.note?.isNotEmpty == true)
                      Text('Ghi chú: ${order.note}'),
                    for (final i in order.items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(i['productName'] as String),
                        subtitle: Text(
                          '${i["sku"]} • ${i["quantity"]} × ${money(i["unitPrice"] as num)}'
                          ' • Đã có phiếu trả: ${i["returnedQuantity"]}',
                        ),
                        trailing: Text(money(i['subtotal'] as num)),
                      ),
                    Text('Phí vận chuyển: ${money(order.shippingFee)}'),
                    Text(
                      'Tổng tiền: ${money(order.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (order.status == 'PENDING' &&
                        order.paymentExpiresAt != null)
                      PaymentReservationStatus(
                        expiresAt: order.paymentExpiresAt!,
                        onExpired: _refresh,
                      ),
                    if (!order.inventoryManaged)
                      const Text(
                        'Đơn cũ chưa theo dõi kho, chỉ xem thông tin.',
                      ),
                    if (order.inventoryManaged)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // BEGIN TEMP_ORDER_PAYMENT_SIMULATION: delete this button after testing.
                          if (snapshot.data!.simulationEnabled &&
                              order.status == 'PENDING' &&
                              order.paymentStatus == 'PENDING')
                            _button(
                              'TEST • Xác nhận đơn (giả lập)',
                              () => _confirm(
                                'Giả lập thanh toán thành công',
                                'Chỉ để test: giả lập đã thanh toán đủ tiền và tự xác nhận đơn. Hạn 5 phút vẫn được kiểm tra.',
                                () => provider.simulatePayment(order.id),
                              ),
                            ),
                          // END TEMP_ORDER_PAYMENT_SIMULATION
                          if (order.status == 'CONFIRMED' &&
                              order.paymentStatus == 'PAID')
                            _button(
                              'Xuất kho',
                              () => _confirm(
                                'Xuất kho',
                                'Hàng đã đóng gói và bàn giao vận chuyển? Xác nhận sẽ trừ tồn thực tế.',
                                () => provider.action(order.id, 'ship'),
                              ),
                            ),
                          if (order.status == 'SHIPPED' &&
                              returns.every(
                                (r) =>
                                    r.status == 'CANCELLED' ||
                                    r.status == 'REJECTED',
                              ))
                            _button(
                              'Giao thành công',
                              () => _confirm(
                                'Giao thành công',
                                'Xác nhận khách đã nhận hàng?',
                                () => provider.action(order.id, 'deliver'),
                              ),
                            ),
                          if (order.status == 'PENDING' ||
                              order.status == 'CONFIRMED')
                            _button(
                              'Hủy đơn',
                              () => _note(
                                'Hủy đơn',
                                'Hủy sẽ giải phóng hàng đã giữ. Đơn đã thu tiền sẽ chờ hoàn.',
                                (note, _) => provider.action(
                                  order.id,
                                  'cancel',
                                  data: {'note': note},
                                ),
                              ),
                            ),
                          if (order.paymentStatus == 'REFUND_PENDING')
                            _button(
                              'Ghi nhận đã hoàn tiền',
                              () => _note(
                                'Hoàn tiền đơn hủy',
                                'Chỉ xác nhận sau khi đã hoàn đủ ${money(order.totalAmount)}.',
                                (note, _) => provider.action(
                                  order.id,
                                  'refunded',
                                  data: {'note': note},
                                ),
                              ),
                            ),
                          if ((order.status == 'SHIPPED' ||
                                  order.status == 'DELIVERED') &&
                              canReturn)
                            _button(
                              order.status == 'SHIPPED'
                                  ? 'Giao thất bại / nhận lại hàng'
                                  : 'Lập phiếu trả hàng',
                              () => _createReturn(order),
                            ),
                        ],
                      ),
                    if (_busy) const LinearProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Phiếu trả hàng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (returns.isEmpty) const Text('Chưa có phiếu trả'),
                    ...returns.map(_returnCard),
                    const SizedBox(height: 24),
                    const Text(
                      'Lịch sử đơn hàng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    for (final h in order.histories)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(h['note']?.toString() ?? ''),
                        subtitle: Text('${h["createdAt"]} • ${h["createdBy"]}'),
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
