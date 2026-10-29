import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../providers/product_variants_provider.dart';

class VariantFormDialog extends StatefulWidget {
  final int productId;
  final Map<String, dynamic>? variant;
  const VariantFormDialog({super.key, required this.productId, this.variant});

  @override
  State<VariantFormDialog> createState() => _VariantFormDialogState();
}

class _VariantFormDialogState extends State<VariantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _price;
  late final Future<
    ({List<Map<String, dynamic>> sizes, List<Map<String, dynamic>> colors})
  >
  _options;
  int? _sizeId;
  int? _colorId;
  late bool _isActive;
  bool _saving = false;
  bool _imagesLoading = false;
  String? _imagesError;
  final List<_VariantImageDraft> _images = [];
  final List<int> _deletedImageIds = [];
  _VariantImageDraft? _primaryImage;
  int? _createdVariantId;

  @override
  void initState() {
    super.initState();
    final variant = widget.variant;
    _sizeId = (variant?['sizeId'] as num?)?.toInt();
    _colorId = (variant?['colorId'] as num?)?.toInt();
    _price = TextEditingController(text: variant?['price']?.toString() ?? '');
    _isActive = variant?['isActive'] == true || variant == null;
    _options = context.read<ProductVariantsProvider>().loadOptions();
    if (variant != null) {
      _loadImages((variant['id'] as num).toInt());
    }
  }

  Future<void> _loadImages(int variantId) async {
    setState(() {
      _imagesLoading = true;
      _imagesError = null;
    });
    try {
      final images = await context.read<ProductVariantsProvider>().loadImages(
        variantId,
      );
      if (!mounted) return;
      setState(() {
        _images
          ..clear()
          ..addAll(images.map(_VariantImageDraft.fromJson));
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
          _images.add(
            _VariantImageDraft(file: file, displayOrder: nextOrder++),
          );
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

  void _removeImage(_VariantImageDraft image) {
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

  Future<void> _saveImages(
    ProductVariantsProvider provider,
    int variantId,
  ) async {
    for (final image in _images) {
      if (image.file == null) continue;
      final uploaded = await provider.uploadImage(
        variantId: variantId,
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
        variantId: variantId,
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
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_imagesLoading || _imagesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được ảnh biến thể. Vui lòng thử lại.'),
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    var variantSaved = false;
    try {
      final data = {
        'productId': widget.productId,
        'sizeId': _sizeId,
        'colorId': _colorId,
        'price': double.parse(_price.text.trim()),
        'costPrice': widget.variant?['costPrice'] ?? 0,
        'stockQuantity': widget.variant?['stockQuantity'] ?? 0,
        'reservedQuantity': widget.variant?['reservedQuantity'] ?? 0,
        'isActive': _isActive,
      };
      final provider = context.read<ProductVariantsProvider>();
      if (widget.variant == null) {
        if (_createdVariantId == null) {
          final created = await provider.createItem(data);
          _createdVariantId = (created['id'] as num).toInt();
        } else {
          await provider.updateItem(_createdVariantId!, data);
        }
      } else {
        await provider.updateItem((widget.variant!['id'] as num).toInt(), data);
      }
      variantSaved = true;
      await _saveImages(
        provider,
        _createdVariantId ?? (widget.variant!['id'] as num).toInt(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.variant == null
                ? 'Thêm biến thể thành công'
                : 'Cập nhật biến thể thành công',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              variantSaved
                  ? 'Biến thể đã lưu, nhưng ảnh chưa lưu xong: $error'
                  : 'Không thể lưu biến thể: $error',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _moneyValidator(String? value, {bool positive = false}) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < 0 || (positive && number == 0)) {
      return positive ? 'Nhập số lớn hơn 0' : 'Nhập số từ 0 trở lên';
    }
    if (!RegExp(r'^\d{1,16}(?:\.\d{1,2})?$').hasMatch(value!.trim())) {
      return 'Tối đa 2 chữ số thập phân';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaFormDialog(
      title: widget.variant == null ? 'Thêm biến thể' : 'Chỉnh sửa biến thể',
      subtitle: 'Thiết lập kích thước, màu sắc và giá bán.',
      width: 640,
      height: size.height * 0.82,
      confirmText: widget.variant == null ? 'Thêm biến thể' : 'Lưu thay đổi',
      isLoading: _saving,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      content: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        child:
            FutureBuilder<
              ({
                List<Map<String, dynamic>> sizes,
                List<Map<String, dynamic>> colors,
              })
            >(
              future: _options,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: snapshot.hasError
                        ? Text('Không tải được size và màu: ${snapshot.error}')
                        : const CircularProgressIndicator(),
                  );
                }
                final options = snapshot.data!;
                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SearchableSelectField<int>(
                                initialValue: _sizeId,
                                decoration: const InputDecoration(
                                  labelText: 'Size *',
                                  hintText: 'Chọn size',
                                ),
                                items: options.sizes
                                    .map(
                                      (item) => DropdownMenuItem<int>(
                                        value: (item['id'] as num).toInt(),
                                        child: Text(
                                          item['name']?.toString() ?? '',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _sizeId = value),
                                validator: (value) =>
                                    value == null ? 'Vui lòng chọn size' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SearchableSelectField<int>(
                                initialValue: _colorId,
                                decoration: const InputDecoration(
                                  labelText: 'Màu *',
                                  hintText: 'Chọn màu',
                                ),
                                items: options.colors
                                    .map(
                                      (item) => DropdownMenuItem<int>(
                                        value: (item['id'] as num).toInt(),
                                        child: Text(
                                          '${item['name']} (${item['code']})',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _colorId = value),
                                validator: (value) =>
                                    value == null ? 'Vui lòng chọn màu' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Giá bán *',
                            hintText: 'Nhập giá bán',
                            suffixText: 'VND',
                          ),
                          validator: (value) =>
                              _moneyValidator(value, positive: true),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          tileColor: AppTheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text('Đang bán'),
                          subtitle: const Text(
                            'Cho phép bán biến thể này',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          value: _isActive,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ảnh biến thể',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Thêm ảnh và chọn một ảnh làm ảnh chính.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
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
                                onPressed: () => _loadImages(
                                  (widget.variant!['id'] as num).toInt(),
                                ),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          )
                        else ...[
                          if (_images.isEmpty)
                            Material(
                              color: AppTheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _saving ? null : _pickImages,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Symbols.add_photo_alternate,
                                        size: 28,
                                        color: AppTheme.textSecondary,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Chọn ảnh từ máy',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG, GIF, WebP · Tối đa 10 MB/ảnh',
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final image in _images)
                                Container(
                                  width: 150,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: identical(_primaryImage, image)
                                        ? AppTheme.surface
                                        : Colors.white,
                                    border: Border.all(
                                      color: identical(_primaryImage, image)
                                          ? AppTheme.primary
                                          : AppTheme.borderLight,
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
                                                            Icons
                                                                .broken_image_outlined,
                                                          ),
                                                        ),
                                                  ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton.filledTonal(
                                              tooltip: 'Xóa ảnh',
                                              onPressed: _saving
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
                                        onPressed: _saving
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
                          if (_images.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _pickImages,
                                icon: const Icon(Symbols.add_photo_alternate),
                                label: const Text('Thêm ảnh'),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _VariantImageDraft {
  int? id;
  String? imageUrl;
  PlatformFile? file;
  int displayOrder;
  bool isPrimary;

  _VariantImageDraft({
    this.id,
    this.imageUrl,
    this.file,
    required this.displayOrder,
    this.isPrimary = false,
  });

  factory _VariantImageDraft.fromJson(Map<String, dynamic> json) =>
      _VariantImageDraft(
        id: (json['id'] as num).toInt(),
        imageUrl: json['imageUrl'] as String,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        isPrimary: json['isPrimary'] == true,
      );
}
