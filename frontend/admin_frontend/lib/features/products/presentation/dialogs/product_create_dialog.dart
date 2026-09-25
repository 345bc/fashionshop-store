import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../sizeguides/presentation/providers/size_guides_provider.dart';

class ProductCreateDialog extends StatefulWidget {
  const ProductCreateDialog({super.key});

  @override
  State<ProductCreateDialog> createState() => _ProductCreateDialogState();
}

class _ProductCreateDialogState extends State<ProductCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedSizeGuideId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
      };

      await context.read<ProductsProvider>().createItem(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm sản phẩm thành công')),
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
      title: 'Thêm sản phẩm mới',
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
                        if (double.tryParse(value!) == null) {
                          return 'Giá không hợp lệ';
                        }
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

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withAlpha(50)),
                ),
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
