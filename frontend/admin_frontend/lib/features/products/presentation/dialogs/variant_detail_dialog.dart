import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../providers/product_variants_provider.dart';

class VariantDetailDialog extends StatefulWidget {
  final int variantId;
  const VariantDetailDialog({super.key, required this.variantId});

  @override
  State<VariantDetailDialog> createState() => _VariantDetailDialogState();
}

class _VariantDetailDialogState extends State<VariantDetailDialog> {
  late final Future<ProductVariantDetails> _details;

  @override
  void initState() {
    super.initState();
    _details = context.read<ProductVariantsProvider>().loadDetail(
      widget.variantId,
    );
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  String _money(dynamic value) {
    final amount = (value as num?)?.toInt() ?? 0;
    final digits = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$digits ₫';
  }

  String _imageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.origin + (url.startsWith('/') ? url : '/$url');
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
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
      width: (size.width * 2 / 3).clamp(500.0, 1100.0),
      height: size.height * 2 / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết biến thể',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            child: FutureBuilder<ProductVariantDetails>(
              future: _details,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: snapshot.hasError
                        ? Text(
                            'Không tải được chi tiết biến thể: ${snapshot.error}',
                          )
                        : const CircularProgressIndicator(),
                  );
                }
                final variant = snapshot.data!.variant;
                final images = [...snapshot.data!.images]
                  ..sort((a, b) {
                    if ((a['isPrimary'] == true) != (b['isPrimary'] == true)) {
                      return a['isPrimary'] == true ? -1 : 1;
                    }
                    return ((a['displayOrder'] as num?) ?? 0).compareTo(
                      (b['displayOrder'] as num?) ?? 0,
                    );
                  });
                final stock = (variant['stockQuantity'] as num?)?.toInt() ?? 0;
                final reserved =
                    (variant['reservedQuantity'] as num?)?.toInt() ?? 0;
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(variant['sku']),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_text(variant['productName'])} · Mã #${widget.variantId}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 48,
                        runSpacing: 4,
                        children: [
                          SizedBox(
                            width: 220,
                            child: _field('Size', _text(variant['sizeName'])),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field(
                              'Màu',
                              '${_text(variant['colorName'])} (${_text(variant['colorCode'])})',
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field('Giá bán', _money(variant['price'])),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field(
                              'Giá vốn',
                              _money(variant['costPrice']),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field('Tồn kho', '$stock'),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field('Đã đặt', '$reserved'),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field('Còn lại', '${stock - reserved}'),
                          ),
                          SizedBox(
                            width: 220,
                            child: _field(
                              'Trạng thái',
                              variant['isActive'] == true
                                  ? 'Đang bán'
                                  : 'Ngừng bán',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ảnh biến thể',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (images.isEmpty) const Text('Chưa có ảnh biến thể.'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final image in images)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imageUrl(image['imageUrl'] as String),
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                                if (image['isPrimary'] == true)
                                  Positioned(
                                    left: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Ảnh chính',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
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
