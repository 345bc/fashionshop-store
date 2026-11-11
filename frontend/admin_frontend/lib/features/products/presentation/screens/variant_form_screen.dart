import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../providers/product_variants_provider.dart';

class VariantFormScreen extends StatefulWidget {
  final int productId;
  final Map<String, dynamic>? variant;
  final VoidCallback onClose;

  const VariantFormScreen({
    super.key,
    required this.productId,
    this.variant,
    required this.onClose,
  });

  @override
  State<VariantFormScreen> createState() => _VariantFormScreenState();
}

class _VariantFormScreenState extends State<VariantFormScreen> {
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
      widget.onClose();
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
    final isEditing = widget.variant != null;
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
          absorbing: _saving,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Về danh sách biến thể',
                        onPressed: widget.onClose,
                        icon: const Icon(Symbols.arrow_back, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEditing ? 'Chỉnh sửa biến thể' : 'Thêm biến thể',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder(
                    future: _options,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: snapshot.hasError
                              ? Text(
                                  'Không tải được size và màu: ${snapshot.error}',
                                )
                              : const CircularProgressIndicator(),
                        );
                      }
                      final options = snapshot.data!;
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _section(
                              'Thông tin biến thể',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _columns([
                                    _field(
                                      'Kích cỡ *',
                                      SearchableSelectField<int>(
                                        initialValue: _sizeId,
                                        decoration: const InputDecoration(
                                          hintText: 'Chọn kích cỡ',
                                        ),
                                        items: [
                                          for (final size in options.sizes)
                                            DropdownMenuItem(
                                              value: (size['id'] as num)
                                                  .toInt(),
                                              child: Text(
                                                size['name']?.toString() ?? '',
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) =>
                                            setState(() => _sizeId = value),
                                        validator: (value) => value == null
                                            ? 'Vui lòng chọn kích cỡ'
                                            : null,
                                      ),
                                    ),
                                    _field(
                                      'Màu sắc *',
                                      SearchableSelectField<int>(
                                        initialValue: _colorId,
                                        decoration: const InputDecoration(
                                          hintText: 'Chọn màu sắc',
                                        ),
                                        items: [
                                          for (final color in options.colors)
                                            DropdownMenuItem(
                                              value: (color['id'] as num)
                                                  .toInt(),
                                              child: Text(
                                                '${color['name']} (${color['code']})',
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) =>
                                            setState(() => _colorId = value),
                                        validator: (value) => value == null
                                            ? 'Vui lòng chọn màu sắc'
                                            : null,
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  _field(
                                    'Giá bán *',
                                    TextFormField(
                                      controller: _price,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        hintText: 'Nhập giá bán',
                                        suffixText: 'VND',
                                      ),
                                      validator: (value) => _moneyValidator(
                                        value,
                                        positive: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Đang bán'),
                                    value: _isActive,
                                    onChanged: (value) =>
                                        setState(() => _isActive = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _section(
                              'Ảnh biến thể',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_imagesLoading)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_imagesError != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Không tải được ảnh: $_imagesError',
                                        ),
                                        TextButton(
                                          onPressed: () => _loadImages(
                                            (widget.variant!['id'] as num)
                                                .toInt(),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.border,
                                          ),
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
                                                    color:
                                                        AppTheme.textSecondary,
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
                                              color:
                                                  identical(
                                                    _primaryImage,
                                                    image,
                                                  )
                                                  ? AppTheme.surface
                                                  : Colors.white,
                                              border: Border.all(
                                                color:
                                                    identical(
                                                      _primaryImage,
                                                      image,
                                                    )
                                                    ? AppTheme.primary
                                                    : AppTheme.borderLight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: image.file != null
                                                          ? Image.memory(
                                                              image
                                                                  .file!
                                                                  .bytes!,
                                                              width: 132,
                                                              height: 110,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Image.network(
                                                              _imageUrl(
                                                                image.imageUrl!,
                                                              ),
                                                              width: 132,
                                                              height: 110,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    _,
                                                                    _,
                                                                    _,
                                                                  ) => const SizedBox(
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
                                                            : () =>
                                                                  _removeImage(
                                                                    image,
                                                                  ),
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
                                                          () => _primaryImage =
                                                              image,
                                                        ),
                                                  icon: Icon(
                                                    identical(
                                                          _primaryImage,
                                                          image,
                                                        )
                                                        ? Symbols.check_circle
                                                        : Symbols
                                                              .radio_button_unchecked,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'Ảnh chính',
                                                  ),
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
                                          onPressed: _saving
                                              ? null
                                              : _pickImages,
                                          icon: const Icon(
                                            Symbols.add_photo_alternate,
                                          ),
                                          label: const Text('Thêm ảnh'),
                                        ),
                                      ),
                                    ],
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
                                TextButton(
                                  onPressed: widget.onClose,
                                  child: const Text('Hủy'),
                                ),
                                FilledButton.icon(
                                  onPressed: _saving ? null : _submit,
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
                                  icon: _saving
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Symbols.save, size: 18),
                                  label: Text(
                                    isEditing
                                        ? 'Lưu thay đổi'
                                        : 'Thêm biến thể',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
