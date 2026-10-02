import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../data/repositories/feedback_repository.dart';
import '../providers/feedback_provider.dart';

class FeedbackProductCatalog extends StatelessWidget {
  final FeedbackProvider provider;
  const FeedbackProductCatalog({super.key, required this.provider});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Chỉ hiển thị sản phẩm có đánh giá • Ưu tiên sản phẩm có phản hồi chưa trả lời',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 16),
      if (provider.catalogPage.isEmpty)
        const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: Text('Không có sản phẩm có đánh giá phù hợp.')),
        ),
      for (final id in provider.catalogPage) _product(id),
      PaginationFooter(
        currentPage: provider.catalogFilters.page,
        totalPages: provider.catalogIds.isEmpty
            ? 1
            : (provider.catalogIds.length / provider.pageSize).ceil(),
        totalElements: provider.catalogIds.length,
        pageSize: provider.pageSize,
        onPageChanged: provider.setCatalogPage,
      ),
    ],
  );
  Widget _product(int id) {
    final product = FeedbackRepository.products.firstWhere((r) => r.id == id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.openProduct(id),
          hoverColor: AppTheme.surface,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checkroom),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${product.parent} / ${product.category}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            '★ ${provider.averageFor(id).toStringAsFixed(1)} / 5',
                          ),
                          Text('${provider.reviewsFor(id).length} đánh giá'),
                          Text(
                            '${provider.unansweredFor(id)} chưa trả lời',
                            style: TextStyle(
                              color: provider.unansweredFor(id) > 0
                                  ? AppTheme.warning
                                  : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
