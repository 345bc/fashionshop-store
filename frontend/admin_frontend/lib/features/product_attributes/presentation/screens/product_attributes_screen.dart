import 'package:flutter/material.dart';

import '../../../../main.dart';
import '../../../../theme/app_theme.dart';

class ProductAttributesScreen extends StatelessWidget {
  const ProductAttributesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (
        title: 'Danh mục',
        subtitle: 'Danh mục con và danh mục cha',
        icon: Icons.category_outlined,
        route: '/categories',
      ),
      (
        title: 'Màu sắc',
        subtitle: 'Tên màu, mã màu và mã HEX',
        icon: Icons.palette_outlined,
        route: '/colors',
      ),
      (
        title: 'Size',
        subtitle: 'Kích cỡ và thứ tự hiển thị',
        icon: Icons.straighten_outlined,
        route: '/sizes',
      ),
      (
        title: 'Size Guide',
        subtitle: 'Bảng hướng dẫn chọn size',
        icon: Icons.menu_book_outlined,
        route: '/sizeguides',
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thuộc tính sản phẩm',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quản lý các dữ liệu dùng khi tạo và chỉnh sửa sản phẩm',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final section in sections)
                    SizedBox(
                      width: cardWidth,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              MainScreen.of(context).navigate(section.route),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  section.icon,
                                  size: 32,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        section.subtitle,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
