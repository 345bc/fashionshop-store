import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';
import '../../../sizeguides/presentation/providers/size_guides_provider.dart';
import '../../data/attribute_kind.dart';
import '../providers/attribute_provider.dart';

class AttributeFormDialog extends StatefulWidget {
  final AttributeKind kind;
  final Map<String, dynamic>? item;
  const AttributeFormDialog({super.key, required this.kind, this.item});

  @override
  State<AttributeFormDialog> createState() => _AttributeFormDialogState();
}

class _AttributeFormDialogState extends State<AttributeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _hex;
  late final TextEditingController _order;
  late final TextEditingController _description;
  String? _currentImageUrl;
  PlatformFile? _selectedImage;
  bool _removeImage = false;
  int? _createdGuideId;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?['name']?.toString() ?? '');
    _code = TextEditingController(text: item?['code']?.toString() ?? '');
    _hex = TextEditingController(text: item?['hexCode']?.toString() ?? '');
    _order = TextEditingController(
      text: item?['displayOrder']?.toString() ?? '0',
    );
    _description = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );
    _currentImageUrl = item?['guideImageUrl'] as String?;
    _isActive = item?['isActive'] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _hex.dispose();
    _order.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    var detailsSaved = false;
    try {
      final Map<String, dynamic> data;
      switch (widget.kind) {
        case AttributeKind.color:
          data = {
            'name': _name.text.trim(),
            'code': _code.text.trim().toUpperCase(),
            'hexCode': _hex.text.trim().toUpperCase(),
          };
        case AttributeKind.size:
          data = {
            'name': _name.text.trim(),
            'displayOrder': int.parse(_order.text.trim()),
          };
        case AttributeKind.sizeGuide:
          data = {
            'name': _name.text.trim(),
            'description': _description.text.trim(),
            'guideImageUrl': _currentImageUrl,
            'isActive': _isActive,
          };
      }
      final provider = context.read<AttributeProvider>();
      if (widget.item == null) {
        if (_createdGuideId == null) {
          final created = await provider.create(data);
          if (widget.kind == AttributeKind.sizeGuide) {
            _createdGuideId = (created['id'] as num).toInt();
          }
        } else {
          await provider.update(_createdGuideId!, data);
        }
      } else {
        await provider.update((widget.item!['id'] as num).toInt(), data);
      }
      detailsSaved = true;
      if (widget.kind == AttributeKind.sizeGuide) {
        final guideId = _createdGuideId ?? (widget.item!['id'] as num).toInt();
        if (_selectedImage != null) {
          final updated = await provider.uploadSizeGuideImage(
            guideId,
            _selectedImage!.name,
            _selectedImage!.bytes!,
          );
          _currentImageUrl = updated['guideImageUrl'] as String?;
          _selectedImage = null;
          await provider.load();
        } else if (_removeImage) {
          await provider.removeSizeGuideImage(guideId);
          _currentImageUrl = null;
          _removeImage = false;
          await provider.load();
        }
      }
      if (!mounted) return;
      if (widget.kind == AttributeKind.sizeGuide) {
        context.read<SizeGuidesProvider>().loadItems();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null ? 'Thêm thành công' : 'Cập nhật thành công',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detailsSaved && widget.kind == AttributeKind.sizeGuide
                  ? 'Thông tin Size Guide đã lưu, nhưng ảnh chưa lưu xong: $error'
                  : 'Không thể lưu ${widget.kind.singular}: $error',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null || file.size == 0 || file.size > 10485760) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh cần có dung lượng từ 1 byte đến 10 MB.'),
          ),
        );
        return;
      }
      setState(() {
        _selectedImage = file;
        _removeImage = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $error')));
      }
    }
  }

  String _imageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.origin + (url.startsWith('/') ? url : '/$url');
  }

  String? _required(String? value, int limit) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập thông tin';
    return text.length > limit ? 'Tối đa $limit ký tự' : null;
  }

  @override
  Widget build(BuildContext context) {
    return ZellaFormDialog(
      title: widget.item == null
          ? 'Thêm ${widget.kind.singular}'
          : 'Chỉnh sửa ${widget.kind.singular}',
      width: 560,
      isLoading: _saving,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _save,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.kind == AttributeKind.size)
                DropdownButtonFormField<String>(
                  initialValue: _name.text.isEmpty ? null : _name.text,
                  decoration: const InputDecoration(labelText: 'Size *'),
                  items: const ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _name.text = value ?? '',
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn size' : null,
                )
              else
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Tên ${widget.kind.singular} *',
                  ),
                  validator: (value) => _required(
                    value,
                    widget.kind == AttributeKind.color ? 50 : 100,
                  ),
                ),
              const SizedBox(height: 18),
              if (widget.kind == AttributeKind.color) ...[
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Mã màu *',
                    hintText: 'BLK',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Vui lòng nhập mã màu';
                    return RegExp(r'^[A-Za-z0-9_-]{1,10}$').hasMatch(text)
                        ? null
                        : 'Tối đa 10 ký tự: chữ, số, _ hoặc -';
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _hex,
                  decoration: const InputDecoration(
                    labelText: 'Mã HEX',
                    hintText: '#000000',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    return text.isEmpty ||
                            RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(text)
                        ? null
                        : 'Mã HEX phải có dạng #RRGGBB';
                  },
                ),
              ],
              if (widget.kind == AttributeKind.size)
                TextFormField(
                  controller: _order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thứ tự hiển thị *',
                  ),
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');
                    return number == null || number < 0
                        ? 'Nhập số nguyên từ 0 trở lên'
                        : null;
                  },
                ),
              if (widget.kind == AttributeKind.sizeGuide) ...[
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  validator: (value) =>
                      (value?.length ?? 0) > 500 ? 'Tối đa 500 ký tự' : null,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ảnh hướng dẫn',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (_selectedImage != null)
                  Image.memory(
                    _selectedImage!.bytes!,
                    height: 180,
                    fit: BoxFit.contain,
                  )
                else if (_currentImageUrl != null && !_removeImage)
                  Image.network(
                    _imageUrl(_currentImageUrl!),
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 120,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                if (_selectedImage == null &&
                    (_currentImageUrl == null || _removeImage))
                  const Text('Chưa có ảnh hướng dẫn.'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _currentImageUrl == null
                            ? 'Chọn ảnh từ máy'
                            : 'Thay ảnh',
                      ),
                    ),
                    if (_selectedImage != null ||
                        (_currentImageUrl != null && !_removeImage))
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _selectedImage = null;
                                _removeImage = _currentImageUrl != null;
                              }),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xóa ảnh'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hoạt động'),
                  value: _isActive,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
