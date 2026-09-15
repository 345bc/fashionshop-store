// GENERATED FROM TEMPLATE: templates/feature_toolbar.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class SuppliersToolbar extends StatelessWidget {
  const SuppliersToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, SĐT hoặc email...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filters
          _buildFilterDropdown('Danh mục', ['Tất cả', 'Vải cao cấp', 'Vải Ý nhập khẩu', 'Da thuộc', 'Vải Hàn Quốc']),
          const SizedBox(width: 16),
          // Reset Filter
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Bỏ lọc'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String hint, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          value: items.first,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {},
        ),
      ),
    );
  }
}

