import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../sizeguides/presentation/providers/size_guides_provider.dart';

class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductEditDialog({super.key, required this.product});

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _styleController;
  late TextEditingController _occasionController;
  late TextEditingController _basePriceController;
  late TextEditingController _descriptionController;

  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedSizeGuideId;

  bool _isLoading = false;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _styleController = TextEditingController(text: widget.product['style']);
    _occasionController = TextEditingController(
      text: widget.product['occasion'],
    );
    _basePriceController = TextEditingController(
      text: widget.product['basePrice']?.toString() ?? '0',
    );
    _descriptionController = TextEditingController(
      text: widget.product['description'],
    );

    final catData = widget.product['categoryId'];
    _selectedCategoryId = catData is int
        ? catData
        : (catData is Map ? catData['id'] as int? : null);

    final supData = widget.product['supplierId'];
    _selectedSupplierId = supData is int
        ? supData
        : (supData is Map ? supData['id'] as int? : null);

    final sgData = widget.product['sizeGuideId'];
    _selectedSizeGuideId = sgData is int
        ? sgData
        : (sgData is Map ? sgData['id'] as int? : null);

    _isActive =
        widget.product['isActive'] ?? widget.product['is_active'] ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadItems();
      context.read<SuppliersProvider>().loadItems();
      context.read<SizeGuidesProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _styleController.dispose();
    _occasionController.dispose();
    _basePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text,
        'categoryId': _selectedCategoryId,
        'basePrice': double.parse(_basePriceController.text),
        'style': _styleController.text,
        'occasion': _occasionController.text,
        'description': _descriptionController.text,
        if (_selectedSupplierId != null) 'supplierId': _selectedSupplierId,
        if (_selectedSizeGuideId != null) 'sizeGuideId': _selectedSizeGuideId,
        'isActive': _isActive,
      };

      await context.read<ProductsProvider>().updateItem(
        widget.product['id'] as int,
        data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sản phẩm thành công')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: \${e.toString()}'),
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
    return ZellaFormDialog(
      title: 'Chỉnh sửa sản phẩm',
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionTitle('Thông tin cơ bản'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm *',
                        hintText: 'Nhập tên sản phẩm',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                          activeThumbColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả ngắn',
                  hintText: 'Nhập mô tả sản phẩm...',
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Phân loại & Thuộc tính'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _styleController,
                      decoration: const InputDecoration(
                        labelText: 'Phong cách (Style)',
                        hintText: 'VD: Vintage, Modern...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _occasionController,
                      decoration: const InputDecoration(
                        labelText: 'Dịp (Occasion)',
                        hintText: 'VD: Dạo phố, Dự tiệc...',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Giá bán & Liên kết'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Giá bán cơ bản (VND) *',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Vui lòng nhập giá';
                        if (double.tryParse(value!) == null)
                          return 'Giá không hợp lệ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<CategoriesProvider>(
                      builder: (context, provider, _) {
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục *',
                          ),
                          items: provider.items.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCategoryId = val);
                          },
                          validator: (value) =>
                              value == null ? 'Vui lòng chọn' : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Consumer<SuppliersProvider>(
                      builder: (context, provider, _) {
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedSupplierId,
                          decoration: const InputDecoration(
                            labelText: 'Nhà cung cấp',
                          ),
                          items: provider.items.map((sup) {
                            return DropdownMenuItem(
                              value: sup.id,
                              child: Text(sup.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSupplierId = val);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<SizeGuidesProvider>(
                      builder: (context, provider, _) {
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedSizeGuideId,
                          decoration: const InputDecoration(
                            labelText: 'Size Guide',
                          ),
                          items: provider.items.map((guide) {
                            return DropdownMenuItem(
                              value: guide.id,
                              child: Text(guide.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSizeGuideId = val);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.text,
      ),
    );
  }
}
