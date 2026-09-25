import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../dialogs/category_edit_dialog.dart';
import '../dialogs/category_delete_dialog.dart';

class CategoriesTable extends StatefulWidget {
  const CategoriesTable({super.key});

  @override
  State<CategoriesTable> createState() => _CategoriesTableState();
}

class _CategoriesTableState extends State<CategoriesTable> {
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 1,
      'parent_id': null,
      'name': 'Áo khoác',
      'slug': 'ao-khoac',
      'is_active': true,
    },
    {
      'id': 2,
      'parent_id': 1,
      'name': 'Áo khoác mùa đông',
      'slug': 'ao-khoac-mua-dong',
      'is_active': true,
    },
    {
      'id': 3,
      'parent_id': null,
      'name': 'Quần tây',
      'slug': 'quan-tay',
      'is_active': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTableHeader(),
        _buildTableRows(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('ID & TÊN DANH MỤC', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 2, child: Text('SLUG', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 2, child: Text('DANH MỤC CHA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 1, child: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTableRows() {
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Text('Chưa có danh mục nào', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isActive = category['is_active'] == true;
        
        String parentName = '—';
        if (category['parent_id'] != null) {
          final parent = _categories.firstWhere((c) => c['id'] == category['parent_id'], orElse: () => {});
          if (parent.isNotEmpty) {
            parentName = parent['name'];
          }
        }

        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => CategoryEditDialog(category: category),
            );
          },
          hoverColor: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${category['id']}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    category['slug'],
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    parentName,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.success.withAlpha(25) : AppTheme.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Đã ẩn',
                        style: TextStyle(
                          color: isActive ? AppTheme.success : AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(
                            const Duration(seconds: 0),
                            () async {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (_) => CategoryEditDialog(category: category),
                              );
                            },
                          );
                        },
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                            SizedBox(width: 8),
                            Text('Xóa danh mục', style: TextStyle(color: AppTheme.danger)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(
                            const Duration(seconds: 0),
                            () async {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (_) => CategoryDeleteDialog(category: category),
                              );
                            },
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
      },
    );
  }
}
