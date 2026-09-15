// GENERATED FROM TEMPLATE: templates/feature_toolbar.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UsersToolbar extends StatelessWidget {
  const UsersToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filters
          _buildFilterDropdown('Vai trò', ['Tất cả', 'Super Admin', 'Admin', 'Manager', 'Viewer']),
          const SizedBox(width: 16),
          // Reset Filter
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Làm mới'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.first,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
          style: const TextStyle(color: AppTheme.text, fontSize: 14, fontWeight: FontWeight.w500),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }
}

