import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../providers/products_provider.dart';

class ProductDetailDialog extends StatefulWidget {
  final int productId;
  final ValueChanged<Map<String, dynamic>> onManageVariants;

  const ProductDetailDialog({
    super.key,
    required this.productId,
    required this.onManageVariants,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  late final Future<ProductDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = context.read<ProductsProvider>().loadDetail(
      widget.productId,
    );
  }

  String _text(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? '—' : result;
  }

  String _price(dynamic value) {
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: (screenSize.width * 2 / 3).clamp(520.0, 1100.0),
      height: screenSize.height * 2 / 3,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chi tiết sản phẩm',
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
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<ProductDetails>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Không tải được chi tiết sản phẩm: ${snapshot.error}',
                      ),
                    ),
                  );
                }
                return _buildDetails(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ProductDetails details) {
    final product = details.product;
    final isActive = product['isActive'] == true;
    final orderedImages = [...details.images]
      ..sort((a, b) {
        final aPrimary = a['isPrimary'] == true;
        final bPrimary = b['isPrimary'] == true;
        if (aPrimary != bPrimary) return aPrimary ? -1 : 1;
        return ((a['displayOrder'] as num?) ?? 0).compareTo(
          (b['displayOrder'] as num?) ?? 0,
        );
      });

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(product['name']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_text(product['slug'])}  •  Mã #${product['id']}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.success.withAlpha(25)
                            : AppTheme.danger.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Đã ẩn',
                        style: TextStyle(
                          color: isActive ? AppTheme.success : AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Ảnh sản phẩm'),
                const SizedBox(height: 12),
                if (orderedImages.isEmpty)
                  Container(
                    height: 140,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Chưa có ảnh sản phẩm'),
                  )
                else
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: orderedImages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _imageUrl(_text(orderedImages[index]['imageUrl'])),
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 150,
                            color: AppTheme.surface,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                _sectionTitle('Thông tin cơ bản'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = constraints.maxWidth < 560
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _detailTile(
                          'Danh mục',
                          _text(product['categoryName']),
                          tileWidth,
                        ),
                        _detailTile(
                          'Nhà cung cấp',
                          _text(product['supplierName']),
                          tileWidth,
                        ),
                        _detailTile(
                          'Size Guide',
                          _text(product['sizeGuideName']),
                          tileWidth,
                        ),
                        _detailTile(
                          'Giá bán cơ bản',
                          _price(product['basePrice']),
                          tileWidth,
                        ),
                        _detailTile(
                          'Phong cách',
                          _text(product['style']),
                          tileWidth,
                        ),
                        _detailTile(
                          'Dịp sử dụng',
                          _text(product['occasion']),
                          tileWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _sectionTitle('Mô tả'),
                const SizedBox(height: 8),
                Text(
                  _text(product['description']),
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onManageVariants(product);
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Quản lý biến thể'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  Widget _detailTile(String label, String value, double width) => Container(
    width: width,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
