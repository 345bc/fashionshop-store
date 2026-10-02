import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../../../widgets/dialogs/quantity_selection_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../data/models/goods_receipt_response_model.dart';
import '../providers/purchases_provider.dart';
import 'goods_receipt_form_dialog.dart';
import 'supplier_payment_dialog.dart';

class GoodsReceiptDetailDialog extends StatefulWidget {
  final int receiptId;
  const GoodsReceiptDetailDialog({super.key, required this.receiptId});
  @override
  State<GoodsReceiptDetailDialog> createState() =>
      _GoodsReceiptDetailDialogState();
}

class _GoodsReceiptDetailDialogState extends State<GoodsReceiptDetailDialog> {
  late Future<GoodsReceiptResponseModel> _future;
  bool _busy = false;
  Future<void> _returnToSupplier(GoodsReceiptResponseModel receipt) async {
    final provider = context.read<PurchasesProvider>();
    final choices = receipt.items
        .where(
          (i) => (i['quantity'] as int) > (i['returnedQuantity'] as int? ?? 0),
        )
        .map(
          (i) => QuantityChoice(
            id: i['variantId'] as int,
            maximum:
                (i['quantity'] as int) - (i['returnedQuantity'] as int? ?? 0),
            label: '${i["productName"]} • ${i["sku"]}',
          ),
        )
        .toList();
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => QuantitySelectionDialog(
        title: 'Trả hàng nhà cung cấp',
        choices: choices,
        description: 'Chỉ xác nhận khi đã bàn giao hàng trả. Hệ thống giảm tồn và giảm công nợ theo đơn giá nhập.',
        onSubmit: (reason, quantities) => provider.action(
          receipt.id,
          'returns',
          data: {
            'reason': reason,
            'items': quantities.entries
                .map((e) => {'variantId': e.key, 'quantity': e.value})
                .toList(),
          },
        ),
      ),
    );
    if (done == true && mounted) {
      context.read<InventoryProvider>().loadItems();
      setState(_load);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<PurchasesProvider>().loadDetail(widget.receiptId);
  }

  Future<void> _action(String action) async {
    final title = action == 'post' ? 'Xác nhận nhập kho' : 'Hủy phiếu nhập';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ZellaConfirmDialog(
        title: title,
        content: Text(
          action == 'post'
              ? 'Hàng đã nhận và kiểm tra đầy đủ? Xác nhận sẽ cộng tồn kho.'
              : 'Hủy phiếu này? Phiếu đã nhập kho sẽ được đảo tồn nếu đủ điều kiện.',
        ),
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<PurchasesProvider>().action(widget.receiptId, action);
      if (!mounted) return;
      context.read<InventoryProvider>().loadItems();
      setState(_load);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: size.width * 2 / 3,
      height: size.height * .8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết phiếu nhập',
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
                    child: Text('Không tải được phiếu: ${snapshot.error}'),
                  );
                }
                final r = snapshot.data!;
                return ListView(
                  children: [
                    Text(
                      r.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('Nhà cung cấp: ${r.supplierName}'),
                    Text(
                      'Trạng thái: ${receiptStatuses[r.status]} • ${paymentStatuses[r.paymentStatus]}',
                    ),
                    Text(
                      'Tạo bởi: ${r.createdBy ?? "—"} • ${DateFormat("dd/MM/yyyy HH:mm").format(r.createdAt)}',
                    ),
                    if (r.postedBy != null) Text('Nhập kho bởi: ${r.postedBy}'),
                    if (r.note?.isNotEmpty == true) Text('Ghi chú: ${r.note}'),
                    const SizedBox(height: 16),
                    for (final item in r.items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${item["productName"]} — ${item["sizeName"]} / ${item["colorName"]}',
                        ),
                        subtitle: Text(
                          '${item["sku"]} • ${item["quantity"]} × ${money(item["unitCost"] as num)}',
                        ),
                        trailing: Text(money(item['subtotal'] as num)),
                      ),
                    const Divider(),
                    Text('Tổng tiền: ${money(r.totalAmount)}'),
                    Text('Giảm trừ hàng trả: ${money(r.returnedAmount)}'),
                    if (r.supplierRefundDue > 0)
                      Text(
                        'Nhà cung cấp cần hoàn lại: ${money(r.supplierRefundDue)}',
                      ),
                    Text(
                      'Đã trả: ${money(r.paidAmount)} • Còn nợ: ${money(r.remainingAmount)}',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (r.status == 'DRAFT')
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final saved = await showDialog<bool>(
                                      context: context,
                                      builder: (_) =>
                                          GoodsReceiptFormDialog(receipt: r),
                                    );
                                    if (saved == true && mounted) {
                                      setState(_load);
                                    }
                                  },
                            child: const Text('Sửa nháp'),
                          ),
                        if (r.status == 'DRAFT')
                          ElevatedButton(
                            onPressed: _busy ? null : () => _action('post'),
                            child: const Text('Xác nhận nhập kho'),
                          ),
                        if (r.status == 'POSTED' && r.remainingAmount > 0)
                          ElevatedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final paid = await showDialog<bool>(
                                      context: context,
                                      builder: (_) =>
                                          SupplierPaymentDialog(receipt: r),
                                    );
                                    if (paid == true && mounted) {
                                      setState(_load);
                                    }
                                  },
                            child: const Text('Thanh toán'),
                          ),
                        if (r.status == 'POSTED' &&
                            r.items.any(
                              (i) =>
                                  (i['quantity'] as int) >
                                  (i['returnedQuantity'] as int? ?? 0),
                            ))
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _returnToSupplier(r),
                            child: const Text('Trả nhà cung cấp'),
                          ),
                        if (r.status == 'POSTED' && r.supplierRefundDue > 0)
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final done = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => SupplierPaymentDialog(
                                        receipt: r,
                                        isRefund: true,
                                      ),
                                    );
                                    if (done == true && mounted) {
                                      setState(_load);
                                    }
                                  },
                            child: const Text('Ghi nhận đã nhận tiền hoàn'),
                          ),
                        if (r.status != 'CANCELLED' &&
                            r.paidAmount == 0 &&
                            r.returns.isEmpty)
                          OutlinedButton(
                            onPressed: _busy ? null : () => _action('cancel'),
                            child: const Text('Hủy phiếu'),
                          ),
                      ],
                    ),
                    if (_busy) const LinearProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Lịch sử trả nhà cung cấp',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (r.returns.isEmpty) const Text('Chưa có hàng trả'),
                    for (final d in r.returns)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${d["code"]} • ${money(d["amount"] as num)}',
                        ),
                        subtitle: Text(
                          '${d["reason"]} • ${d["createdBy"]}\n'
                          '${(d["items"] as List).map((i) => "SKU ID ${i["variantId"]}: ${i["quantity"]}").join(", ")}',
                        ),
                      ),
                    if (r.refunds.isNotEmpty)
                      Text(
                        'Đã nhận tiền hoàn: ${money(r.supplierRefundedAmount)}',
                      ),
                    for (final f in r.refunds)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(money(f['amount'] as num)),
                        subtitle: Text(
                          '${f["createdAt"]} • ${f["createdBy"]} • ${f["note"] ?? ""}',
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Lịch sử thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (r.payments.isEmpty) const Text('Chưa có thanh toán'),
                    for (final p in r.payments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${money(p["amount"] as num)} • ${p["paymentMethod"] == "CASH" ? "Tiền mặt" : "Chuyển khoản"}',
                        ),
                        subtitle: Text(
                          '${p["createdBy"] ?? "—"} • ${p["paidAt"]}\n${p["note"] ?? ""}',
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
