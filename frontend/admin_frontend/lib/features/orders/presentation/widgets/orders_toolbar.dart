import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class OrdersToolbar extends StatelessWidget {
  const OrdersToolbar({super.key});

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
                hintText: 'Tìm kiếm đơn hàng theo mã, tên khách hàng...',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'all',
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                style: const TextStyle(fontSize: 14, color: AppTheme.text),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả thời gian')),
                  DropdownMenuItem(value: 'today', child: Text('Hôm nay')),
                  DropdownMenuItem(value: 'week', child: Text('Tuần này')),
                  DropdownMenuItem(value: 'month', child: Text('Tháng này')),
                ],
                onChanged: (value) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
