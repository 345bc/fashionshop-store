import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'pagination_footer.dart';

class WarehouseTable extends StatelessWidget {
  final List<String> headers;
  final List<Widget> rows;
  final bool loading;
  final String? error;
  final int page, total, pageSize;
  final ValueChanged<int> onPage;
  final VoidCallback onRetry;
  const WarehouseTable({
    super.key,
    required this.headers,
    required this.rows,
    required this.loading,
    this.error,
    required this.page,
    required this.total,
    required this.pageSize,
    required this.onPage,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppTheme.borderLight),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              for (final label in headers)
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (rows.isEmpty && !loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Text('Không có dữ liệu'),
          ),
        for (final row in rows) ...[row, const Divider(height: 1)],
        PaginationFooter(
          currentPage: page,
          totalPages: total == 0 ? 1 : (total / pageSize).ceil(),
          totalElements: total,
          pageSize: pageSize,
          onPageChanged: onPage,
        ),
      ],
    ),
  );
}
