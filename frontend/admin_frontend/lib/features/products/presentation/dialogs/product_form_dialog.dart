import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../../core/network/api_endpoints.dart';

import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../sizeguides/presentation/providers/size_guides_provider.dart';

class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
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
  int? _productId;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _productId = (widget.product?['id'] as num?)?.toInt();
    _imagesLoading = _isEditing;
    _nameController = TextEditingController(text: widget.product?['name']);
    _styleController = TextEditingController(text: widget.product?['style']);
    _occasionController = TextEditingController(
      text: widget.product?['occasion'],
    );
    _basePriceController = TextEditingController(
      text: widget.product?['basePrice']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?['description'],
    );

    final catData = widget.product?['categoryId'];
    _selectedCategoryId = catData is int
        ? catData
        : (catData is Map ? catData['id'] as int? : null);

    final supData = widget.product?['supplierId'];
    _selectedSupplierId = supData is int
        ? supData
        : (supData is Map ? supData['id'] as int? : null);

    final sgData = widget.product?['sizeGuideId'];
    _selectedSizeGuideId = sgData is int
        ? sgData
        : (sgData is Map ? sgData['id'] as int? : null);

    _isActive =
        widget.product?['isActive'] ?? widget.product?['is_active'] ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesProvider>().loadOptions();
      context.read<SuppliersProvider>().loadOptions();
      context.read<SizeGuidesProvider>().loadItems();
      if (_isEditing) _loadImages();
    });
  }

  Future<void> _loadImages() async {
    setState(() {
      _imagesLoading = true;
      _imagesError = null;
    });
    try {
      final images = await context.read<ProductsProvider>().loadImages(
        _productId!,
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
    final productId = _productId!;
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
    if (_isLoading) return;
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
        'name': _nameController.text.trim(),
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
      if (_productId == null) {
        final created = await productsProvider.createItem(data);
        _productId = (created['id'] as num).toInt();
      } else {
        await productsProvider.updateItem(_productId!, data);
      }
      productUpdated = true;
      await _saveImages(productsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Cập nhật sản phẩm thành công'
                  : 'Thêm sản phẩm thành công',
            ),
          ),
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
                  : 'Không thể lưu sản phẩm: $e',
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
      title: _isEditing ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới',
      subtitle: 'Thông tin, phân loại và ảnh sản phẩm.',
      confirmText: _isEditing ? 'Lưu thay đổi' : 'Tạo sản phẩm',
      width: 900,
      height: screenSize.height * 0.88,
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      content: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12, right: 6, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _formRow(
                    'Tên sản phẩm *',
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên sản phẩm',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _formRow(
                    'Mô tả ngắn',
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Nhập mô tả sản phẩm',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _formRow(
                    'Phong cách',
                    TextFormField(
                      controller: _styleController,
                      decoration: const InputDecoration(
                        hintText: 'VD: Vintage, Modern',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _formRow(
                    'Dịp sử dụng',
                    TextFormField(
                      controller: _occasionController,
                      decoration: const InputDecoration(
                        hintText: 'VD: Dạo phố, Dự tiệc',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _formRow(
                    'Giá bán *',
                    TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        suffixText: 'VND',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Vui lòng nhập giá';
                        final price = double.tryParse(value!);
                        if (price == null || !price.isFinite || price <= 0) {
                          return 'Giá phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _formRow(
                    'Danh mục *',
                    Consumer<CategoriesProvider>(
                      builder: (context, provider, _) {
                        return SearchableSelectField<int>(
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            hintText: 'Chọn danh mục',
                            errorText: provider.optionsError,
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
                  const SizedBox(height: 24),
                  _formRow(
                    'Nhà cung cấp *',
                    Consumer<SuppliersProvider>(
                      builder: (context, provider, _) {
                        return SearchableSelectField<int>(
                          initialValue: _selectedSupplierId,
                          decoration: InputDecoration(
                            hintText: 'Chọn nhà cung cấp',
                            errorText: provider.optionsError,
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
                  const SizedBox(height: 24),
                  _formRow(
                    'Bảng kích thước *',
                    Consumer<SizeGuidesProvider>(
                      builder: (context, provider, _) {
                        return SearchableSelectField<int>(
                          initialValue: _selectedSizeGuideId,
                          decoration: const InputDecoration(
                            hintText: 'Chọn bảng kích thước',
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
                  const SizedBox(height: 24),
                  _formRow(
                    'Trạng thái',
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      tileColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        _isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _isActive,
                      activeThumbColor: AppTheme.primary,
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() => _isActive = value),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _formRow(
                    'Ảnh sản phẩm',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Chọn ảnh chính. Tối đa 10 MB mỗi ảnh.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          if (_images.isEmpty)
                            const Text(
                              'Chưa có ảnh sản phẩm.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final image in _images)
                                Container(
                                  width: 150,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                            Symbols
                                                                .broken_image,
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
                                                            Symbols
                                                                .broken_image,
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
                                              icon: const Icon(
                                                Symbols.close,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : () => setState(
                                                () => _primaryImage = image,
                                              ),
                                        icon: Icon(
                                          identical(_primaryImage, image)
                                              ? Symbols.check_circle
                                              : Symbols.radio_button_unchecked,
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
                            icon: const Icon(Symbols.add_photo_alternate),
                            label: const Text('Chọn ảnh từ thiết bị'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formRow(String label, Widget field) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.text),
          ),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 10), field],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 190, child: title),
            Expanded(child: field),
          ],
        );
      },
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
