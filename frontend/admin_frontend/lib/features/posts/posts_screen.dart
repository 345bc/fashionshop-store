import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import 'post_form_screen.dart';
import '../../widgets/common/action_menu.dart';
import '../../widgets/common/feature_header.dart';
import '../../widgets/common/feature_toolbar.dart';
import '../../widgets/common/filter_dropdown.dart';
import '../../widgets/common/pagination_footer.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/zella_checkbox.dart';

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
      MainScreen.of(context)
          .navigate('/posts/form', {'post': post, 'categories': _categories});
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
      text: postStatuses[status] ?? status,
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
