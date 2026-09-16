// GENERATED FROM TEMPLATE: templates/feature_header.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class SuppliersHeader extends StatelessWidget {
  const SuppliersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhà cung cấp',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quản lý đối tác và lịch sử nhập hàng',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 20),
              label: const Text('Xuất dữ liệu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.text,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Thêm nhà cung cấp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

