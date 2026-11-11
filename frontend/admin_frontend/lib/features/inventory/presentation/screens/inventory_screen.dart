import 'dart:async';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../../widgets/common/warehouse_table.dart';
import '../../data/models/inventory_response_model.dart';
import '../providers/inventory_provider.dart';
import '../dialogs/inventory_adjustment_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<({int lowStock, int outOfStock})> _alerts;
  late final Timer _alertTimer;

  @override
  void initState() {
    super.initState();
    _alerts = context.read<InventoryProvider>().stockAlerts();
    _alertTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshAlerts(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InventoryProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _alertTimer.cancel();
    super.dispose();
  }

  void _refreshAlerts() {
    setState(() => _alerts = context.read<InventoryProvider>().stockAlerts());
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
          FutureBuilder(
            future: _alerts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _refreshAlerts,
                    child: const Text('Không tải được cảnh báo kho. Thử lại'),
                  ),
                );
              }
              final alerts = snapshot.data;
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Sắp hết hàng: ${alerts?.lowStock ?? '…'}'),
                    selected: p.status == 'low' && p.query.isEmpty,
                    onSelected: (selected) =>
                        p.filter(selected ? 'low' : 'all', clearSearch: true),
                    avatar: const Icon(
                      Symbols.warning,
                      color: AppTheme.warning,
                    ),
                  ),
                  FilterChip(
                    label: Text('Hết hàng: ${alerts?.outOfStock ?? '…'}'),
                    selected: p.status == 'out' && p.query.isEmpty,
                    onSelected: (selected) =>
                        p.filter(selected ? 'out' : 'all', clearSearch: true),
                    avatar: const Icon(Symbols.cancel, color: AppTheme.danger),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FeatureToolbar(
            searchHint: 'Tìm theo tên sản phẩm, danh mục, kích cỡ hoặc màu sắc',
            initialSearchText: p.query,
            onSearchChanged: p.search,
            filterWidget: FilterDropdown<String>(
              label: 'Trạng thái',
              searchHint: 'Tìm trạng thái',
              value: p.status,
              defaultValue: 'all',
              options: const [
                FilterOption(
                  value: 'low',
                  label: 'Sắp hết hàng',
                  icon: Symbols.warning,
                  iconColor: AppTheme.warning,
                ),
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
            flexes: const [3, 2, 1, 1, 1],
            headers: const [
              'SẢN PHẨM',
              'SIZE / MÀU',
              'TỒN / ĐÃ GIỮ',
              'CÓ THỂ BÁN',
              '',
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
  Widget _row(InventoryResponseModel item) => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${item.sizeName} / ${item.colorName}'),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${item.stockQuantity} / ${item.reservedQuantity}'),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${item.availableQuantity}',
              style: TextStyle(
                color: item.availableQuantity <= 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 48,
              child: ActionMenu(
                items: const [
                  ActionMenuItem(
                    value: 'detail',
                    label: 'Chi tiết kho',
                    icon: Symbols.visibility,
                  ),
                  ActionMenuItem(
                    value: 'adjust',
                    label: 'Điều chỉnh tồn',
                    icon: Symbols.tune,
                  ),
                ],
                onSelected: (action) async {
                  if (action == 'detail') {
                    MainScreen.of(context)
                        .navigate('/inventory/detail', {'item': item});
                  } else if (action == 'adjust') {
                    final adjusted = await showDialog<bool>(
                      context: context,
                      builder: (_) => InventoryAdjustmentDialog(item: item),
                    );
                    if (mounted && adjusted == true) _refreshAlerts();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
