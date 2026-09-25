import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FeatureTabs extends StatelessWidget {
  final List<Map<String, dynamic>> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const FeatureTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = selectedIndex == index;
            final tab = tabs[index];

            return InkWell(
              onTap: () => onTabChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      tab['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? AppTheme.text : AppTheme.textSecondary,
                      ),
                    ),
                    if (tab['count'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.text : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tab['count']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
