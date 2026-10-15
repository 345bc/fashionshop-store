import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../providers/feedback_provider.dart';
import '../widgets/feedback_category_filters.dart';
import '../widgets/feedback_product_catalog.dart';
import '../widgets/feedback_workspace.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<FeedbackProvider>();
      if (!p.initialized) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FeedbackProvider>();
    final catalog =
        p.view == FeedbackView.products && p.selectedProductId == null;
    final productDetail =
        p.view == FeedbackView.products && p.selectedProductId != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AbsorbPointer(
        absorbing: p.saving || p.loading,
        child: SingleChildScrollView(
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
              if (p.isDemo)
                const Text(
                  'Dữ liệu mẫu',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              if (p.loading) const LinearProgressIndicator(),
              if (p.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    p.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
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
                    icon: const Icon(Symbols.arrow_back),
                    label: const Text('Danh sách sản phẩm'),
                  ),
                ),
                Text(
                  p.products
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
              if (catalog) ...[
                FeedbackCategoryFilters(provider: p, catalog: catalog),
                const SizedBox(height: 16),
              ],
              FeatureToolbar(
                key: ValueKey(
                  catalog
                      ? 'catalog-search'
                      : 'review-search-${p.view}-${p.selectedProductId}',
                ),
                searchHint: catalog
                    ? 'Tìm sản phẩm theo tên hoặc SKU'
                    : 'Tìm khách hàng, nội dung hoặc đơn hàng',
                initialSearchText: catalog ? p.catalogFilters.query : p.query,
                onSearchChanged: catalog ? p.setCatalogQuery : p.setQuery,
                filterWidget: catalog
                    ? null
                    : FilterDropdown<int>(
                        label: 'Đánh giá',
                        searchHint: 'Tìm số sao',
                        value: p.rating ?? 0,
                        defaultValue: 0,
                        options: [
                          for (var i = 5; i >= 1; i--)
                            FilterOption(
                              value: i,
                              label: '$i sao',
                              icon: Symbols.star,
                              iconColor: const Color(0xFFFFB020),
                            ),
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
      ),
    );
  }
}
