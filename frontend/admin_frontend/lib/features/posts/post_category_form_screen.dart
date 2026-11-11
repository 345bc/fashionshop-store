import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';

class PostCategoryFormScreen extends StatefulWidget {
  const PostCategoryFormScreen({
    super.key,
    this.category,
    required this.onClose,
  });

  final Map<String, dynamic>? category;
  final VoidCallback onClose;

  @override
  State<PostCategoryFormScreen> createState() => _PostCategoryFormScreenState();
}

class _PostCategoryFormScreenState extends State<PostCategoryFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late bool _active;
  String? _thumbnail;
  Uint8List? _coverBytes;
  String? _coverName;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?['name']);
    _active = widget.category?['active'] ?? true;
    _thumbnail = widget.category?['thumbnail'];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final selected = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true,
      );
      if (!mounted || selected == null) return;
      final file = selected.files.single;
      if (file.bytes == null || file.size > 10 * 1024 * 1024) {
        setState(
          () => _error = 'Chọn ảnh JPG, PNG, GIF hoặc WebP tối đa 10 MB.',
        );
        return;
      }
      setState(() {
        _coverBytes = file.bytes;
        _coverName = file.name;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_coverBytes == null && (_thumbnail?.isNotEmpty != true)) {
      setState(() => _error = 'Vui lòng chọn ảnh bìa danh mục.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ApiClient();
      final bytes = _coverBytes;
      if (bytes != null) {
        final response = await api.post(
          '/admin/posts/images',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              bytes,
              filename: _coverName ?? 'category.jpg',
            ),
          }),
        );
        if (!mounted) return;
        _thumbnail = response.data['data']['url'] as String;
        _coverBytes = null;
      }
      final data = {
        'name': _name.text.trim(),
        'thumbnail': _thumbnail,
        'active': _active,
      };
      final category = widget.category;
      if (category == null) {
        await api.post('/admin/posts/categories', data: data);
      } else {
        await api.put('/admin/posts/categories/${category['id']}', data: data);
      }
      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _coverBytes;
    final thumbnail = _thumbnail;
    final hasCover = bytes != null || thumbnail?.isNotEmpty == true;
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
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Về danh sách danh mục bài viết',
                          onPressed: widget.onClose,
                          icon: const Icon(Symbols.arrow_back, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.category == null
                                ? 'Thêm danh mục bài viết'
                                : 'Chỉnh sửa danh mục bài viết',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _section('Thông tin danh mục', [
                      TextFormField(
                        controller: _name,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Tên danh mục *',
                          hintText: 'Nhập tên danh mục bài viết',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập tên danh mục'
                            : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hiển thị danh mục và bài viết'),
                        value: _active,
                        onChanged: (value) => setState(() => _active = value),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _section('Ảnh bìa', [
                      if (hasCover) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: bytes != null
                              ? Image.memory(
                                  bytes,
                                  width: 320,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  thumbnail!,
                                  width: 320,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Text('Không tải được ảnh bìa'),
                                ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _pickCover,
                        icon: const Icon(Symbols.add_photo_alternate),
                        label: Text(hasCover ? 'Đổi ảnh bìa' : 'Chọn ảnh bìa'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                          onPressed: _saving ? null : _save,
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
                          icon: const Icon(Symbols.save, size: 18),
                          label: Text(_saving ? 'Đang lưu…' : 'Lưu'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
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
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}
