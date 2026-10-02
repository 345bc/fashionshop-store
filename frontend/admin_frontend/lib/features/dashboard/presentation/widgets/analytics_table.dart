import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../providers/dashboard_provider.dart';

class AnalyticsTable extends StatelessWidget {
  final DashboardProvider provider;
  const AnalyticsTable({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final table = provider.table;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              table.note,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          if (table.rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text('Không có dữ liệu trong bộ lọc đã chọn.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: c.maxWidth < table.columns.length * 160
                      ? table.columns.length * 160.0
                      : c.maxWidth,
                  child: Column(
                    children: [
                      DataTable(
                        showCheckboxColumn: false,
                        headingRowHeight: 60,
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 92,
                        columnSpacing: 20,
                        columns: [
                          for (final column in table.columns)
                            DataColumn(label: Flexible(child: Text(column))),
                        ],
                        rows: [
                          for (final row in provider.pageRows)
                            DataRow(
                              onSelectChanged: (_) => _detail(context, row),
                              cells: [
                                for (final cell in row)
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        cell,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      PaginationFooter(
                        currentPage: provider.page,
                        totalPages: (table.rows.length / provider.pageSize)
                            .ceil(),
                        totalElements: table.rows.length,
                        pageSize: provider.pageSize,
                        onPageChanged: provider.setPage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _detail(BuildContext context, List<String> row) => showDialog(
    context: context,
    builder: (_) => ZellaDialog(
      width: MediaQuery.sizeOf(context).width * 2 / 3,
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết ${provider.section.label.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < row.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SelectableText(
                      '${provider.table.columns[i]}: ${row[i]}',
                    ),
                  ),
                const SizedBox(height: 16),
                Text(provider.table.note),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
