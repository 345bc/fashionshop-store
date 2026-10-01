import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../data/models/category_response_model.dart';
import '../providers/categories_provider.dart';

class CategoryFormDialog extends StatefulWidget {
  final CategoryResponseModel? category;
  const CategoryFormDialog({super.key, this.category});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final Future<List<CategoryResponseModel>> _parentsFuture;
  int? _parentId;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _parentId = widget.category?.parentId;
    _isActive = widget.category?.isActive ?? true;
    _parentsFuture = context.read<CategoriesProvider>().loadParentOptions();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục cha')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'parentId': _parentId,
        'isActive': _isActive,
      };
      final provider = context.read<CategoriesProvider>();
      if (widget.category == null) {
        await provider.createItem(data);
      } else {
        await provider.updateItem(widget.category!.id, data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.category == null
                ? 'Thêm danh mục thành công'
                : 'Cập nhật danh mục thành công',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu danh mục: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _canBeParent(
    CategoryResponseModel candidate,
    Map<int, CategoryResponseModel> byId,
  ) {
    if (!candidate.isActive) return false;
    final editedId = widget.category?.id;
    if (editedId == null) return true;
    var current = candidate;
    final visited = <int>{};
    while (visited.add(current.id)) {
      if (current.id == editedId) return false;
      final next = byId[current.parentId];
      if (next == null) break;
      current = next;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaFormDialog(
      title: widget.category == null
          ? 'Thêm danh mục mới'
          : 'Chỉnh sửa danh mục',
      width: (size.width * 2 / 3).clamp(480.0, 1100.0),
      height: size.height * 2 / 3,
      confirmText: widget.category == null ? 'Thêm danh mục' : 'Lưu thay đổi',
      isLoading: _saving,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thông tin cơ bản',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên danh mục *'),
                maxLength: 100,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên danh mục'
                    : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Slug sẽ được tạo tự động từ tên danh mục.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<CategoryResponseModel>>(
                future: _parentsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text(
                      snapshot.hasError
                          ? 'Không tải được danh mục cha: ${snapshot.error}'
                          : 'Đang tải danh mục cha...',
                    );
                  }
                  final byId = {
                    for (final item in snapshot.data!) item.id: item,
                  };
                  final choices = snapshot.data!
                      .where((item) => _canBeParent(item, byId))
                      .toList();
                  final validParent = choices.any(
                    (item) => item.id == _parentId,
                  );
                  return DropdownButtonFormField<int?>(
                    key: ValueKey(_parentId),
                    initialValue: validParent ? _parentId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục cha *',
                    ),
                    items: [
                      ...choices.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _parentId = value),
                    validator: (_) {
                      if (_parentId == null) {
                        return 'Vui lòng chọn danh mục cha';
                      }
                      return _parentId != null && !validParent
                          ? 'Danh mục cha không hợp lệ'
                          : null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trạng thái hoạt động'),
                value: _isActive,
                activeThumbColor: AppTheme.primary,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
