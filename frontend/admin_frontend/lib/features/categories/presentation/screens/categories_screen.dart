import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../data/models/category_response_model.dart';
import '../dialogs/category_create_dialog.dart';
import '../dialogs/category_delete_dialog.dart';
import '../dialogs/category_detail_dialog.dart';
import '../dialogs/category_edit_dialog.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoriesProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    MainScreen.of(context).navigate('/product-attributes'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Thuộc tính sản phẩm'),
              ),
            ),
            const SizedBox(height: 12),
            FeatureHeader(
              title: 'Danh mục',
              subtitle: 'Quản lý cấu trúc danh mục sản phẩm',
              actionLabel: 'Thêm danh mục',
              actionIcon: Icons.add,
              onExportPressed: () {},
              onActionPressed: () => showDialog(
                context: context,
                builder: (_) => const CategoryCreateDialog(),
              ),
            ),
            const SizedBox(height: 32),
            FeatureToolbar(
              searchHint: 'Tìm kiếm danh mục theo tên hoặc slug...',
              initialSearchText: context
                  .read<CategoriesProvider>()
                  .currentQuery,
              onSearchChanged: (query) =>
                  context.read<CategoriesProvider>().loadItems(query: query),
              filterWidget: DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tất cả trạng thái'),
                  ),
                  DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('Đã ẩn')),
                ],
                onChanged: (value) {
                  setState(() => _status = value ?? 'all');
                  context.read<CategoriesProvider>().setStatus(_status);
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Consumer<CategoriesProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Text(
                          'Lỗi: ${provider.error}',
                          style: const TextStyle(color: AppTheme.error),
                        ),
                      ),
                    );
                  }
                  final visible = provider.pageItems;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: _header('DANH MỤC')),
                            Expanded(flex: 2, child: _header('DANH MỤC CHA')),
                            Expanded(flex: 2, child: _header('TRẠNG THÁI')),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Text('Không có dữ liệu'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => _row(visible[index]),
                        ),
                      const Divider(height: 1),
                      PaginationFooter(
                        currentPage: provider.currentPage,
                        totalPages: provider.totalElements == 0
                            ? 1
                            : (provider.totalElements / provider.pageSize)
                                  .ceil(),
                        totalElements: provider.totalElements,
                        pageSize: provider.pageSize,
                        onPageChanged: (page) => provider.loadItems(page: page),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Text _header(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    ),
  );

  Widget _row(CategoryResponseModel category) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => CategoryDetailDialog(categoryId: category.id),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: category.imageUrl == null
                          ? const Icon(Icons.image_outlined)
                          : Image.network(
                              category.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.slug,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(category.parentName ?? '—')),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: category.isActive ? 'Hoạt động' : 'Đã ẩn',
                  textColor: category.isActive
                      ? AppTheme.success
                      : AppTheme.danger,
                  backgroundColor:
                      (category.isActive ? AppTheme.success : AppTheme.danger)
                          .withAlpha(25),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: ActionMenu(
                items: const [
                  ActionMenuItem(
                    value: 'view',
                    label: 'Xem chi tiết',
                    icon: Icons.visibility_outlined,
                  ),
                  ActionMenuItem(
                    value: 'edit',
                    label: 'Chỉnh sửa',
                    icon: Icons.edit_outlined,
                  ),
                  ActionMenuItem(
                    value: 'delete',
                    label: 'Xóa danh mục',
                    icon: Icons.delete_outline,
                    color: AppTheme.danger,
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          CategoryDetailDialog(categoryId: category.id),
                    );
                  } else if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) => CategoryEditDialog(category: category),
                    );
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (_) => CategoryDeleteDialog(category: category),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
