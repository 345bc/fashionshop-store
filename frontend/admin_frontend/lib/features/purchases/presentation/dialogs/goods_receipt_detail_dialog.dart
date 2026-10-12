import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
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

  // --- UI Helpers ---

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
      case 'POSTED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      case 'DRAFT':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'PAID':
        return AppTheme.success;
      case 'UNPAID':
        return AppTheme.danger;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  // --- Layout Builders ---

  Widget _buildLeftColumn(GoodsReceiptResponseModel r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Danh sách sản phẩm nhập', Symbols.inventory_2),
        _buildItemsList(r),
        const SizedBox(height: 24),

        _buildSectionHeader('Lịch sử thanh toán & Hoàn tiền', Symbols.payments),
        _buildPaymentsList(r),
        const SizedBox(height: 24),

        _buildSectionHeader(
          'Lịch sử trả nhà cung cấp',
          Symbols.assignment_return,
        ),
        _buildReturnsList(r),
      ],
    );
  }

  Widget _buildRightColumn(GoodsReceiptResponseModel r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _statusBadge(
              receiptStatuses[r.status] ?? r.status,
              _getStatusColor(r.status),
            ),
            const SizedBox(width: 8),
            _statusBadge(
              paymentStatuses[r.paymentStatus] ?? r.paymentStatus,
              _getPaymentStatusColor(r.paymentStatus),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Thông tin phiếu nhập', Symbols.info),
        _buildReceiptInfo(r),
        const SizedBox(height: 24),

        _buildSectionHeader('Tổng kết tài chính', Symbols.account_balance),
        _buildFinancialSummary(r),
        const SizedBox(height: 24),

        _buildSectionHeader('Thao tác', Symbols.touch_app),
        _buildActions(r),
      ],
    );
  }

  Widget _buildItemsList(GoodsReceiptResponseModel r) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: r.items.asMap().entries.map((e) {
          final i = e.value;
          final isLast = e.key == r.items.length - 1;
          final returnedQty = i['returnedQuantity'] as int? ?? 0;
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
                            '${i["productName"]} — ${i["sizeName"]} / ${i["colorName"]}',
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
                                'Đã trả nhà cung cấp: $returnedQty',
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
                          '${i["quantity"]} × ${money(i["unitCost"] as num)}',
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

  Widget _buildPaymentsList(GoodsReceiptResponseModel r) {
    if (r.payments.isEmpty && r.refunds.isEmpty) {
      return const Text(
        'Chưa có giao dịch',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...r.payments.map(
            (p) => Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.surface,
                    child: Icon(
                      Symbols.arrow_outward,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text('Đã thanh toán: ${money(p["amount"] as num)}'),
                  subtitle: Text(
                    '${p["paymentMethod"] == "CASH" ? "Tiền mặt" : "Chuyển khoản"} • ${p["createdBy"] ?? "—"}\n'
                    '${p["paidAt"]} ${p["note"] != null && p["note"].toString().isNotEmpty ? " • ${p["note"]}" : ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          ...r.refunds.map(
            (f) => Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.surface,
                    child: Icon(
                      Symbols.arrow_downward,
                      size: 16,
                      color: AppTheme.success,
                    ),
                  ),
                  title: Text(
                    'Đã nhận tiền hoàn: ${money(f["amount"] as num)}',
                  ),
                  subtitle: Text(
                    '${f["createdBy"]} • ${f["createdAt"]}\n'
                    '${f["note"] ?? ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsList(GoodsReceiptResponseModel r) {
    if (r.returns.isEmpty) {
      return const Text(
        'Chưa có hàng trả',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: r.returns.asMap().entries.map((e) {
          final d = e.value;
          final isLast = e.key == r.returns.length - 1;
          return Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surface,
                  child: Icon(
                    Symbols.assignment_return,
                    size: 16,
                    color: AppTheme.danger,
                  ),
                ),
                title: Text(
                  '${d["code"]} • Giá trị: ${money(d["amount"] as num)}',
                ),
                subtitle: Text(
                  'Lý do: ${d["reason"]} • ${d["createdBy"]}\n'
                  'Sản phẩm: ${(d["items"] as List).map((i) => "SKU ${i["variantId"]}: ${i["quantity"]}").join(", ")}',
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

  Widget _buildReceiptInfo(GoodsReceiptResponseModel r) {
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
          _infoRow(Symbols.storefront, 'Nhà cung cấp', r.supplierName),
          const SizedBox(height: 12),
          _infoRow(Symbols.person, 'Tạo bởi', r.createdBy ?? "—"),
          if (r.postedBy != null) ...[
            const SizedBox(height: 12),
            _infoRow(Symbols.inventory, 'Nhập kho bởi', r.postedBy!),
          ],
          if (r.note?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _infoRow(Symbols.notes, 'Ghi chú', r.note!),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(GoodsReceiptResponseModel r) {
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
                'Tổng tiền hàng',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(money(r.totalAmount)),
            ],
          ),
          if (r.returnedAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giảm trừ hàng trả',
                  style: TextStyle(color: AppTheme.danger),
                ),
                Text(
                  '-${money(r.returnedAmount)}',
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đã thanh toán',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(money(r.paidAmount)),
            ],
          ),
          if (r.supplierRefundDue > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NCC cần hoàn lại',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  money(r.supplierRefundDue),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (r.remainingAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Còn nợ NCC',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  money(r.remainingAmount),
                  style: const TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(GoodsReceiptResponseModel r) {
    List<Widget> actions = [];

    if (r.status == 'DRAFT') {
      actions.add(
        _actionButton('Sửa phiếu nháp', Symbols.edit, Colors.orange, () async {
          final saved = await showDialog<bool>(
            context: context,
            builder: (_) => GoodsReceiptFormDialog(receipt: r),
          );
          if (saved == true && mounted) setState(_load);
        }, isOutlined: true),
      );
      actions.add(
        _actionButton(
          'Xác nhận nhập kho',
          Symbols.inventory,
          AppTheme.primary,
          () => _action('post'),
        ),
      );
    }

    if (r.status == 'POSTED' && r.remainingAmount > 0) {
      actions.add(
        _actionButton(
          'Thanh toán cho NCC',
          Symbols.payments,
          AppTheme.success,
          () async {
            final paid = await showDialog<bool>(
              context: context,
              builder: (_) => SupplierPaymentDialog(receipt: r),
            );
            if (paid == true && mounted) setState(_load);
          },
        ),
      );
    }

    if (r.status == 'POSTED' &&
        r.items.any(
          (i) => (i['quantity'] as int) > (i['returnedQuantity'] as int? ?? 0),
        )) {
      actions.add(
        _actionButton(
          'Trả hàng nhà cung cấp',
          Symbols.assignment_return,
          Colors.orange,
          () => _returnToSupplier(r),
          isOutlined: true,
        ),
      );
    }

    if (r.status == 'POSTED' && r.supplierRefundDue > 0) {
      actions.add(
        _actionButton(
          'Ghi nhận đã nhận tiền hoàn',
          Symbols.move_to_inbox,
          AppTheme.success,
          () async {
            final done = await showDialog<bool>(
              context: context,
              builder: (_) => SupplierPaymentDialog(receipt: r, isRefund: true),
            );
            if (done == true && mounted) setState(_load);
          },
        ),
      );
    }

    if (r.status != 'CANCELLED' && r.paidAmount == 0 && r.returns.isEmpty) {
      actions.add(
        _actionButton(
          'Hủy phiếu',
          Symbols.cancel,
          AppTheme.danger,
          () => _action('cancel'),
          isOutlined: true,
        ),
      );
    }

    if (actions.isEmpty) {
      return Container(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions,
    );
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: size.width * 2 / 3,
      height: size.height * .85,
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
                        Text('Không tải được phiếu: ${snapshot.error}'),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final r = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            r.code,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Ngày tạo: ${DateFormat("dd/MM/yyyy HH:mm").format(r.createdAt)}',
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
                            Expanded(flex: 5, child: _buildLeftColumn(r)),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildRightColumn(r)),
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
