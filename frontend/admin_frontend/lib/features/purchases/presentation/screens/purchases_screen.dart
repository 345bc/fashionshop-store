import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/warehouse_table.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/models/goods_receipt_response_model.dart';
import '../providers/purchases_provider.dart';
import '../dialogs/goods_receipt_form_dialog.dart';
import '../dialogs/goods_receipt_detail_dialog.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PurchasesProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<PurchasesProvider>(
    builder: (context, p, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureHeader(
            title: 'Nhập hàng',
            subtitle: 'Phiếu nhập và thanh toán nhà cung cấp',
            actionLabel: 'Tạo phiếu nhập',
            actionIcon: Icons.add,
            onActionPressed: () => showDialog(
              context: context,
              builder: (_) => const GoodsReceiptFormDialog(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Công nợ phiếu đã nhập trên trang: ${money(p.items.where((r) => r.status == "POSTED").fold<num>(0, (n, r) => n + r.remainingAmount))}',
          ),
          const SizedBox(height: 24),
          FeatureToolbar(
            searchHint: 'Tìm mã phiếu hoặc nhà cung cấp...',
            initialSearchText: p.query,
            onSearchChanged: p.search,
            filterWidget: Row(
              children: [
                DropdownButton<String>(
                  value: p.status,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả trạng thái'),
                    ),
                    ...receiptStatuses.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (v) => p.filter(v ?? 'all'),
                ),
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: p.loadItems,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WarehouseTable(
            headers: const [
              'PHIẾU NHẬP',
              'NHÀ CUNG CẤP',
              'TỔNG TIỀN',
              'CÒN NỢ',
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
  Widget _row(GoodsReceiptResponseModel r) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => GoodsReceiptDetailDialog(receiptId: r.id),
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
                    r.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                r.supplierName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(money(r.totalAmount))),
            Expanded(
              child: Text(
                r.status == 'POSTED' ? money(r.remainingAmount) : '—',
              ),
            ),
            Expanded(child: Text(receiptStatuses[r.status] ?? r.status)),
            Expanded(
              child: Text(
                r.status == 'CANCELLED'
                    ? '—'
                    : paymentStatuses[r.paymentStatus] ?? r.paymentStatus,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
