// GENERATED FROM TEMPLATE: templates/feature_tabs.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UsersTabs extends StatefulWidget {
  const UsersTabs({super.key});

  @override
  State<UsersTabs> createState() => _UsersTabsState();
}

class _UsersTabsState extends State<UsersTabs> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Tất cả', 'count': 124},
    {'title': 'Hoạt động', 'count': 118},
    {'title': 'Bị khóa', 'count': 6},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isActive = _selectedIndex == index;
          final tab = _tabs[index];

          return InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
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
                    tab['title'],
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
                      color: isActive ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tab['count']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

