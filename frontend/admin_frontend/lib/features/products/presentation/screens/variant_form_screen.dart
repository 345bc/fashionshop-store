import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/searchable_multi_select_field.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../../../../widgets/common/zella_toast.dart';
import '../providers/product_variants_provider.dart';

typedef _Combination = ({int sizeId, int colorId});
typedef _Options = ({
  List<Map<String, dynamic>> sizes,
  List<Map<String, dynamic>> colors,
  Set<_Combination> existing,
});

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
  late Future<_Options> _options;
  int? _sizeId;
  int? _colorId;
  final _sizeIds = <int>{};
  final _colorIds = <int>{};
  final _prices = <_Combination, String>{};
  late bool _isActive;
  bool _saving = false;
  bool _imagesLoading = false;
  String? _imagesError;
  final _editImages = _VariantImages();
  final _colorImages = <int, _VariantImages>{};
  int? _imageColorId;
  List<_VariantCreation>? _batch;
  int _processed = 0;

  _VariantImages? get _selectedImages {
    if (widget.variant != null) return _editImages;
    return _colorImages[_imageColorId];
  }

  @override
  void initState() {
    super.initState();
    final variant = widget.variant;
    _sizeId = (variant?['sizeId'] as num?)?.toInt();
    _colorId = (variant?['colorId'] as num?)?.toInt();
    _price = TextEditingController(text: variant?['price']?.toString() ?? '');
    _isActive = variant?['isActive'] == true || variant == null;
    _options = _loadOptions();
    if (variant != null) {
      _loadImages((variant['id'] as num).toInt());
    }
  }

  Future<_Options> _loadOptions() async {
    final provider = context.read<ProductVariantsProvider>();
    final (options, existing) = await (
      provider.loadOptions(),
      widget.variant == null
          ? provider.loadExistingCombinations(widget.productId)
          : Future.value(<_Combination>{}),
    ).wait;
    return (sizes: options.sizes, colors: options.colors, existing: existing);
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
        final imagesDraft = _editImages;
        imagesDraft.images
          ..clear()
          ..addAll(images.map(_VariantImageDraft.fromJson))
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        imagesDraft.primary =
            imagesDraft.images.where((image) => image.isPrimary).firstOrNull ??
            imagesDraft.images.firstOrNull;
      });
    } catch (error) {
      if (mounted) setState(() => _imagesError = error.toString());
    } finally {
      if (mounted) setState(() => _imagesLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final draft = _selectedImages;
    if (draft == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: true,
        withData: true,
      );
      if (!mounted ||
          _saving ||
          _batch != null ||
          result == null ||
          result.files.isEmpty) {
        return;
      }
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
            draft.images.fold<int>(
              -1,
              (maxOrder, image) =>
                  image.displayOrder > maxOrder ? image.displayOrder : maxOrder,
            ) +
            1;
        for (final file in result.files) {
          draft.images.add(
            _VariantImageDraft(file: file, displayOrder: nextOrder++),
          );
        }
        draft.primary ??= draft.images.first;
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

  void _removeImage(_VariantImageDraft image) {
    final draft = _selectedImages!;
    setState(() {
      if (image.id != null) draft.deletedIds.add(image.id!);
      draft.images.remove(image);
      if (identical(draft.primary, image)) {
        draft.primary = draft.images.firstOrNull;
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
    _VariantImages draft,
  ) async {
    final primary = draft.primary;
    for (final image in draft.images) {
      if (image.file == null) continue;
      final isPrimary = identical(image, primary);
      final uploaded = await provider.uploadImage(
        variantId: variantId,
        fileName: image.file!.name,
        bytes: image.file!.bytes!,
        isPrimary: isPrimary,
        displayOrder: image.displayOrder,
      );
      image.id = (uploaded['id'] as num).toInt();
      image.imageUrl = uploaded['imageUrl'] as String;
      image.file = null;
      if (isPrimary) {
        for (final item in draft.images) {
          item.isPrimary = identical(item, image);
        }
      }
    }
    if (primary != null && !primary.isPrimary) {
      await provider.updateImage(
        id: primary.id!,
        variantId: variantId,
        imageUrl: primary.imageUrl!,
        isPrimary: true,
        displayOrder: primary.displayOrder,
      );
      for (final image in draft.images) {
        image.isPrimary = identical(image, primary);
      }
    }
    for (final id in List<int>.of(draft.deletedIds)) {
      await provider.deleteImage(id);
      draft.deletedIds.remove(id);
    }
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Map<String, dynamic> _variantData(_Combination combination, double price) => {
    'productId': widget.productId,
    'sizeId': combination.sizeId,
    'colorId': combination.colorId,
    'price': price,
    'costPrice': widget.variant?['costPrice'] ?? 0,
    'stockQuantity': widget.variant?['stockQuantity'] ?? 0,
    'reservedQuantity': widget.variant?['reservedQuantity'] ?? 0,
    'isActive': _isActive,
  };

  Future<void> _submit(
    List<_Combination> combinations,
    Map<int, String> sizeNames,
    Map<int, String> colorNames,
  ) async {
    if (_saving) return;
    if (_imagesLoading || _imagesError != null) {
      ZellaToast.show(
        context,
        message: 'Chưa tải được ảnh biến thể. Vui lòng thử lại.',
        type: ToastType.warning,
      );
      return;
    }
    if (_batch == null && _formKey.currentState?.validate() != true) return;
    if (widget.variant == null && combinations.isEmpty && _batch == null) {
      ZellaToast.show(
        context,
        message: 'Các tổ hợp đã chọn đều có biến thể.',
        type: ToastType.warning,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final provider = context.read<ProductVariantsProvider>();
    try {
      final variant = widget.variant;
      if (variant != null) {
        final id = (variant['id'] as num).toInt();
        final combination = (sizeId: _sizeId!, colorId: _colorId!);
        final data = _variantData(
          combination,
          double.parse(_price.text.trim()),
        );
        await provider.updateItem(id, data, refresh: false);
        try {
          await _saveImages(provider, id, _editImages);
        } catch (error) {
          throw Exception('Biến thể đã lưu, nhưng ảnh chưa lưu xong: $error');
        }
      } else {
        _batch ??= [
          for (final combination in combinations)
            _VariantCreation(
              label:
                  '${sizeNames[combination.sizeId]} · ${colorNames[combination.colorId]}',
              data: _variantData(
                combination,
                double.tryParse(
                      combinations.length > 1
                          ? _prices[combination]?.trim() ?? ''
                          : '',
                    ) ??
                    double.parse(_price.text.trim()),
              ),
              images:
                  _colorImages[combination.colorId]?.copyForCreation() ??
                  _VariantImages(),
            ),
        ];
        if (!await _saveBatch(provider, _batch!)) return;
      }
      if (!mounted) return;
      ZellaToast.show(
        context,
        message: variant != null
            ? 'Cập nhật biến thể thành công'
            : 'Đã thêm ${_batch!.length} biến thể',
        type: ToastType.success,
      );
      widget.onClose();
    } catch (error) {
      if (mounted) {
        ZellaToast.show(
          context,
          message: 'Không thể hoàn tất lưu biến thể: $error',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _saveBatch(
    ProductVariantsProvider provider,
    List<_VariantCreation> batch,
  ) async {
    const parallelism = 3;
    final pending = batch.where((item) => !item.complete).toList();
    final errors = <String>[];
    _processed = batch.length - pending.length;
    for (
      var offset = 0;
      mounted && offset < pending.length;
      offset += parallelism
    ) {
      await Future.wait(
        pending.skip(offset).take(parallelism).map((item) async {
          try {
            if (item.id == null) {
              final created = await provider.createItem(
                item.data,
                refresh: false,
              );
              item.id = (created['id'] as num).toInt();
            }
            await _saveImages(provider, item.id!, item.images);
            item.complete = true;
          } catch (error) {
            item.error = error.toString();
            errors.add('${item.label}: $error');
          } finally {
            if (mounted) setState(() => _processed++);
          }
        }),
      );
    }
    if (!mounted) return false;
    if (errors.isEmpty) return true;
    final complete = batch.where((item) => item.complete).length;
    final created = batch.where((item) => item.id != null).length;
    if (created == 0) _batch = null;
    ZellaToast.show(
      context,
      message:
          'Đã lưu xong $complete/${batch.length} biến thể. ${errors.first}',
      type: created == 0 ? ToastType.error : ToastType.warning,
    );
    return false;
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
                              ? Column(
                                  children: [
                                    Text(
                                      'Không tải được dữ liệu biến thể: ${snapshot.error}',
                                    ),
                                    TextButton(
                                      onPressed: () => setState(
                                        () => _options = _loadOptions(),
                                      ),
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                )
                              : const CircularProgressIndicator(),
                        );
                      }
                      final options = snapshot.data!;
                      final sizeNames = _optionNames(options.sizes);
                      final colorNames = _optionNames(options.colors);
                      final combinations = [
                        for (final size in _sizeIds)
                          for (final color in _colorIds)
                            if (!options.existing.contains((
                              sizeId: size,
                              colorId: color,
                            )))
                              (sizeId: size, colorId: color),
                      ];
                      final skipped =
                          _sizeIds.length * _colorIds.length -
                          combinations.length;
                      final draft = _selectedImages;
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
                                      isEditing
                                          ? _singleChoice(
                                              sizeNames,
                                              _sizeId,
                                              'kích cỡ',
                                              (value) => setState(
                                                () => _sizeId = value,
                                              ),
                                            )
                                          : _choices(
                                              sizeNames,
                                              _sizeIds,
                                              'kích cỡ',
                                            ),
                                    ),
                                    _field(
                                      'Màu sắc *',
                                      _colorChoice(options.colors, isEditing),
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  _field(
                                    isEditing ? 'Giá bán *' : 'Giá bán chung *',
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
                                  if (!isEditing && skipped > 0)
                                    Text(
                                      'Bỏ qua $skipped tổ hợp đã có biến thể.',
                                    ),
                                  if (combinations.length > 1) ...[
                                    const SizedBox(height: 16),
                                    _variantPrices(
                                      combinations,
                                      sizeNames,
                                      colorNames,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _section(
                              'Ảnh biến thể',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!isEditing && _colorIds.isNotEmpty) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final id in _colorIds)
                                          _imageChoice(
                                            id,
                                            colorNames[id]!,
                                            _colorImages[id],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (draft == null)
                                    const Text('Chọn màu sắc để thêm ảnh.')
                                  else if (_imagesLoading)
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
                                    if (draft.images.isEmpty)
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
                                        for (final image in draft.images)
                                          Container(
                                            width: 150,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  identical(
                                                    draft.primary,
                                                    image,
                                                  )
                                                  ? AppTheme.surface
                                                  : Colors.white,
                                              border: Border.all(
                                                color:
                                                    identical(
                                                      draft.primary,
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
                                                          () => draft.primary =
                                                              image,
                                                        ),
                                                  icon: Icon(
                                                    identical(
                                                          draft.primary,
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
                                    if (draft.images.isNotEmpty) ...[
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
                            if (_batch != null && !_saving)
                              for (final item in _batch!.where(
                                (item) => !item.complete,
                              ))
                                Text(
                                  '${item.label}: ${item.error ?? 'Chưa lưu'}',
                                  style: const TextStyle(color: AppTheme.error),
                                ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                TextButton(
                                  onPressed: widget.onClose,
                                  child: Text(
                                    _batch == null ? 'Hủy' : 'Về danh sách',
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _submit(
                                          combinations,
                                          sizeNames,
                                          colorNames,
                                        ),
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
                                        : _saving && _batch != null
                                        ? 'Đã xử lý $_processed/${_batch!.length}'
                                        : _batch != null
                                        ? 'Thử lưu lại'
                                        : combinations.length > 1
                                        ? 'Thêm ${combinations.length} biến thể'
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

  Map<int, String> _optionNames(
    List<Map<String, dynamic>> items, {
    bool showCode = false,
  }) => {
    for (final item in items)
      (item['id'] as num).toInt(): showCode && item['code'] != null
          ? '${item['name']} (${item['code']})'
          : item['name']?.toString() ?? '',
  };

  Widget _singleChoice(
    Map<int, String> names,
    int? selected,
    String label,
    ValueChanged<int?> onChanged,
  ) => SearchableSelectField<int>(
    initialValue: selected,
    decoration: InputDecoration(hintText: 'Chọn $label'),
    items: [
      for (final entry in names.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: onChanged,
    validator: (value) => value == null ? 'Vui lòng chọn $label' : null,
  );

  Widget _colorChoice(List<Map<String, dynamic>> colors, bool isEditing) {
    final hexCodes = {
      for (final color in colors)
        (color['id'] as num).toInt(): color['hexCode'],
    };
    Widget? swatch(int id) => _colorSwatch(hexCodes[id]);

    if (!isEditing) {
      return _choices(
        _optionNames(colors),
        _colorIds,
        'màu sắc',
        leadingBuilder: swatch,
      );
    }
    final selected = _colorId;
    return SearchableMultiSelectField<int>(
      values: {?selected},
      decoration: const InputDecoration(hintText: 'Chọn màu sắc'),
      options: _optionNames(colors, showCode: true),
      leadingBuilder: swatch,
      singleSelection: true,
      validator: (values) =>
          values == null || values.isEmpty ? 'Vui lòng chọn màu sắc' : null,
      onChanged: (values) => setState(() => _colorId = values.single),
    );
  }

  Widget? _colorSwatch(Object? hexCode) {
    final hex = hexCode?.toString().trim() ?? '';
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    final rgb = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Color(0xFF000000 | rgb),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
    );
  }

  Widget _choices(
    Map<int, String> names,
    Set<int> selected,
    String label, {
    Widget? Function(int)? leadingBuilder,
  }) => SearchableMultiSelectField<int>(
    values: selected,
    decoration: InputDecoration(hintText: 'Chọn $label'),
    options: names,
    leadingBuilder: leadingBuilder,
    validator: (values) =>
        values == null || values.isEmpty ? 'Vui lòng chọn $label' : null,
    onChanged: (values) => setState(() {
      selected
        ..clear()
        ..addAll(values);
      if (identical(selected, _colorIds)) {
        for (final id in selected) {
          _colorImages.putIfAbsent(id, _VariantImages.new);
        }
        if (!selected.contains(_imageColorId)) {
          _imageColorId = selected.firstOrNull;
        }
      }
    }),
  );

  Widget _variantPrices(
    List<_Combination> combinations,
    Map<int, String> sizes,
    Map<int, String> colors,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Giá riêng theo biến thể'),
      const SizedBox(height: 8),
      for (final combination in combinations)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${sizes[combination.sizeId]} · ${colors[combination.colorId]}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey(combination),
                  initialValue: _prices[combination],
                  decoration: const InputDecoration(
                    hintText: 'Dùng giá chung',
                    suffixText: 'VND',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) => _prices[combination] = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? null
                      : _moneyValidator(value, positive: true),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _imageChoice(int id, String label, _VariantImages? draft) {
    final count = draft?.images.length ?? 0;
    return ChoiceChip(
      label: Text(count == 0 ? label : '$label ($count)'),
      selected: _imageColorId == id,
      onSelected: (_) => setState(() => _imageColorId = id),
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

  Widget _section(String title, Widget content) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE4E7EC)),
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
        Padding(
          padding: const EdgeInsets.all(24),
          child: ExcludeFocus(
            excluding: _saving || _batch != null,
            child: AbsorbPointer(absorbing: _batch != null, child: content),
          ),
        ),
      ],
    ),
  );
}

class _VariantCreation {
  final String label;
  final Map<String, dynamic> data;
  final _VariantImages images;
  int? id;
  bool complete = false;
  String? error;

  _VariantCreation({
    required this.label,
    required this.data,
    required this.images,
  });
}

class _VariantImages {
  final images = <_VariantImageDraft>[];
  final deletedIds = <int>[];
  _VariantImageDraft? primary;

  _VariantImages copyForCreation() {
    final copy = _VariantImages();
    for (final image in images) {
      final draft = _VariantImageDraft(
        file: image.file,
        displayOrder: image.displayOrder,
      );
      copy.images.add(draft);
      if (identical(image, primary)) copy.primary = draft;
    }
    return copy;
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
