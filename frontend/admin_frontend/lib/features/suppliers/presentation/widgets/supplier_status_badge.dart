import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class SupplierStatusBadge extends StatelessWidget {
  final String status;

  const SupplierStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Đang hợp tác':
        bgColor = AppTheme.success.withAlpha(25);
        textColor = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'Ngừng hợp tác':
        bgColor = AppTheme.textMuted.withAlpha(25);
        textColor = AppTheme.textMuted;
        icon = Icons.cancel;
        break;
      default:
        bgColor = AppTheme.info.withAlpha(25);
        textColor = AppTheme.info;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
