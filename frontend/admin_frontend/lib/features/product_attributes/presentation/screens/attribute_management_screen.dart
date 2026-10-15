import 'package:material_symbols_icons/symbols.dart';

import '../../../../widgets/common/pagination_footer.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../data/attribute_kind.dart';
import '../dialogs/attribute_form_dialog.dart';
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

  void _showEdit(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<AttributeProvider>.value(
        value: _provider,
        child: AttributeFormDialog(kind: widget.kind, item: item),
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
    return ChangeNotifierProvider<AttributeProvider>.value(
      value: _provider,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Về sản phẩm',
                      onPressed: () =>
                          MainScreen.of(context).navigate('/products'),
                      icon: const Icon(Symbols.arrow_back),
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
                      icon: const Icon(Symbols.add),
                      label: Text('Thêm ${widget.kind.singular}'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FeatureToolbar(
                  key: ValueKey(widget.kind),
                  searchHint: widget.kind == AttributeKind.color
                      ? 'Tìm màu sắc theo tên, mã màu hoặc mã hex'
                      : 'Tìm theo kích cỡ hoặc mô tả',
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
                      if (provider.loading) {
                        return const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (provider.error != null) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Không tải được dữ liệu: ${provider.error}',
                                ),
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
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = provider.items[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    hoverColor: AppTheme.surface,
                                    onTap: () => _showEdit(item),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                              Symbols
                                                                  .broken_image,
                                                            ),
                                                          ),
                                                    )
                                                  : const SizedBox(
                                                      width: 48,
                                                      height: 48,
                                                      child: Icon(
                                                        Symbols.image,
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
                                                  item['name']?.toString() ??
                                                      '—',
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
                                                  color:
                                                      item['isActive'] == false
                                                      ? AppTheme.danger
                                                      : AppTheme.success,
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            tooltip: 'Chỉnh sửa',
                                            icon: const Icon(
                                              Symbols.edit,
                                              size: 18,
                                            ),
                                            onPressed: () => _showEdit(item),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (widget.kind != AttributeKind.size)
                            PaginationFooter(
                              currentPage: provider.currentPage,
                              totalPages: provider.totalElements == 0
                                  ? 1
                                  : (provider.totalElements / provider.pageSize)
                                        .ceil(),
                              totalElements: provider.totalElements,
                              pageSize: provider.pageSize,
                              onPageChanged: provider.setPage,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
