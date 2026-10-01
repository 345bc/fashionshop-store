import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../data/models/category_response_model.dart';
import '../providers/categories_provider.dart';

class CategoryDeleteDialog extends StatefulWidget {
  final CategoryResponseModel category;

  const CategoryDeleteDialog({super.key, required this.category});

  @override
  State<CategoryDeleteDialog> createState() => _CategoryDeleteDialogState();
}

class _CategoryDeleteDialogState extends State<CategoryDeleteDialog> {
  bool _isLoading = false;

  Future<void> _delete() async {
    setState(() => _isLoading = true);

    try {
      await context.read<CategoriesProvider>().deleteItem(widget.category.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa danh mục thành công')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZellaConfirmDialog(
      title: 'Xóa danh mục',
      content: Text(
        'Bạn có chắc chắn muốn xóa danh mục "${widget.category.name}" không? Danh mục đang có sản phẩm hoặc danh mục con sẽ không thể xóa.',
        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
      ),
      confirmText: 'Xóa',
      iconColor: AppTheme.danger,
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _delete,
    );
  }
}
