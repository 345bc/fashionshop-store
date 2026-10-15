
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/common/feature_header.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../../widgets/common/warehouse_table.dart';
import '../../data/models/inventory_response_model.dart';
import '../providers/inventory_provider.dart';
import '../dialogs/inventory_detail_dialog.dart';
import '../dialogs/inventory_adjustment_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InventoryProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<InventoryProvider>(
    builder: (context, p, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureHeader(
            showAction: false,
            title: 'Tồn kho',
            subtitle: 'Quản lý tồn theo biến thể sản phẩm',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Text('SKU: ${p.totalElements}'),
              Text(
                'Tồn trên trang: ${p.items.fold<int>(0, (n, i) => n + i.stockQuantity)}',
              ),
              Text(
                'Đã giữ trên trang: ${p.items.fold<int>(0, (n, i) => n + i.reservedQuantity)}',
              ),
              Text(
                'Có thể bán trên trang: ${p.items.fold<int>(0, (n, i) => n + i.availableQuantity)}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          FeatureToolbar(
            searchHint: 'Tìm theo SKU, tên SP, danh mục, kích cỡ hoặc màu sắc',
            initialSearchText: p.query,
            onSearchChanged: p.search,
            filterWidget: FilterDropdown<String>(
              label: 'Trạng thái',
              searchHint: 'Tìm trạng thái',
              value: p.status,
              defaultValue: 'all',
              options: const [
                FilterOption(
                  value: 'available',
                  label: 'Còn hàng',
                  icon: Symbols.check_circle,
                  iconColor: AppTheme.success,
                ),
                FilterOption(
                  value: 'out',
                  label: 'Hết hàng khả dụng',
                  icon: Symbols.cancel,
                ),
              ],
              onChanged: (v) => p.filter(v),
            ),
          ),
          const SizedBox(height: 24),
          WarehouseTable(
            flexes: const [3, 2, 1, 1, 1, 1],
            headers: const [
              'SẢN PHẨM / SKU',
              'SIZE / MÀU',
              'TỒN / ĐÃ GIỮ',
              'CÓ THỂ BÁN',
              'GIÁ VỐN',
              'THAO TÁC',
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
  Widget _row(InventoryResponseModel i) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => InventoryDetailDialog(item: i),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      i.sku,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${i.sizeName} / ${i.colorName}'),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${i.stockQuantity} / ${i.reservedQuantity}'),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${i.availableQuantity}',
                  style: TextStyle(
                    color: i.availableQuantity == 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(money(i.costPrice)),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Lịch sử kho',
                    icon: const Icon(Symbols.history),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => InventoryDetailDialog(item: i),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Điều chỉnh tồn',
                    icon: const Icon(Symbols.tune),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => InventoryAdjustmentDialog(item: i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
