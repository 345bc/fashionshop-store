import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/models/order_response_model.dart';
import '../../data/models/return_order_summary.dart';
import '../providers/orders_provider.dart';
import 'order_detail_dialog.dart';

class ReturnManagementDialog extends StatefulWidget {
  const ReturnManagementDialog({super.key});
  @override
  State<ReturnManagementDialog> createState() => _ReturnManagementDialogState();
}

class _ReturnManagementDialogState extends State<ReturnManagementDialog> {
  List<ReturnOrderSummary> _items = [];
  int _page = 0, _total = 0, _request = 0;
  String _query = '', _status = 'ALL';
  String? _error;
  bool _loading = true;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<OrdersProvider>().returnOrders(
        page: _page,
        query: _query,
        status: _status,
      );
      if (!mounted || request != _request) return;
      final lastPage = result.total == 0 ? 0 : (result.total - 1) ~/ 10;
      if (_page > lastPage) {
        _page = lastPage;
        await _load();
        return;
      }
      setState(() {
        _items = result.items;
        _total = result.total;
        _loading = false;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  void _search(String value) {
    _searchTimer?.cancel();
    _query = value.trim();
    _page = 0;
    _request++;
    setState(() {
      _loading = true;
      _items = [];
    });
    _searchTimer = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _openOrder(ReturnOrderSummary order) async {
    final provider = context.read<OrdersProvider>();
    await showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: OrderDetailDialog(orderId: order.orderId),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => ZellaDialog(
    width: 860,
    height: math.min(MediaQuery.sizeOf(context).height * .86, 740),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Symbols.assignment_return, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Quản lý hoàn hàng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Symbols.close),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Chọn đơn để duyệt yêu cầu, nhận hàng trả hoặc ghi nhận hoàn tiền.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              onChanged: _search,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Symbols.search, size: 20),
                hintText: 'Mã đơn, người nhận, số điện thoại',
                border: OutlineInputBorder(),
              ),
            );
            final filter = DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _status,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'ALL',
                  child: Text('Tất cả yêu cầu'),
                ),
                ...returnStatuses.entries.map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                _searchTimer?.cancel();
                _status = value;
                _page = 0;
                _load();
              },
            );
            if (constraints.maxWidth < 600) {
              return Column(
                children: [search, const SizedBox(height: 10), filter],
              );
            }
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                SizedBox(width: 200, child: filter),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '$_total đơn có yêu cầu',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có đơn hàng có yêu cầu phù hợp.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) => _orderRow(_items[index]),
                ),
        ),
        const Divider(height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: _loading || _page == 0
                  ? null
                  : () {
                      _page--;
                      _load();
                    },
              icon: const Icon(Symbols.chevron_left),
            ),
            Text(
              '${_page + 1} / ${math.max(1, (_total / 10).ceil())}',
              style: const TextStyle(fontSize: 12),
            ),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: _loading || (_page + 1) * 10 >= _total
                  ? null
                  : () {
                      _page++;
                      _load();
                    },
              icon: const Icon(Symbols.chevron_right),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _orderRow(ReturnOrderSummary order) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _openOrder(order),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${order.recipientName} · ${order.recipientPhone}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: order.statuses
                        .map(
                          (status) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'PENDING'
                                  ? Colors.amber.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              returnStatuses[status] ?? status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: status == 'PENDING'
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${order.totalRequests} yêu cầu · ${DateFormat('dd/MM/yyyy HH:mm').format(order.latestRequestAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(order.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (order.pendingRequests > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${order.pendingRequests} chờ duyệt',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Symbols.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}
