import '../../../../widgets/common/pagination_footer.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/inventory_response_model.dart';
import '../providers/inventory_provider.dart';

class InventoryDetailDialog extends StatefulWidget {
  final InventoryResponseModel item;
  const InventoryDetailDialog({super.key, required this.item});
  @override
  State<InventoryDetailDialog> createState() => _InventoryDetailDialogState();
}

class _InventoryDetailDialogState extends State<InventoryDetailDialog> {
  late Future<Map<String, dynamic>> _future;
  int _page = 0;
  int _total = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<InventoryProvider>().history(
      widget.item.variantId,
      page: _page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: size.width * 2 / 3,
      height: size.height * 2 / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch sử kho',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(widget.item.label),
          Text('Nhà cung cấp: ${widget.item.supplierName}'),
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
                final data = snapshot.data!;
                final rows = (data['content'] as List)
                    .cast<Map<String, dynamic>>();
                _total = (data['totalElements'] as num).toInt();
                if (rows.isEmpty) {
                  return const Center(child: Text('Chưa có biến động kho'));
                }
                const labels = {
                  'OPENING': 'Tồn đầu kỳ',
                  'RECEIPT': 'Nhập hàng',
                  'RECEIPT_REVERSAL': 'Đảo phiếu nhập',
                  'ADJUSTMENT': 'Điều chỉnh',
                  'ORDER_RESERVE': 'Giữ hàng cho đơn',
                  'ORDER_RELEASE': 'Giải phóng hàng đã giữ',
                  'ORDER_SHIP': 'Xuất kho giao khách',
                  'CUSTOMER_RETURN': 'Nhận hàng khách trả',
                  'RETURN_DAMAGED': 'Nhận hàng trả hỏng',
                  'SUPPLIER_RETURN': 'Trả nhà cung cấp',
                };
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final m in rows)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${labels[m["movementType"]] ?? m["movementType"]} • ${m["referenceCode"]}',
                              ),
                              subtitle: Text(
                                'Tồn: ${m["beforeQuantity"]} → ${m["afterQuantity"]}'
                                '${m["beforeReserved"] == null ? "" : " • Đã giữ: ${m["beforeReserved"]} → ${m["afterReserved"]}"}'
                                ' • ${m["createdBy"] ?? "Hệ thống"} • '
                                '${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.parse(m["createdAt"] as String).toLocal())}\n${m["reason"] ?? ""}',
                              ),
                              trailing: Text(
                                '${(m["quantityChange"] as int) > 0 ? "+" : ""}${m["quantityChange"]}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    PaginationFooter(
                      currentPage: _page,
                      totalPages: _total == 0 ? 1 : (_total / 15).ceil(),
                      totalElements: _total,
                      pageSize: 15,
                      onPageChanged: (page) => setState(() {
                        _page = page;
                        _load();
                      }),
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
