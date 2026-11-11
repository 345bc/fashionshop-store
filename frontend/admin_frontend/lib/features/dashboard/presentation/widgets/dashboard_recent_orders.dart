import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../data/models/analytics_models.dart';
import '../../data/repositories/analytics_repository.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_overview_charts.dart';

class DashboardRecentOrders extends StatefulWidget {
  final DashboardProvider provider;
  final ValueChanged<String>? onNavigate;
  const DashboardRecentOrders({
    super.key,
    required this.provider,
    this.onNavigate,
  });
  @override
  State<DashboardRecentOrders> createState() => _DashboardRecentOrdersState();
}

class _DashboardRecentOrdersState extends State<DashboardRecentOrders> {
  late Future<List<Map<String, dynamic>>> _future;
  late DateTime _start, _end;
  String? _status;
  static const statuses = [
    'PENDING',
    'CONFIRMED',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
    'RETURNED',
  ];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardRecentOrders oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_start != widget.provider.start ||
        _end != widget.provider.end ||
        oldWidget.provider != widget.provider) {
      _load();
    }
  }

  void _load() {
    final p = widget.provider;
    _start = p.start;
    _end = p.end;
    if (p.isDemo) {
      final orders =
          p.data.orders
              .where(
                (o) =>
                    !o.createdAt.isBefore(_start) &&
                    o.createdAt.isBefore(_end.add(const Duration(days: 1))) &&
                    (_status == null || o.status == _status),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _future = Future.value(
        orders.take(5).map((o) {
          final products = AnalyticsRepository.products.where(
            (product) => product.id == o.productId,
          );
          final product = products.isEmpty ? null : products.first;
          return <String, dynamic>{
            'code': o.code,
            'status': o.status,
            'total': o.total,
            'productName': product?.name,
            'categoryName': product?.category,
            'itemCount': 1,
          };
        }).toList(),
      );
    } else {
      _future = p.data
          .fetch({
            'start': _start.toIso8601String().substring(0, 10),
            'end': _end.toIso8601String().substring(0, 10),
            'section': 'orders',
            'page': 0,
            'size': 5,
            if (_status != null) 'status': _status,
          })
          .then(
            (result) => (result['recentOrders'] as List? ?? [])
                .map((row) => Map<String, dynamic>.from(row))
                .toList(),
          );
    }
  }

  @override
  Widget build(BuildContext context) => overviewCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Text(
              'Đơn hàng gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Lọc trạng thái đơn hàng',
                  position: PopupMenuPosition.under,
                  initialValue: _status ?? 'ALL',
                  onSelected: (value) => setState(() {
                    _status = value == 'ALL' ? null : value;
                    _load();
                  }),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'ALL',
                      child: Text('Tất cả trạng thái'),
                    ),
                    for (final status in statuses)
                      PopupMenuItem(
                        value: status,
                        child: Text(orderStatusLabel(status)),
                      ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD0D5DD)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.tune, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          _status == null ? 'Lọc' : orderStatusLabel(_status!),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: widget.onNavigate == null
                      ? null
                      : () => widget.onNavigate!('/orders'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text('Không tải được đơn hàng gần đây.'),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'Chưa có đơn hàng trong bộ lọc đã chọn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxWidth < 540;
                return Column(
                  children: [
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            for (final item in [
                              ('Sản phẩm', 5),
                              ('Danh mục', 3),
                              ('Tổng tiền', 3),
                              ('Trạng thái', 3),
                            ])
                              Expanded(
                                flex: item.$2,
                                child: Text(
                                  item.$1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    for (final row in rows)
                      InkWell(
                        onTap: widget.onNavigate == null
                            ? null
                            : () => widget.onNavigate!('/orders'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFF0F2F5)),
                            ),
                          ),
                          child: compact
                              ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _product(row)),
                                        const SizedBox(width: 8),
                                        _statusBadge(
                                          row['status']?.toString() ?? '',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row['categoryName']?.toString() ??
                                                '—',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          reportMoney(
                                            (row['total'] as num? ?? 0).round(),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(flex: 5, child: _product(row)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        row['categoryName']?.toString() ?? '—',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        reportMoney(
                                          (row['total'] as num? ?? 0).round(),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _statusBadge(
                                          row['status']?.toString() ?? '',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    ),
  );

  Widget _product(Map<String, dynamic> row) {
    final url = row['imageUrl']?.toString();
    final code = row['code']?.toString() ?? '';
    final count = (row['itemCount'] as num? ?? 1).toInt();
    return Tooltip(
      message: code,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 48,
              height: 56,
              color: const Color(0xFFF5F6F8),
              child: url == null || url.isEmpty
                  ? const Icon(
                      Symbols.image,
                      size: 22,
                      color: AppTheme.textMuted,
                    )
                  : Image.network(
                      Uri.parse(url).hasScheme
                          ? url
                          : '${Uri.parse(ApiEndpoints.baseUrl).origin}${url.startsWith('/') ? '' : '/'}$url',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Symbols.broken_image,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['productName']?.toString() ?? 'Đơn hàng',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  count > 1 ? '+${count - 1} sản phẩm khác' : '1 sản phẩm',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'DELIVERED'
        ? const Color(0xFF039855)
        : status == 'CANCELLED'
        ? const Color(0xFFD92D20)
        : status == 'CONFIRMED'
        ? const Color(0xFF3563D9)
        : const Color(0xFFB7791F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
