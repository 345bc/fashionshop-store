import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/attribute_kind.dart';
import '../providers/attribute_provider.dart';

class AttributeDetailDialog extends StatefulWidget {
  final AttributeKind kind;
  final int id;
  const AttributeDetailDialog({
    super.key,
    required this.kind,
    required this.id,
  });

  @override
  State<AttributeDetailDialog> createState() => _AttributeDetailDialogState();
}

class _AttributeDetailDialogState extends State<AttributeDetailDialog> {
  late final Future<Map<String, dynamic>> _detail;

  @override
  void initState() {
    super.initState();
    _detail = context.read<AttributeProvider>().loadDetail(widget.id);
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  String _imageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.origin + (url.startsWith('/') ? url : '/$url');
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: (size.width * 2 / 3).clamp(480.0, 1000.0),
      height: size.height * 2 / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết ${widget.kind.singular}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _detail,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: snapshot.hasError
                        ? Text('Không tải được chi tiết: ${snapshot.error}')
                        : const CircularProgressIndicator(),
                  );
                }
                final item = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(item['name']),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mã #${widget.id}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 26),
                      if (widget.kind == AttributeKind.color) ...[
                        if (RegExp(r'^#[0-9A-Fa-f]{6}$')
                            .hasMatch(item['hexCode']?.toString() ?? '')) ...[
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  'FF${(item['hexCode'] as String).substring(1)}',
                                  radix: 16,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _field('Mã màu', _text(item['code'])),
                        _field('Mã HEX', _text(item['hexCode'])),
                      ],
                      if (widget.kind == AttributeKind.size)
                        _field('Thứ tự hiển thị', _text(item['displayOrder'])),
                      if (widget.kind == AttributeKind.sizeGuide) ...[
                        _field('Mô tả', _text(item['description'])),
                        _field(
                          'Trạng thái',
                          item['isActive'] == false ? 'Đã ẩn' : 'Hoạt động',
                        ),
                        if ((item['guideImageUrl']?.toString() ?? '')
                            .isNotEmpty) ...[
                          const Text(
                            'Ảnh hướng dẫn',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _imageUrl(item['guideImageUrl'] as String),
                              height: 300,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const SizedBox(
                                height: 160,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}
