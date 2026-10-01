import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
  final List<PlatformFile> _selectedImages = [];

  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedSizeGuideId;

  bool _isLoading = false;
  int? _createdProductId;
  int _nextImageIndex = 0;

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

  Future<void> _addImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;
      final invalid = result.files.where(
        (file) => file.bytes == null || file.size == 0 || file.size > 10485760,
      );
      if (invalid.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mỗi ảnh cần có dung lượng từ 1 byte đến 10 MB.'),
          ),
        );
        return;
      }
      setState(() => _selectedImages.addAll(result.files));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $error')));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
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

      final productsProvider = context.read<ProductsProvider>();
      if (_createdProductId == null) {
        final product = await productsProvider.createItem(data);
        _createdProductId = (product['id'] as num).toInt();
      }

      for (var i = _nextImageIndex; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        await productsProvider.uploadImage(
          productId: _createdProductId!,
          fileName: image.name,
          bytes: image.bytes!,
          isPrimary: i == 0,
          displayOrder: i,
        );
        _nextImageIndex = i + 1;
      }

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
            content: Text(
              _createdProductId == null
                  ? 'Không thể thêm sản phẩm: $e'
                  : 'Sản phẩm đã được tạo, nhưng tải ảnh chưa hoàn tất. Hãy thử lưu lại: $e',
            ),
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
    final screenSize = MediaQuery.sizeOf(context);
    return ZellaFormDialog(
      title: 'Thêm sản phẩm mới',
      width: (screenSize.width * 2 / 3).clamp(480.0, 1200.0),
      height: screenSize.height * 2 / 3,
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
                          initialValue: _selectedCategoryId,
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
                          initialValue: _selectedSupplierId,
                          decoration: const InputDecoration(
                            labelText: 'Nhà cung cấp *',
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
                          validator: (value) =>
                              value == null ? 'Vui lòng chọn' : null,
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
                          initialValue: _selectedSizeGuideId,
                          decoration: const InputDecoration(
                            labelText: 'Size Guide *',
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
                          validator: (value) =>
                              value == null ? 'Vui lòng chọn' : null,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Ảnh sản phẩm'),
              const SizedBox(height: 8),
              const Text('Chọn ảnh từ máy. Ảnh đầu tiên sẽ là ảnh chính.'),
              if (_createdProductId != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Sản phẩm đã được tạo. Bấm Lưu để tiếp tục tải các ảnh còn lại.',
                ),
              ],
              const SizedBox(height: 12),
              for (var i = 0; i < _selectedImages.length; i++) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Image.memory(
                    _selectedImages[i].bytes!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                  title: Text(
                    _selectedImages[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(i == 0 ? 'Ảnh chính' : 'Ảnh ${i + 1}'),
                  trailing: _createdProductId == null
                      ? IconButton(
                          tooltip: 'Xóa ảnh',
                          onPressed: _isLoading ? null : () => _removeImage(i),
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              if (_createdProductId == null)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _addImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Thêm ảnh'),
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
