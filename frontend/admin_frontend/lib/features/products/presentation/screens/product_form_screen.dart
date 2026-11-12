import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../../../../core/network/api_endpoints.dart';

import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../sizeguides/presentation/providers/size_guides_provider.dart';
import '../../../../widgets/common/zella_toast.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback? onClose;

  const ProductFormScreen({super.key, this.product, this.onClose});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
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
        ZellaToast.show(
          context,
          message: 'Mỗi ảnh cần có dung lượng từ 1 byte đến 10 MB.',
          type: ToastType.warning,
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
        ZellaToast.show(
          context,
          message: 'Không thể chọn ảnh: $error',
          type: ToastType.error,
        );
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

  Future<void> _submit({required bool active}) async {
    if (_isLoading) return;
    if (_imagesLoading || _imagesError != null) {
      ZellaToast.show(
        context,
        message: 'Chưa tải được ảnh sản phẩm. Vui lòng thử lại.',
        type: ToastType.warning,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ZellaToast.show(
        context,
        message: 'Vui lòng chọn danh mục',
        type: ToastType.warning,
      );
      return;
    }

    setState(() {
      _isActive = active;
      _isLoading = true;
    });
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
        ZellaToast.show(
          context,
          message: _isEditing
              ? 'Cập nhật sản phẩm thành công'
              : active
              ? 'Đăng sản phẩm thành công'
              : 'Đã lưu bản nháp sản phẩm',
          type: ToastType.success,
        );
        _close();
      }
    } catch (e) {
      if (mounted) {
        ZellaToast.show(
          context,
          message: productUpdated
              ? 'Thông tin sản phẩm đã lưu, nhưng ảnh chưa lưu xong: $e'
              : 'Không thể lưu sản phẩm: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFF5364FF)),
            ),
          ),
        ),
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Về danh sách sản phẩm',
                              onPressed: _close,
                              icon: const Icon(Symbols.arrow_back, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isEditing
                                    ? 'Chỉnh sửa sản phẩm'
                                    : 'Thêm sản phẩm',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _close,
                          child: const Text('Sản phẩm / Thông tin sản phẩm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _section(
                      'Thông tin sản phẩm',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _columns([
                            _field(
                              'Tên sản phẩm *',
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập tên sản phẩm',
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Vui lòng nhập tên'
                                    : null,
                              ),
                            ),
                            _field(
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
                          ]),
                          const SizedBox(height: 24),
                          _columns([
                            _field(
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
                            _field(
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
                                      setState(
                                        () => _selectedSizeGuideId = val,
                                      );
                                    },
                                    validator: (value) =>
                                        value == null ? 'Vui lòng chọn' : null,
                                  );
                                },
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _columns([
                            _field(
                              'Phong cách',
                              TextFormField(
                                controller: _styleController,
                                decoration: const InputDecoration(
                                  hintText: 'VD: Vintage, Modern',
                                ),
                              ),
                            ),
                            _field(
                              'Dịp sử dụng',
                              TextFormField(
                                controller: _occasionController,
                                decoration: const InputDecoration(
                                  hintText: 'VD: Dạo phố, Dự tiệc',
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _field(
                            'Mô tả ngắn',
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText: 'Nhập mô tả sản phẩm',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      'Giá bán & hiển thị',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _columns([
                            _field(
                              'Giá bán *',
                              TextFormField(
                                controller: _basePriceController,
                                decoration: const InputDecoration(
                                  suffixText: 'VND',
                                  hintText: '0',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Vui lòng nhập giá';
                                  }
                                  final price = double.tryParse(value!);
                                  if (price == null ||
                                      !price.isFinite ||
                                      price <= 0) {
                                    return 'Giá phải lớn hơn 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _field(
                              'Trạng thái hiện tại',
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FC),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: const Color(0xFFE4E7EC),
                                  ),
                                ),
                                child: Text(
                                  _isEditing
                                      ? (_isActive
                                            ? 'Đang hoạt động'
                                            : 'Bản nháp · Chưa hiển thị')
                                      : 'Chọn Lưu nháp hoặc Đăng sản phẩm bên dưới',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                      _imageUrl(
                                                        image.imageUrl!,
                                                      ),
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
                                                : Symbols
                                                      .radio_button_unchecked,
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
                            Material(
                              color: const Color(0xFFFCFCFD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFFD0D5DD),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _isLoading ? null : _pickImages,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 38,
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFE4E7EC),
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: const Icon(
                                          Symbols.upload,
                                          size: 24,
                                          color: Color(0xFF475467),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Text(
                                        'Nhấn để chọn ảnh từ thiết bị',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'JPG, PNG, GIF, WebP · Tối đa 10 MB mỗi ảnh',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        TextButton(onPressed: _close, child: const Text('Hủy')),
                        OutlinedButton(
                          onPressed: () => _submit(active: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                          ),
                          child: const Text('Lưu nháp'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _submit(active: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5364FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Symbols.check, size: 18),
                          label: Text(
                            _isLoading
                                ? 'Đang lưu...'
                                : _isEditing
                                ? 'Lưu và đăng sản phẩm'
                                : 'Đăng sản phẩm',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 9),
      field,
    ],
  );

  Widget _columns(List<Widget> fields) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 650) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              fields[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: 24),
            Expanded(child: fields[i]),
          ],
        ],
      );
    },
  );

  Widget _section(String title, Widget content) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE4E7EC)),
        Padding(padding: const EdgeInsets.all(24), child: content),
      ],
    ),
  );
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
