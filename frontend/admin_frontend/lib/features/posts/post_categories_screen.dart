import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/action_menu.dart';
import '../../widgets/common/feature_header.dart';
import '../../widgets/common/feature_toolbar.dart';
import '../../widgets/common/filter_dropdown.dart';
import '../../widgets/common/pagination_footer.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/zella_checkbox.dart';

class PostCategoriesScreen extends StatefulWidget {
  const PostCategoriesScreen({super.key});

  @override
  State<PostCategoriesScreen> createState() => _PostCategoriesScreenState();
}

class _PostCategoriesScreenState extends State<PostCategoriesScreen> {
  final _api = ApiClient();
  List<dynamic> _categories = [];
  String _searchQuery = '';
  String _status = 'all';
  int _page = 0;
  final int _pageSize = 10;
  bool _loading = true;
  String? _error;
  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/admin/posts/categories');
      if (!mounted) return;
      setState(() {
        _categories = res.data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    return _categories.map((e) => Map<String, dynamic>.from(e)).where((c) {
      final query = _searchQuery.toLowerCase().trim();
      final name = (c['name'] ?? '').toString().toLowerCase();
      final slug = (c['slug'] ?? '').toString().toLowerCase();
      final matchesQuery =
          query.isEmpty || name.contains(query) || slug.contains(query);

      final isActive = c['active'] == true;
      final matchesStatus = switch (_status) {
        'active' => isActive,
        'inactive' => !isActive,
        _ => true,
      };
      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get _totalPages =>
      (_filteredCategories.length / _pageSize).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> get _pagedCategories {
    final start = _page * _pageSize;
    if (start >= _filteredCategories.length) return [];
    final end = (start + _pageSize).clamp(0, _filteredCategories.length);
    return _filteredCategories.sublist(start, end);
  }

  Future<void> _toggleStatus(Map<String, dynamic> cat) async {
    try {
      final newActive = !(cat['active'] == true);
      await _api.put(
        '/admin/posts/categories/${cat['id']}',
        data: {
          'name': cat['name'],
          'thumbnail': cat['thumbnail'],
          'active': newActive,
        },
      );
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newActive
                  ? 'Đã kích hoạt danh mục "${cat['name']}"'
                  : 'Đã ẩn danh mục "${cat['name']}"',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _openDialog([Map<String, dynamic>? category]) async {
    final name = TextEditingController(text: category?['name']);
    bool active = category?['active'] ?? true;
    String? thumbnail = category?['thumbnail'];
    Uint8List? coverBytes;
    String? coverName;
    bool saving = false;
    String? error;
    final form = GlobalKey<FormState>();

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        enabled: !saving,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Tên danh mục *',
                          hintText: 'Nhập tên danh mục bài viết',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập tên danh mục'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (coverBytes != null || thumbnail != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: coverBytes != null
                              ? Image.memory(
                                  coverBytes!,
                                  height: 145,
                                  width: 440,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  thumbnail!,
                                  height: 145,
                                  width: 440,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Text('Không tải được ảnh bìa'),
                                    ),
                                  ),
                                ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          coverBytes != null || thumbnail != null
                              ? 'Đổi ảnh bìa danh mục'
                              : 'Chọn ảnh bìa danh mục',
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                try {
                                  final selected = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: [
                                          'jpg',
                                          'jpeg',
                                          'png',
                                          'gif',
                                          'webp',
                                        ],
                                        withData: true,
                                      );
                                  if (selected == null || !context.mounted) {
                                    return;
                                  }
                                  final file = selected.files.single;
                                  if (file.bytes == null ||
                                      file.size > 10 * 1024 * 1024) {
                                    update(
                                      () => error = 'Chọn ảnh JPG, PNG, GIF hoặc WebP tối đa 10 MB.',
                                    );
                                    return;
                                  }
                                  update(() {
                                    coverBytes = file.bytes;
                                    coverName = file.name;
                                    error = null;
                                  });
                                } catch (e) {
                                  if (context.mounted) {
                                    update(() => error = e.toString());
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hiển thị danh mục và bài viết'),
                        value: active,
                        onChanged: saving
                            ? null
                            : (v) => update(() => active = v),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (coverBytes == null &&
                            (thumbnail == null || thumbnail!.isEmpty)) {
                          update(
                            () => error = 'Vui lòng chọn ảnh bìa danh mục.',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          if (coverBytes != null) {
                            final response = await _api.post(
                              '/admin/posts/images',
                              data: FormData.fromMap({
                                'file': MultipartFile.fromBytes(
                                  coverBytes!,
                                  filename: coverName ?? 'category.jpg',
                                ),
                              }),
                            );
                            thumbnail = response.data['data']['url'] as String;
                            coverBytes = null;
                          }
                          final data = {
                            'name': name.text.trim(),
                            'thumbnail': thumbnail,
                            'active': active,
                          };
                          if (category == null) {
                            await _api.post(
                              '/admin/posts/categories',
                              data: data,
                            );
                          } else {
                            await _api.put(
                              '/admin/posts/categories/${category['id']}',
                              data: data,
                            );
                          }
                          if (dialogContext.mounted) {
                            update(() => saving = false);
                            await WidgetsBinding.instance.endOfFrame;
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            update(() {
                              saving = false;
                              error = e.toString();
                            });
                          }
                        }
                      },
                child: Text(saving ? 'Đang lưu…' : 'Lưu'),
              ),
            ],
          ),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    if (changed == true && mounted) _loadCategories();
  }

  Text _header(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    ),
  );

  Widget _row(Map<String, dynamic> category) {
    final id = (category['id'] as num).toInt();
    final isActive = category['active'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDialog(category),
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
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: category['thumbnail'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                category['thumbnail'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Symbols.folder,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                            )
                          : const Icon(
                              Symbols.folder,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      category['slug'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    text: isActive ? 'Hoạt động' : 'Đã ẩn',
                    textColor: isActive ? AppTheme.success : AppTheme.danger,
                    backgroundColor:
                        (isActive ? AppTheme.success : AppTheme.danger)
                            .withAlpha(25),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: ActionMenu(
                  items: [
                    const ActionMenuItem(
                      value: 'edit',
                      label: 'Chỉnh sửa',
                      icon: Symbols.edit,
                    ),
                    ActionMenuItem(
                      value: 'toggle',
                      label: isActive ? 'Ẩn danh mục' : 'Kích hoạt',
                      icon: isActive
                          ? Symbols.visibility_off
                          : Symbols.visibility,
                      color: isActive ? AppTheme.warning : AppTheme.success,
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openDialog(category);
                    } else if (value == 'toggle') {
                      _toggleStatus(category);
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
  Widget build(BuildContext context) {
    final visible = _pagedCategories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeatureHeader(
              title: 'Danh mục bài viết',
              subtitle:
                  'Quản lý cấu trúc danh mục bài viết và phân loại tin tức',
              actionLabel: 'Thêm danh mục',
              actionIcon: Symbols.add,
              onActionPressed: () => _openDialog(),
              secondaryAction: IconButton(
                onPressed: _loadCategories,
                tooltip: 'Tải lại',
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 32),
            FeatureToolbar(
              searchHint: 'Tìm kiếm danh mục theo tên hoặc slug',
              initialSearchText: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _page = 0;
                });
              },
              filterWidget: FilterDropdown<String>(
                label: 'Trạng thái',
                searchHint: 'Tìm trạng thái',
                value: _status,
                defaultValue: 'all',
                options: const [
                  FilterOption(value: 'all', label: 'Tất cả trạng thái'),
                  FilterOption(
                    value: 'active',
                    label: 'Hoạt động',
                    icon: Symbols.check_circle,
                    iconColor: AppTheme.success,
                  ),
                  FilterOption(
                    value: 'inactive',
                    label: 'Đã ẩn',
                    icon: Symbols.cancel,
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value;
                    _page = 0;
                  });
                },
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
                              style: const TextStyle(color: AppTheme.error),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _loadCategories,
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
                                  visible.isNotEmpty &&
                                  selectedIds.length == visible.length,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedIds = visible
                                        .map((e) => (e['id'] as num).toInt())
                                        .toSet();
                                  } else {
                                    selectedIds.clear();
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _header('DANH MỤC')),
                            Expanded(
                              flex: 3,
                              child: _header('SLUG'),
                            ),
                            Expanded(flex: 2, child: _header('TRẠNG THÁI')),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(
                            child: Text(
                              'Không có dữ liệu danh mục bài viết',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => _row(visible[index]),
                        ),
                      const Divider(height: 1),
                      PaginationFooter(
                        currentPage: _page,
                        totalPages: _totalPages,
                        totalElements: _filteredCategories.length,
                        pageSize: _pageSize,
                        onPageChanged: (page) => setState(() => _page = page),
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
}
