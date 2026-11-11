import '../../../auth/presentation/provider/auth_provider.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../../../widgets/dialogs/quantity_selection_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../data/models/goods_receipt_response_model.dart';
import '../providers/purchases_provider.dart';
import '../dialogs/goods_receipt_form_dialog.dart';
import '../dialogs/supplier_payment_dialog.dart';

class GoodsReceiptDetailScreen extends StatefulWidget {
  final int receiptId;
  final VoidCallback onClose;

  const GoodsReceiptDetailScreen({
    super.key,
    required this.receiptId,
    required this.onClose,
  });
  @override
  State<GoodsReceiptDetailScreen> createState() =>
      _GoodsReceiptDetailScreenState();
}

class _GoodsReceiptDetailScreenState extends State<GoodsReceiptDetailScreen> {
  late Future<GoodsReceiptResponseModel> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<PurchasesProvider>().loadDetail(widget.receiptId);
  }

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

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static const _secondary = TextStyle(color: AppTheme.textSecondary);

  String _date(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '—' : _dateFormat.format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Về danh sách phiếu nhập',
                  onPressed: _busy ? null : widget.onClose,
                  icon: const Icon(Symbols.arrow_back, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chi tiết phiếu nhập',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_busy) const LinearProgressIndicator(),
            FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text('Không tải được phiếu: ${snapshot.error}'),
                      TextButton(
                        onPressed: () => setState(_load),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
                }
                return _receipt(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _receipt(GoodsReceiptResponseModel receipt) {
    final info = _section('Thông tin phiếu', [
      _pair('Nhà cung cấp', receipt.supplierName),
      _pair('Ngày tạo', _date(receipt.createdAt)),
      _pair('Người tạo', receipt.createdBy ?? '—'),
      if (receipt.postedBy != null) _pair('Người nhập kho', receipt.postedBy!),
      if (receipt.note?.isNotEmpty == true) _pair('Ghi chú', receipt.note!),
    ]);
    final totals = _section('Thanh toán', [
      _pair('Tổng tiền hàng', money(receipt.totalAmount)),
      if (receipt.returnedAmount > 0)
        _pair('Giảm trừ hàng trả', '-${money(receipt.returnedAmount)}'),
      _pair('Đã thanh toán', money(receipt.paidAmount)),
      if (receipt.supplierRefundDue > 0)
        _pair('Nhà cung cấp cần hoàn', money(receipt.supplierRefundDue)),
      if (receipt.remainingAmount > 0)
        _pair('Còn nợ', money(receipt.remainingAmount), emphasized: true),
    ]);
    final actions = _actions(receipt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              receipt.code,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              receiptStatuses[receipt.status] ?? receipt.status,
              style: _secondary,
            ),
            if (receipt.status != 'CANCELLED')
              Text(
                paymentStatuses[receipt.paymentStatus] ?? receipt.paymentStatus,
                style: _secondary,
              ),
          ],
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 800
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    Expanded(child: totals),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [info, const SizedBox(height: 16), totals],
                ),
        ),
        const SizedBox(height: 16),
        _section('Hàng nhập', [
          if (receipt.items.isEmpty)
            const Text('Phiếu chưa có sản phẩm', style: _secondary),
          for (final item in receipt.items)
            _entry('${item["productName"]}', [
              '${item["sizeName"]} / ${item["colorName"]} · SKU ${item["sku"]}',
              '${item["quantity"]} × ${money(item["unitCost"] as num)}',
              if ((item['returnedQuantity'] as int? ?? 0) > 0)
                'Đã trả nhà cung cấp: ${item["returnedQuantity"]}',
            ], amount: money(item['subtotal'] as num)),
        ]),
        const SizedBox(height: 16),
        _section('Lịch sử thanh toán và hoàn tiền', [
          if (receipt.payments.isEmpty && receipt.refunds.isEmpty)
            const Text('Chưa có giao dịch', style: _secondary),
          for (final payment in receipt.payments)
            _transaction('Thanh toán', payment, 'paidAt'),
          for (final refund in receipt.refunds)
            _transaction('Nhận tiền hoàn', refund, 'createdAt'),
        ]),
        const SizedBox(height: 16),
        _section('Lịch sử trả nhà cung cấp', [
          if (receipt.returns.isEmpty)
            const Text('Chưa có hàng trả', style: _secondary),
          for (final returned in receipt.returns)
            _entry('${returned["code"]}', [
              '${_date(returned["createdAt"])} · ${returned["createdBy"] ?? "—"}',
              'Lý do: ${returned["reason"]}',
              _returnedItems(receipt, returned['items'] as List),
            ], amount: money(returned['amount'] as num)),
        ]),
      ],
    );
  }

  String _returnedItems(GoodsReceiptResponseModel receipt, List items) {
    final skuByVariant = {
      for (final item in receipt.items) item['variantId']: item['sku'],
    };
    return items
        .map((item) {
          final variantId = item['variantId'];
          final sku = skuByVariant[variantId];
          return '${sku ?? 'Biến thể #$variantId'} × ${item['quantity']}';
        })
        .join(', ');
  }

  Widget _transaction(
    String title,
    Map<String, dynamic> entry,
    String dateKey,
  ) {
    final method = entry['paymentMethod'] == 'CASH'
        ? 'Tiền mặt'
        : 'Chuyển khoản';
    final note = entry['note']?.toString().trim() ?? '';
    return _entry(title, [
      '${_date(entry[dateKey])} · ${entry["createdBy"] ?? "—"} · $method',
      if (note.isNotEmpty) note,
    ], amount: money(entry['amount'] as num));
  }

  Widget _section(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppTheme.borderLight),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        for (final row in rows) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: row,
          ),
        ],
      ],
    ),
  );

  Widget _pair(String label, String value, {bool emphasized = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: _secondary)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: emphasized
              ? const TextStyle(fontWeight: FontWeight.w600)
              : null,
        ),
      ),
    ],
  );

  Widget _entry(String title, List<String> details, {required String amount}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                for (final detail in details)
                  if (detail.isNotEmpty) Text(detail, style: _secondary),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );

  List<Widget> _actions(GoodsReceiptResponseModel receipt) {
    final isAdmin = context.watch<AuthProvider>().hasRole('ADMIN');
    final posted = receipt.status == 'POSTED';
    return [
      if (receipt.status == 'DRAFT') ...[
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _openForm(GoodsReceiptFormDialog(receipt: receipt)),
          child: const Text('Sửa phiếu nháp'),
        ),
        if (isAdmin)
          FilledButton(
            onPressed: _busy ? null : () => _action('post'),
            child: const Text('Xác nhận nhập kho'),
          ),
      ],
      if (posted && isAdmin && receipt.remainingAmount > 0)
        FilledButton(
          onPressed: _busy
              ? null
              : () => _openForm(SupplierPaymentDialog(receipt: receipt)),
          child: const Text('Thanh toán cho NCC'),
        ),
      if (posted &&
          receipt.items.any(
            (item) =>
                (item['quantity'] as int) >
                (item['returnedQuantity'] as int? ?? 0),
          ))
        OutlinedButton(
          onPressed: _busy ? null : () => _returnToSupplier(receipt),
          child: const Text('Trả hàng nhà cung cấp'),
        ),
      if (posted && isAdmin && receipt.supplierRefundDue > 0)
        FilledButton(
          onPressed: _busy
              ? null
              : () => _openForm(
                  SupplierPaymentDialog(receipt: receipt, isRefund: true),
                ),
          child: const Text('Ghi nhận đã nhận tiền hoàn'),
        ),
      if (receipt.status != 'CANCELLED' &&
          receipt.paidAmount == 0 &&
          receipt.returns.isEmpty)
        OutlinedButton(
          onPressed: _busy ? null : () => _action('cancel'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
          child: const Text('Hủy phiếu'),
        ),
    ];
  }

  Future<void> _openForm(Widget dialog) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => dialog,
    );
    if (saved == true && mounted) setState(_load);
  }
}
