import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class UserRoleBadge extends StatelessWidget {
  final String role;

  const UserRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (role.toLowerCase()) {
      case 'super admin':
        bgColor = AppTheme.primary.withAlpha(25);
        textColor = AppTheme.primary;
        break;
      case 'admin':
        bgColor = const Color(0xFFE3F2FD); // Light blue
        textColor = const Color(0xFF1976D2); // Dark blue
        break;
      case 'manager':
        bgColor = const Color(0xFFF3E5F5); // Light purple
        textColor = const Color(0xFF7B1FA2); // Dark purple
        break;
      default:
        bgColor = AppTheme.surface;
        textColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
