import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'post_rich_content.dart';

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/action_menu.dart';
import '../../widgets/common/feature_header.dart';
import '../../widgets/common/feature_toolbar.dart';
import '../../widgets/common/filter_dropdown.dart';
import '../../widgets/common/pagination_footer.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/zella_checkbox.dart';

const _statuses = {
  'DRAFT': 'Bản nháp',
  'PUBLISHED': 'Xuất bản / Hẹn giờ',
  'ARCHIVED': 'Đã ẩn',
};

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _api = ApiClient();
  final _search = TextEditingController();
  List<dynamic> _posts = [], _categories = [];
  int _page = 0, _pages = 0, _totalElements = 0, _generation = 0;
  String? _status, _error;
  int? _categoryFilter;
  bool _loading = true;
  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        _api.get(
          '/admin/posts',
          queryParameters: {
            'page': _page,
            'q': _search.text,
            if (_categoryFilter != null) 'categoryId': _categoryFilter,
            if (_status != null) 'status': _status,
          },
        ),
        _api.get('/admin/posts/categories'),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        final data = result[0].data['data'];
        _posts = data['content'] ?? [];
        _pages = data['totalPages'] ?? 1;
        _totalElements =
            (data['totalElements'] as num?)?.toInt() ?? _posts.length;
        _categories = result[1].data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _message(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    try {
      Map<String, dynamic>? post;
      if (row != null) {
        post = Map<String, dynamic>.from(
          (await _api.get('/admin/posts/${row['id']}')).data['data'],
        );
      }
      if (!mounted) return;
      final changed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PostEditor(post: post, categories: _categories),
      );
      if (changed == true) _load();
    } catch (e) {
      _message(e);
    }
  }

  Future<void> _delete(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bản nháp?'),
        content: Text(post['title']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/admin/posts/${post['id']}');
      if (_posts.length == 1 && _page > 0) _page--;
      _load();
    } catch (e) {
      _message(e);
    }
  }

  Text _headerText(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    ),
  );

  Widget _buildStatusBadge(String status, bool isScheduled) {
    if (status == 'PUBLISHED') {
      if (isScheduled) {
        return StatusBadge(
          text: 'Hẹn giờ',
          textColor: AppTheme.info,
          backgroundColor: AppTheme.info.withAlpha(25),
        );
      }
      return StatusBadge(
        text: 'Xuất bản',
        textColor: AppTheme.success,
        backgroundColor: AppTheme.success.withAlpha(25),
      );
    } else if (status == 'DRAFT') {
      return StatusBadge(
        text: 'Bản nháp',
        textColor: AppTheme.warning,
        backgroundColor: AppTheme.warning.withAlpha(25),
      );
    } else if (status == 'ARCHIVED') {
      return StatusBadge(
        text: 'Đã ẩn',
        textColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.textSecondary.withAlpha(25),
      );
    }
    return StatusBadge(
      text: _statuses[status] ?? status,
      textColor: AppTheme.textSecondary,
      backgroundColor: AppTheme.surface,
    );
  }

  Widget _buildPostRow(Map<String, dynamic> post) {
    final id = (post['id'] as num).toInt();
    final title = (post['title'] as String?) ?? '';
    final slug = (post['slug'] as String?) ?? '';
    final categoryName = (post['categoryName'] as String?) ?? 'Chưa phân loại';
    final viewCount = (post['viewCount'] as num?)?.toInt() ?? 0;
    final status = (post['status'] as String?) ?? 'DRAFT';
    final thumbnail = post['thumbnail'] as String?;
    final publishedAtStr = post['publishedAt'] as String?;
    final createdAtStr = post['createdAt'] as String?;

    DateTime? publishedDate;
    if (publishedAtStr != null && publishedAtStr.isNotEmpty) {
      try {
        publishedDate = DateTime.parse(publishedAtStr).toLocal();
      } catch (_) {}
    }

    DateTime? createdDate;
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        createdDate = DateTime.parse(createdAtStr).toLocal();
      } catch (_) {}
    }

    final isScheduled =
        status == 'PUBLISHED' &&
        publishedDate != null &&
        publishedDate.isAfter(DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _edit(post),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              ZellaCheckbox(
                value: selectedIds.contains(id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);
                    }
                  });
                },
              ),
              const SizedBox(width: 16),
              // Cột 1: BÀI VIẾT (Ảnh thumbnail + Tiêu đề + Slug)
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: thumbnail != null && thumbnail.isNotEmpty
                          ? Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Symbols.article,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            )
                          : const Icon(
                              Symbols.article,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.text,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slug.isNotEmpty ? '/$slug' : '#$id',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Cột 2: CHUYÊN MỤC
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.folder,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Cột 3: LƯỢT ĐỌC & NGÀY
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.visibility,
                          size: 15,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$viewCount lượt đọc',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      publishedDate != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(publishedDate)
                          : (createdDate != null
                                ? DateFormat('dd/MM/yyyy').format(createdDate)
                                : 'Chưa có'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Cột 4: TRẠNG THÁI
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(status, isScheduled),
                ),
              ),
              // Cột 5: ACTION MENU
              SizedBox(
                width: 48,
                child: ActionMenu(
                  items: [
                    const ActionMenuItem(
                      value: 'edit',
                      label: 'Chỉnh sửa',
                      icon: Symbols.edit,
                    ),
                    if (status == 'DRAFT')
                      const ActionMenuItem(
                        value: 'delete',
                        label: 'Xóa bản nháp',
                        icon: Symbols.delete,
                        color: AppTheme.danger,
                      ),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') {
                      _edit(post);
                    } else if (val == 'delete') {
                      _delete(post);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureHeader(
            title: 'Bài viết',
            subtitle: 'Quản lý bài viết và nội dung blog / tin tức',
            actionLabel: 'Viết bài',
            actionIcon: Symbols.add,
            onActionPressed: () => _edit(),
            secondaryAction: IconButton(
              onPressed: _load,
              tooltip: 'Tải lại',
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 32),
          FeatureToolbar(
            searchHint: 'Tìm kiếm bài viết theo tiêu đề...',
            initialSearchText: _search.text,
            maxSearchLength: 255,
            onSearchChanged: (query) {
              if (!mounted) return;
              _search.text = query;
              _page = 0;
              _load();
            },
            filterWidget: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterDropdown<int>(
                  label: 'Chuyên mục',
                  searchHint: 'Tìm kiếm chuyên mục',
                  value: _categoryFilter ?? 0,
                  defaultValue: 0,
                  options: [
                    const FilterOption<int>(
                      value: 0,
                      label: 'Tất cả chuyên mục',
                    ),
                    ..._categories.map(
                      (c) => FilterOption<int>(
                        value: (c['id'] as num).toInt(),
                        label: c['name'],
                      ),
                    ),
                  ],
                  onChanged: (id) {
                    _categoryFilter = id == 0 ? null : id;
                    _page = 0;
                    _load();
                  },
                ),
                FilterDropdown<String>(
                  label: 'Trạng thái',
                  searchHint: 'Tìm kiếm trạng thái',
                  value: _status ?? '',
                  defaultValue: '',
                  options: const [
                    FilterOption<String>(value: '', label: 'Tất cả trạng thái'),
                    FilterOption<String>(
                      value: 'PUBLISHED',
                      label: 'Xuất bản / Hẹn giờ',
                      icon: Symbols.check_circle,
                      iconColor: AppTheme.success,
                    ),
                    FilterOption<String>(
                      value: 'DRAFT',
                      label: 'Bản nháp',
                      icon: Symbols.edit_document,
                      iconColor: AppTheme.warning,
                    ),
                    FilterOption<String>(
                      value: 'ARCHIVED',
                      label: 'Đã ẩn',
                      icon: Symbols.archive,
                      iconColor: AppTheme.textSecondary,
                    ),
                  ],
                  onChanged: (value) {
                    _status = value.isEmpty ? null : value;
                    _page = 0;
                    _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lỗi: $_error',
                            style: const TextStyle(color: AppTheme.danger),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          ZellaCheckbox(
                            value:
                                _posts.isNotEmpty &&
                                selectedIds.length == _posts.length,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedIds = _posts
                                      .map((p) => (p['id'] as num).toInt())
                                      .toSet();
                                } else {
                                  selectedIds.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: _headerText('BÀI VIẾT')),
                          Expanded(flex: 2, child: _headerText('CHUYÊN MỤC')),
                          Expanded(
                            flex: 2,
                            child: _headerText('LƯỢT ĐỌC & NGÀY'),
                          ),
                          Expanded(flex: 2, child: _headerText('TRẠNG THÁI')),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_posts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: Text(
                            'Không tìm thấy bài viết nào phù hợp.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _posts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _buildPostRow(
                          Map<String, dynamic>.from(_posts[index]),
                        ),
                      ),
                    const Divider(height: 1),
                    PaginationFooter(
                      currentPage: _page,
                      totalPages: _pages,
                      totalElements: _totalElements,
                      pageSize: 20,
                      onPageChanged: (page) {
                        setState(() {
                          _page = page;
                        });
                        _load();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

String? _required(String? v) =>
    v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung' : null;

class _PostEditor extends StatefulWidget {
  final Map<String, dynamic>? post;
  final List<dynamic> categories;
  const _PostEditor({this.post, required this.categories});
  @override
  State<_PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<_PostEditor> {
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
      if (mounted) {
        setState(() => _saving = false);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, true);
      }
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

  Widget _section(String title, String subtitle, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      );

  Widget _writingPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        'Nội dung bài viết',
        'Đặt tiêu đề rõ ràng và viết phần giới thiệu ngắn gọn để thu hút người đọc.',
        [
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
        ],
      ),
      const SizedBox(height: 20),
      _section(
        'Soạn thảo',
        'Định dạng nội dung và chèn ảnh ngay tại vị trí đang viết.',
        [
          PostRichEditor(
            controller: _content,
            disabled: _saving,
            onUploading: (busy) => setState(() => _uploadingInline = busy),
          ),
        ],
      ),
    ],
  );

  Widget _settingsPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section('Xuất bản', 'Chọn chuyên mục và cách hiển thị bài viết.', [
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
          items: _statuses.entries
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
      _section(
        'Ảnh bìa',
        'Ảnh đại diện xuất hiện trên danh sách bài viết và banner trang chủ.',
        [_coverPicker()],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _uploadingInline;
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: !busy,
      child: Dialog(
        insetPadding: EdgeInsets.all(size.width < 700 ? 12 : 28),
        backgroundColor: AppTheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 1320,
          height: size.height * .94,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    const Icon(Symbols.edit_document, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post == null
                                ? 'Viết bài mới'
                                : 'Chỉnh sửa bài viết',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Biên tập nội dung và quản lý xuất bản',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Symbols.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _form,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: EdgeInsets.all(
                        constraints.maxWidth < 700 ? 16 : 24,
                      ),
                      child: constraints.maxWidth >= 1000
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _writingPanel()),
                                const SizedBox(width: 24),
                                SizedBox(width: 340, child: _settingsPanel()),
                              ],
                            )
                          : Column(
                              children: [
                                _writingPanel(),
                                const SizedBox(height: 20),
                                _settingsPanel(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: busy ? null : () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _preview,
                          icon: const Icon(Symbols.visibility, size: 18),
                          label: const Text('Xem trước'),
                        ),
                        FilledButton.icon(
                          onPressed: busy ? null : _save,
                          icon: const Icon(Symbols.check, size: 18),
                          label: Text(_saving ? 'Đang lưu…' : 'Lưu bài viết'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
