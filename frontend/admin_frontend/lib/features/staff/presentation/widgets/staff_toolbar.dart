import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/filter_dropdown.dart';

class StaffToolbar extends StatelessWidget {
  const StaffToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: Icon(Symbols.search, size: 20, color: AppTheme.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          FilterDropdown<String>(
            label: 'Phòng ban',
            searchHint: 'Tìm phòng ban',
            value: 'all',
            defaultValue: 'all',
            options: const [
              FilterOption(value: 'sales', label: 'Bán hàng'),
              FilterOption(value: 'warehouse', label: 'Kho'),
              FilterOption(value: 'designer', label: 'Thiết kế'),
              FilterOption(value: 'accountant', label: 'Kế toán'),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
