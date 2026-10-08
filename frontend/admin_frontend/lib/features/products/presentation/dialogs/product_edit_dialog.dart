import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../../core/network/api_endpoints.dart';

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
  bool _imagesLoading = true;
  String? _imagesError;
  final List<_EditableImage> _images = [];
  final List<int> _deletedImageIds = [];
  _EditableImage? _primaryImage;
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
      if (!mounted) return;
      context.read<CategoriesProvider>().loadOptions();
      context.read<SuppliersProvider>().loadOptions();
      context.read<SizeGuidesProvider>().loadItems();
      _loadImages();
    });
  }

  Future<void> _loadImages() async {
    setState(() {
      _imagesLoading = true;
      _imagesError = null;
    });
    try {
      final images = await context.read<ProductsProvider>().loadImages(
        widget.product['id'] as int,
      );
      if (!mounted) return;
      setState(() {
        _images
          ..clear()
          ..addAll(images.map(_EditableImage.fromJson));
        _images.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _primaryImage = null;
        for (final image in _images) {
          if (image.isPrimary) {
            _primaryImage = image;
            break;
          }
        }
        _primaryImage ??= _images.isEmpty ? null : _images.first;
      });
    } catch (error) {
      if (mounted) setState(() => _imagesError = error.toString());
    } finally {
      if (mounted) setState(() => _imagesLoading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      if (result.files.any(
        (file) => file.bytes == null || file.size == 0 || file.size > 10485760,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mỗi ảnh cần có dung lượng từ 1 byte đến 10 MB.'),
          ),
        );
        return;
      }
      setState(() {
        var nextOrder =
            _images.fold<int>(
              -1,
              (maxOrder, image) =>
                  image.displayOrder > maxOrder ? image.displayOrder : maxOrder,
            ) +
            1;
        for (final file in result.files) {
          _images.add(_EditableImage.newFile(file, nextOrder++));
        }
        _primaryImage ??= _images.first;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $error')));
      }
    }
  }

  void _removeImage(_EditableImage image) {
    setState(() {
      if (image.id != null) _deletedImageIds.add(image.id!);
      _images.remove(image);
      if (identical(_primaryImage, image)) {
        _primaryImage = _images.isEmpty ? null : _images.first;
      }
    });
  }

  String _imageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.origin + (url.startsWith('/') ? url : '/$url');
  }

  Future<void> _saveImages(ProductsProvider provider) async {
    final productId = widget.product['id'] as int;
    for (final image in _images) {
      if (image.file == null) continue;
      final uploaded = await provider.uploadImage(
        productId: productId,
        fileName: image.file!.name,
        bytes: image.file!.bytes!,
        isPrimary: false,
        displayOrder: image.displayOrder,
      );
      image.id = (uploaded['id'] as num).toInt();
      image.imageUrl = uploaded['imageUrl'] as String;
      image.file = null;
    }

    final primary = _primaryImage;
    if (primary != null && !primary.isPrimary) {
      await provider.updateImage(
        id: primary.id!,
        productId: productId,
        imageUrl: primary.imageUrl!,
        isPrimary: true,
        displayOrder: primary.displayOrder,
      );
      for (final image in _images) {
        image.isPrimary = identical(image, primary);
      }
    }

    for (final id in List<int>.of(_deletedImageIds)) {
      await provider.deleteImage(id);
      _deletedImageIds.remove(id);
    }
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
    if (_imagesLoading || _imagesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được ảnh sản phẩm. Vui lòng thử lại.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    setState(() => _isLoading = true);
    var productUpdated = false;
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

      final productsProvider = context.read<ProductsProvider>();
      await productsProvider.updateItem(widget.product['id'] as int, data);
      productUpdated = true;
      await _saveImages(productsProvider);

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
            content: Text(
              productUpdated
                  ? 'Thông tin sản phẩm đã lưu, nhưng ảnh chưa lưu xong: $e'
                  : 'Không thể cập nhật sản phẩm: $e',
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
      title: 'Chỉnh sửa sản phẩm',
      width: (screenSize.width * 2 / 3).clamp(480.0, 1200.0),
      height: screenSize.height * 2 / 3,
      confirmText: 'Lưu thay đổi',
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
                        final price = double.tryParse(value!);
                        if (price == null || price <= 0) {
                          return 'Giá phải lớn hơn 0';
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
                          decoration: InputDecoration(
                            errorText: provider.optionsError,
                            labelText: 'Danh mục *',
                          ),
                          items: provider.options.map((cat) {
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
                          decoration: InputDecoration(
                            errorText: provider.optionsError,
                            labelText: 'Nhà cung cấp *',
                          ),
                          items: provider.options.map((sup) {
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
              const Text(
                'Chọn ảnh chính, thêm ảnh mới hoặc xóa ảnh hiện có. '
                'Thay đổi được áp dụng khi bấm Lưu thay đổi.',
              ),
              const SizedBox(height: 16),
              if (_imagesLoading)
                const Center(child: CircularProgressIndicator())
              else if (_imagesError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không tải được ảnh: $_imagesError'),
                    TextButton(
                      onPressed: _loadImages,
                      child: const Text('Thử lại'),
                    ),
                  ],
                )
              else ...[
                if (_images.isEmpty) const Text('Chưa có ảnh sản phẩm.'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final image in _images)
                      Container(
                        width: 150,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: image.file != null
                                      ? Image.memory(
                                          image.file!.bytes!,
                                          width: 132,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const SizedBox(
                                                width: 132,
                                                height: 110,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              ),
                                        )
                                      : Image.network(
                                          _imageUrl(image.imageUrl!),
                                          width: 132,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const SizedBox(
                                                width: 132,
                                                height: 110,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              ),
                                        ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton.filledTonal(
                                    tooltip: 'Xóa ảnh',
                                    onPressed: _isLoading
                                        ? null
                                        : () => _removeImage(image),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() => _primaryImage = image),
                              icon: Icon(
                                identical(_primaryImage, image)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 18,
                              ),
                              label: const Text('Ảnh chính'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Thêm ảnh'),
                ),
              ],
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

class _EditableImage {
  int? id;
  String? imageUrl;
  PlatformFile? file;
  int displayOrder;
  bool isPrimary;

  _EditableImage({
    this.id,
    this.imageUrl,
    this.file,
    required this.displayOrder,
    this.isPrimary = false,
  });

  factory _EditableImage.fromJson(Map<String, dynamic> json) => _EditableImage(
    id: (json['id'] as num).toInt(),
    imageUrl: json['imageUrl'] as String,
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    isPrimary: json['isPrimary'] == true,
  );

  factory _EditableImage.newFile(PlatformFile file, int displayOrder) =>
      _EditableImage(file: file, displayOrder: displayOrder);
}
