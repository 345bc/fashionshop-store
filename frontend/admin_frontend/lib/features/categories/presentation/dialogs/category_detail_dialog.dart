import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/category_response_model.dart';
import '../providers/categories_provider.dart';

class CategoryDetailDialog extends StatefulWidget {
  final int categoryId;
  const CategoryDetailDialog({super.key, required this.categoryId});

  @override
  State<CategoryDetailDialog> createState() => _CategoryDetailDialogState();
}

class _CategoryDetailDialogState extends State<CategoryDetailDialog> {
  late Future<CategoryResponseModel> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CategoriesProvider>().loadDetail(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: (size.width * 2 / 3).clamp(480.0, 1100.0),
      height: size.height * 2 / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết danh mục',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<CategoryResponseModel>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Không tải được danh mục: ${snapshot.error}'),
                  );
                }
                final category = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${category.slug}  •  Mã #${category.id}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      if (category.imageUrl != null) ...[
                        Image.network(
                          category.imageUrl!,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Text('Không tải được ảnh danh mục'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _field('Danh mục cha', category.parentName ?? 'Không có'),
                      _field(
                        'Trạng thái',
                        category.isActive ? 'Hoạt động' : 'Đã ẩn',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    ),
  );
}
