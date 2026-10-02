import 'package:flutter/material.dart';

import '../../data/repositories/feedback_repository.dart';
import '../providers/feedback_provider.dart';

class FeedbackCategoryFilters extends StatelessWidget {
  final FeedbackProvider provider;
  final bool catalog;
  const FeedbackCategoryFilters({
    super.key,
    required this.provider,
    this.catalog = false,
  });
  @override
  Widget build(BuildContext context) {
    final f = catalog ? provider.catalogFilters : provider.filters;
    final parents = {
      for (final p in FeedbackRepository.products) p.parentId: p.parent,
    };
    final children = {
      for (final p in FeedbackRepository.products)
        if (f.parentId == null || p.parentId == f.parentId)
          p.categoryId: p.category,
    };
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<int>(
            key: ValueKey('parent-${f.parentId}-$catalog'),
            initialValue: f.parentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Danh mục cha'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Tất cả danh mục cha'),
              ),
              for (final entry in parents.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (id) =>
                provider.setCategory(id, parent: true, catalog: catalog),
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<int>(
            key: ValueKey('child-${f.categoryId}-${f.parentId}-$catalog'),
            initialValue: f.categoryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Danh mục con'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Tất cả danh mục con'),
              ),
              for (final entry in children.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (id) =>
                provider.setCategory(id, parent: false, catalog: catalog),
          ),
        ),
      ],
    );
  }
}
