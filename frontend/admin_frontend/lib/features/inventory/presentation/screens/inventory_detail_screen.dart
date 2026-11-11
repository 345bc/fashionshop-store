import 'package:material_symbols_icons/symbols.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../data/models/inventory_response_model.dart';
import '../providers/inventory_provider.dart';

class InventoryDetailScreen extends StatefulWidget {
  final InventoryResponseModel item;
  final VoidCallback onClose;

  const InventoryDetailScreen({
    super.key,
    required this.item,
    required this.onClose,
  });
  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  static const _pageSize = 15;
  static const _movementLabels = {
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
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  late Future<Map<String, dynamic>> _future;
  int _page = 0;
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
    final item = widget.item;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Về danh sách tồn kho',
                  onPressed: widget.onClose,
                  icon: const Icon(Symbols.arrow_back, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chi tiết kho',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 24,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Kích cỡ / Màu: ${item.sizeName} / ${item.colorName}',
                      ),
                      Text('Danh mục: ${item.categoryName}'),
                      Text('Nhà cung cấp: ${item.supplierName}'),
                      Text('Giá vốn: ${money(item.costPrice)}'),
                      Text(
                        item.isActive
                            ? 'Trạng thái bán: Đang bán'
                            : 'Trạng thái bán: Ngừng bán',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 40,
                    runSpacing: 16,
                    children: [
                      _quantity('Tồn kho', item.stockQuantity),
                      _quantity('Đã giữ', item.reservedQuantity),
                      _quantity('Có thể bán', item.availableQuantity),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Lịch sử kho',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  FutureBuilder(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
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
                      final total = (data['totalElements'] as num).toInt();
                      if (rows.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Chưa có biến động kho')),
                        );
                      }
                      return Column(
                        children: [
                          for (final movement in rows) ...[
                            _movementRow(movement),
                            const Divider(height: 1),
                          ],
                          LayoutBuilder(
                            builder: (context, box) => SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: box.maxWidth,
                                ),
                                child: PaginationFooter(
                                  currentPage: _page,
                                  totalPages: (total / _pageSize).ceil(),
                                  totalElements: total,
                                  pageSize: _pageSize,
                                  onPageChanged: (page) => setState(() {
                                    _page = page;
                                    _load();
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppTheme.borderLight),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  Widget _quantity(String label, int value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 4),
      Text(
        '$value',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _movementRow(Map<String, dynamic> movement) {
    final type = movement['movementType']?.toString() ?? '—';
    final title = _movementLabels[type] ?? type;
    final reference = movement['referenceCode']?.toString().trim() ?? '';
    final reason = movement['reason']?.toString().trim() ?? '';
    final date = DateTime.tryParse(movement['createdAt']?.toString() ?? '');
    final author = movement['createdBy'] ?? 'Hệ thống';
    final delta = (movement['quantityChange'] as num).toInt();
    const secondary = TextStyle(fontSize: 12, color: AppTheme.textSecondary);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (reference.isNotEmpty) Text(reference, style: secondary),
        if (reason.isNotEmpty && reason != title)
          Text(reason, style: secondary),
      ],
    );
    final quantities = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tồn: ${movement['beforeQuantity']} → ${movement['afterQuantity']}',
        ),
        if (movement['beforeReserved'] != null)
          Text(
            'Đã giữ: ${movement['beforeReserved']} → ${movement['afterReserved']}',
            style: secondary,
          ),
      ],
    );
    final performedBy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (date != null) Text(_dateFormat.format(date.toLocal())),
        Text('$author', style: secondary),
      ],
    );
    final change = Text(
      delta > 0 ? '+$delta' : '$delta',
      textAlign: TextAlign.end,
      semanticsLabel: 'Thay đổi tồn kho: $delta',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: delta > 0
            ? AppTheme.success
            : delta < 0
            ? AppTheme.danger
            : AppTheme.textSecondary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 650;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: wide
                    ? details
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 8),
                          quantities,
                          const SizedBox(height: 8),
                          performedBy,
                        ],
                      ),
              ),
              if (wide) ...[
                const SizedBox(width: 20),
                Expanded(flex: 2, child: quantities),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: performedBy),
              ],
              const SizedBox(width: 12),
              SizedBox(width: 64, child: change),
            ],
          );
        },
      ),
    );
  }
}
