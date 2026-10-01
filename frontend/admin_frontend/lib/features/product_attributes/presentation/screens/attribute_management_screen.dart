import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../../../widgets/common/action_menu.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../sizeguides/presentation/providers/size_guides_provider.dart';
import '../../data/attribute_kind.dart';
import '../dialogs/attribute_form_dialog.dart';
import '../dialogs/attribute_detail_dialog.dart';
import '../providers/attribute_provider.dart';

class AttributeManagementScreen extends StatefulWidget {
  final AttributeKind kind;
  const AttributeManagementScreen({super.key, required this.kind});

  @override
  State<AttributeManagementScreen> createState() =>
      _AttributeManagementScreenState();
}

class _AttributeManagementScreenState extends State<AttributeManagementScreen> {
  late AttributeProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = AttributeProvider(widget.kind)..load();
  }

  @override
  void didUpdateWidget(covariant AttributeManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _provider.dispose();
      _provider = AttributeProvider(widget.kind)..load();
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ${widget.kind.singular}'),
        content: Text(
          'Xóa "${item['name']}"? Mục đang được sử dụng sẽ không thể xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _provider.delete((item['id'] as num).toInt());
      if (!mounted) return;
      if (widget.kind == AttributeKind.sizeGuide) {
        context.read<SizeGuidesProvider>().loadItems();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Xóa thành công')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<AttributeProvider>.value(
        value: _provider,
        child: AttributeDetailDialog(
          kind: widget.kind,
          id: (item['id'] as num).toInt(),
        ),
      ),
    );
  }

  String _imageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.origin + (url.startsWith('/') ? url : '/$url');
  }

  Widget _secondary(Map<String, dynamic> item) {
    switch (widget.kind) {
      case AttributeKind.color:
        return Row(
          children: [
            if (RegExp(r'^#[0-9A-Fa-f]{6}$')
                .hasMatch(item['hexCode']?.toString() ?? '')) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      'FF${(item['hexCode'] as String).substring(1)}',
                      radix: 16,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderLight),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${item['code'] ?? '—'} · ${item['hexCode'] ?? '—'}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        );
      case AttributeKind.size:
        return Text(
          'Thứ tự: ${item['displayOrder'] ?? 0}',
          style: const TextStyle(color: AppTheme.textSecondary),
        );
      case AttributeKind.sizeGuide:
        return Text(
          item['description']?.toString().isNotEmpty == true
              ? item['description'].toString()
              : 'Chưa có mô tả',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        context.watch<AuthProvider>().user?.roles.any(
          (role) => role == 'ADMIN' || role == 'ROLE_ADMIN',
        ) ??
        false;
    return ChangeNotifierProvider<AttributeProvider>.value(
      value: _provider,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Về thuộc tính sản phẩm',
                  onPressed: () =>
                      MainScreen.of(context).navigate('/product-attributes'),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý ${widget.kind.title}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Thuộc tính dùng cho sản phẩm và biến thể',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) =>
                        ChangeNotifierProvider<AttributeProvider>.value(
                          value: _provider,
                          child: AttributeFormDialog(kind: widget.kind),
                        ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text('Thêm ${widget.kind.singular}'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FeatureToolbar(
              key: ValueKey(widget.kind),
              searchHint: 'Tìm ${widget.kind.title}...',
              onSearchChanged: _provider.search,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<AttributeProvider>(
                builder: (context, provider, _) {
                  if (provider.loading && provider.items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.error != null && provider.items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Không tải được dữ liệu: ${provider.error}'),
                            TextButton(
                              onPressed: provider.load,
                              child: const Text('Thử lại'),
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
                            Expanded(
                              child: Text(
                                widget.kind.title.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.kind == AttributeKind.sizeGuide)
                              const SizedBox(
                                width: 100,
                                child: Text(
                                  'TRẠNG THÁI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (provider.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Text('Chưa có dữ liệu'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = provider.items[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                hoverColor: AppTheme.surface,
                                onTap: () => _showDetail(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      if (widget.kind ==
                                          AttributeKind.sizeGuide) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child:
                                              (item['guideImageUrl']
                                                          ?.toString() ??
                                                      '')
                                                  .isNotEmpty
                                              ? Image.network(
                                                  _imageUrl(
                                                    item['guideImageUrl']
                                                        as String,
                                                  ),
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const SizedBox(
                                                        width: 48,
                                                        height: 48,
                                                        child: Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                        ),
                                                      ),
                                                )
                                              : const SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 14),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name']?.toString() ?? '—',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            _secondary(item),
                                          ],
                                        ),
                                      ),
                                      if (widget.kind ==
                                          AttributeKind.sizeGuide)
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            item['isActive'] == false
                                                ? 'Đã ẩn'
                                                : 'Hoạt động',
                                            style: TextStyle(
                                              color: item['isActive'] == false
                                                  ? AppTheme.danger
                                                  : AppTheme.success,
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        width: 48,
                                        child: ActionMenu(
                                          items: [
                                            const ActionMenuItem(
                                              value: 'view',
                                              label: 'Xem chi tiết',
                                              icon: Icons.visibility_outlined,
                                            ),
                                            const ActionMenuItem(
                                              value: 'edit',
                                              label: 'Chỉnh sửa',
                                              icon: Icons.edit_outlined,
                                            ),
                                            if (canDelete)
                                              const ActionMenuItem(
                                                value: 'delete',
                                                label: 'Xóa',
                                                icon: Icons.delete_outline,
                                                color: AppTheme.danger,
                                              ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'view') {
                                              _showDetail(item);
                                            } else if (value == 'edit') {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    ChangeNotifierProvider<
                                                      AttributeProvider
                                                    >.value(
                                                      value: _provider,
                                                      child:
                                                          AttributeFormDialog(
                                                            kind: widget.kind,
                                                            item: item,
                                                          ),
                                                    ),
                                              );
                                            } else if (value == 'delete') {
                                              _delete(item);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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
}
