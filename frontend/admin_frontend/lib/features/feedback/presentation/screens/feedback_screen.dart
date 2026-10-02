import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../data/repositories/feedback_repository.dart';
import '../providers/feedback_provider.dart';
import '../widgets/feedback_category_filters.dart';
import '../widgets/feedback_product_catalog.dart';
import '../widgets/feedback_workspace.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FeedbackProvider>();
    final catalog =
        p.view == FeedbackView.products && p.selectedProductId == null;
    final productDetail =
        p.view == FeedbackView.products && p.selectedProductId != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        key: PageStorageKey(
          catalog
              ? 'feedback-catalog'
              : productDetail
              ? 'feedback-product-${p.selectedProductId}'
              : 'feedback-inbox',
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Phản hồi khách hàng',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xử lý phản hồi mới hoặc kiểm tra đánh giá theo sản phẩm.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Dữ liệu mẫu • Chưa kết nối backend.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(
                    'Cần xử lý (${p.count(ReviewFilter.unanswered)})',
                  ),
                  selected: p.view == FeedbackView.inbox,
                  onSelected: (_) => p.setView(FeedbackView.inbox),
                ),
                ChoiceChip(
                  label: const Text('Theo sản phẩm'),
                  selected: p.view == FeedbackView.products,
                  onSelected: (_) => p.setView(FeedbackView.products),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (productDetail) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: p.backToCatalog,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Danh sách sản phẩm'),
                ),
              ),
              Text(
                FeedbackRepository.products
                    .firstWhere((r) => r.id == p.selectedProductId)
                    .name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${p.averageFor(p.selectedProductId!).toStringAsFixed(1)} / 5 sao • '
                '${p.reviewsFor(p.selectedProductId!).length} đánh giá • ${p.unansweredFor(p.selectedProductId!)} chưa trả lời',
              ),
              const SizedBox(height: 20),
            ],
            if (!productDetail) ...[
              FeedbackCategoryFilters(provider: p, catalog: catalog),
              const SizedBox(height: 16),
            ],
            FeatureToolbar(
              searchHint: catalog
                  ? 'Tìm sản phẩm theo tên hoặc SKU...'
                  : 'Tìm khách hàng, nội dung hoặc đơn hàng...',
              initialSearchText: catalog ? p.catalogFilters.query : p.query,
              onSearchChanged: catalog ? p.setCatalogQuery : p.setQuery,
              filterWidget: catalog
                  ? null
                  : DropdownButton<int>(
                      value: p.rating ?? 0,
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text('Tất cả số sao'),
                        ),
                        for (var i = 5; i >= 1; i--)
                          DropdownMenuItem(value: i, child: Text('$i sao')),
                      ],
                      onChanged: (i) => p.setRating(i == 0 ? null : i),
                    ),
            ),
            const SizedBox(height: 16),
            if (catalog)
              FeedbackProductCatalog(provider: p)
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in [
                    ReviewFilter.all,
                    ReviewFilter.unanswered,
                    ReviewFilter.replied,
                    ReviewFilter.hidden,
                  ])
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: p.filter == filter,
                      onSelected: (_) => p.setFilter(filter),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FeedbackWorkspace(provider: p),
            ],
          ],
        ),
      ),
    );
  }
}
