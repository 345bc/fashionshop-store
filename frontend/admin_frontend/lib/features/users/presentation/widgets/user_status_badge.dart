import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UserStatusBadge extends StatelessWidget {
  final String status;

  const UserStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (status.toLowerCase() == 'hoạt động') {
      bgColor = AppTheme.success.withOpacity(0.1);
      textColor = AppTheme.success;
    } else {
      bgColor = AppTheme.danger.withOpacity(0.1);
      textColor = AppTheme.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

