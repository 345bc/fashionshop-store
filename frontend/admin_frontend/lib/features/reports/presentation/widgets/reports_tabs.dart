import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ReportsTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const ReportsTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          _buildSubTabBtn('revenue', '📅 Doanh thu theo thời gian'),
          _buildSubTabBtn('products', '📦 Doanh thu theo sản phẩm'),
        ],
      ),
    );
  }

  Widget _buildSubTabBtn(String id, String label) {
    final isActive = activeTab == id;
    return InkWell(
      onTap: () => onTabChanged(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
