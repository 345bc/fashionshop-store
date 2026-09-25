import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';

class CategoryDeleteDialog extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryDeleteDialog({super.key, required this.category});

  @override
  State<CategoryDeleteDialog> createState() => _CategoryDeleteDialogState();
}

class _CategoryDeleteDialogState extends State<CategoryDeleteDialog> {
  bool _isLoading = false;

  Future<void> _delete() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Replace with API Call
      await Future.delayed(const Duration(seconds: 1)); // Mock API delay
      
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: ZellaConfirmDialog(
          title: 'Xóa danh mục',
          content: Text(
            'Bạn có chắc chắn muốn xóa danh mục "${widget.category['name']}" không? Hành động này không thể hoàn tác và có thể ảnh hưởng đến các sản phẩm thuộc danh mục này.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          confirmText: 'Xóa',
          iconColor: AppTheme.danger,
          isLoading: _isLoading,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _delete,
        ),
      ),
    );
  }
}
