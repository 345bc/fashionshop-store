import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';
import 'post_rich_content.dart';

const postStatuses = {
  'DRAFT': 'Bản nháp',
  'PUBLISHED': 'Xuất bản / Hẹn giờ',
  'ARCHIVED': 'Đã ẩn',
};

String? _required(String? v) =>
    v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung' : null;

class PostFormScreen extends StatefulWidget {
  final Map<String, dynamic>? post;
  final List<dynamic> categories;
  final VoidCallback onClose;

  const PostFormScreen({
    super.key,
    this.post,
    required this.categories,
    required this.onClose,
  });
  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late final quill.QuillController _content;
  bool _uploadingInline = false;
  late String _status;
  int? _categoryId;
  Uint8List? _coverBytes;
  String? _coverName;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _fields = {
      for (final key in ['title', 'summary', 'thumbnail', 'publishedAt'])
        key: TextEditingController(
          text: key == 'publishedAt' && widget.post?[key] != null
              ? DateFormat("yyyy-MM-dd'T'HH:mm")
                    .format(DateTime.parse(widget.post![key]).toLocal())
              : widget.post?[key]?.toString() ?? '',
        ),
    };
    _content = quill.QuillController(
      document: loadPostDocument(widget.post?['content'] ?? ''),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _status = widget.post?['status'] ?? 'DRAFT';
    _categoryId = widget.post?['categoryId'];
  }

  @override
  void dispose() {
    _content.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPublishedAt() async {
    final now = DateTime.now();
    DateTime initial = now;
    final currentText = _fields['publishedAt']!.text.trim();
    if (currentText.isNotEmpty) {
      final parsed = DateTime.tryParse(currentText);
      if (parsed != null) initial = parsed;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày hẹn giờ xuất bản',
      confirmText: 'Tiếp tục',
      cancelText: 'Hủy',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: 'Chọn giờ xuất bản',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _fields['publishedAt']!.text = DateFormat("yyyy-MM-dd'T'HH:mm")
          .format(selected);
    });
  }

