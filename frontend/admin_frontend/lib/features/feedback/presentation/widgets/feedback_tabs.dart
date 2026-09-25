import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class FeedbackTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const FeedbackTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'all', 'label': 'Tất cả', 'count': 34},
      {'id': 'pending', 'label': 'Chờ duyệt', 'count': 7},
      {'id': 'published', 'label': 'Đã duyệt', 'count': 24},
      {'id': 'rejected', 'label': 'Từ chối', 'count': 3},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isActive = activeTab == tab['id'];
            return InkWell(
              onTap: () => onTabChanged(tab['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? AppTheme.text : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.text : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tab['count']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