  Future<void> _pickCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('Không đọc được ảnh đã chọn');
      }
      setState(() {
        _coverBytes = file.bytes;
        _coverName = file.name;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể chọn ảnh: $e');
    }
  }

  Widget _coverPicker() => FormField<String>(
    validator: (_) => _coverBytes == null && _fields['thumbnail']!.text.isEmpty
        ? 'Vui lòng chọn ảnh bìa'
        : null,
    builder: (field) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_coverBytes != null || _fields['thumbnail']!.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: _coverBytes != null
                      ? Image.memory(
                          _coverBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => const Center(
                            child: Text('Không xem trước được ảnh'),
                          ),
                        )
                      : Image.network(
                          _fields['thumbnail']!.text,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => const Center(
                            child: Text(
                              'Không tải được ảnh bìa. Bạn có thể chọn ảnh khác.',
                            ),
                          ),
                        ),
                ),
              ),
            ),
          if (_coverBytes == null && _fields['thumbnail']!.text.isEmpty)
            Container(
              width: double.infinity,
              height: 150,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.add_photo_alternate,
                    size: 32,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Chưa có ảnh bìa',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    await _pickCover();
                    if (mounted && _coverBytes != null) {
                      field.didChange(_coverName);
                    }
                  },
            icon: const Icon(Icons.upload_outlined),
            label: Text(
              _coverBytes != null || _fields['thumbnail']!.text.isNotEmpty
                  ? 'Đổi ảnh bìa'
                  : 'Chọn ảnh bìa',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _coverName ?? 'JPG, PNG, GIF hoặc WebP',
            overflow: TextOverflow.ellipsis,
          ),
          if (_coverBytes != null)
            const Text('Ảnh sẽ được tải lên khi lưu bài viết.'),
          if (field.errorText != null)
            Text(
              field.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );

  Future<void> _preview() async {
    final preview = quill.QuillController(
      document: quill.Document.fromJson(_content.document.toDelta().toJson()),
      selection: const TextSelection.collapsed(offset: 0),
    )..readOnly = true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xem trước bài viết'),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fields['title']!.text,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (_coverBytes != null)
                  Image.memory(
                    _coverBytes!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else if (_fields['thumbnail']!.text.isNotEmpty)
                  Image.network(
                    _fields['thumbnail']!.text,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const Text('Không tải được ảnh bìa'),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _fields['summary']!.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                quill.QuillEditor.basic(
                  controller: preview,
                  config: const quill.QuillEditorConfig(
                    scrollable: false,
                    embedBuilders: [PostImageEmbedBuilder()],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
    // Let the dialog finish its closing animation before disposing its editor.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    preview.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _content.readOnly = true;
      _error = null;
    });
    try {
      if (_coverBytes != null) {
        final response = await ApiClient().post(
          '/admin/posts/images',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              _coverBytes!,
              filename: _coverName ?? 'cover.jpg',
            ),
          }),
        );
        final url = response.data['data']['url'] as String;
        if (!mounted) return;
        setState(() {
          _fields['thumbnail']!.text = url;
          _coverBytes = null;
          _coverName = null;
        });
      }
      final time = _fields['publishedAt']!.text.trim();
      final data = {
        for (final key in ['title', 'summary', 'thumbnail'])
          key: _fields[key]!.text.trim(),
        'content': encodePostDocument(_content.document),
        'categoryId': _categoryId,
        'status': _status,
        'publishedAt': _status == 'PUBLISHED' && time.isNotEmpty
            ? DateTime.parse(time).toUtc().toIso8601String()
            : null,
      };
      if (widget.post == null) {
        await ApiClient().post('/admin/posts', data: data);
      } else {
        await ApiClient().put('/admin/posts/${widget.post!['id']}', data: data);
      }
      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _content.readOnly = false;
          _error = e.toString();
        });
      }
    }
  }

  InputDecoration _input(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
  );

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    ),
  );

  Widget _writingPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section('Nội dung bài viết', [
        TextFormField(
          controller: _fields['title'],
          enabled: !_saving,
          minLines: 1,
          maxLines: 3,
          maxLength: 255,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          decoration: _input('Tiêu đề *', hint: 'Nhập tiêu đề bài viết'),
          validator: _required,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fields['summary'],
          enabled: !_saving,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: _input(
            'Tóm tắt',
            hint: 'Giới thiệu nội dung chính của bài viết…',
          ),
        ),
      ]),
      const SizedBox(height: 20),
      _section('Soạn thảo', [
        PostRichEditor(
          controller: _content,
          disabled: _saving,
          onUploading: (busy) => setState(() => _uploadingInline = busy),
        ),
      ]),
    ],
  );

  Widget _settingsPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section('Xuất bản', [
        DropdownButtonFormField<int>(
          initialValue: _categoryId,
          isExpanded: true,
          decoration: _input('Danh mục *'),
          items: widget.categories
              .map(
                (c) => DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(
                    '${c['name']}${c['active'] == true ? '' : ' (ẩn)'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _saving ? null : (v) => setState(() => _categoryId = v),
          validator: (v) => v == null ? 'Chọn danh mục' : null,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _status,
          isExpanded: true,
          decoration: _input('Trạng thái'),
          items: postStatuses.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: _saving ? null : (v) => setState(() => _status = v!),
        ),
        if (_status == 'PUBLISHED') ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: _fields['publishedAt'],
            readOnly: true,
            enabled: !_saving,
            onTap: _saving ? null : _pickPublishedAt,
            decoration: _input('Ngày giờ xuất bản', hint: 'Đăng ngay khi lưu')
                .copyWith(
                  prefixIcon: const Icon(Symbols.schedule, size: 20),
                  suffixIcon: IconButton(
                    tooltip: _fields['publishedAt']!.text.isEmpty
                        ? 'Chọn ngày giờ'
                        : 'Xóa hẹn giờ',
                    icon: Icon(
                      _fields['publishedAt']!.text.isEmpty
                          ? Symbols.calendar_month
                          : Symbols.close,
                      size: 20,
                    ),
                    onPressed: _saving
                        ? null
                        : () {
                            if (_fields['publishedAt']!.text.isEmpty) {
                              _pickPublishedAt();
                            } else {
                              setState(() => _fields['publishedAt']!.clear());
                            }
                          },
                  ),
                ),
            validator: (v) =>
                v == null ||
                    v.trim().isEmpty ||
                    DateTime.tryParse(v.trim()) != null
                ? null
                : 'Thời gian không hợp lệ',
          ),
          const SizedBox(height: 10),
          const Text(
            'Để trống để đăng ngay. Chọn thời gian trong tương lai để hẹn giờ xuất bản.',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ]),
      const SizedBox(height: 20),
      _section('Ảnh bìa', [_coverPicker()]),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _uploadingInline;
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
                        tooltip: 'Về danh sách bài viết',
                        onPressed: busy ? null : widget.onClose,
                        icon: const Icon(Symbols.arrow_back, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.post == null
                              ? 'Viết bài mới'
                              : 'Chỉnh sửa bài viết',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (box.maxWidth >= 1000)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _writingPanel()),
                        const SizedBox(width: 24),
                        SizedBox(width: 340, child: _settingsPanel()),
                      ],
                    )
                  else ...[
                    _writingPanel(),
                    const SizedBox(height: 24),
                    _settingsPanel(),
                  ],
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
                        onPressed: busy ? null : widget.onClose,
                        child: const Text('Hủy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _preview,
                        icon: const Icon(Symbols.visibility, size: 18),
                        label: const Text('Xem trước'),
                      ),
                      FilledButton.icon(
                        onPressed: busy ? null : _save,
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
                        label: Text(_saving ? 'Đang lưu…' : 'Lưu bài viết'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
