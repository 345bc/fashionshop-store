import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FeatureHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onActionPressed;
  final VoidCallback? onExportPressed;

  const FeatureHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onActionPressed,
    this.onExportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            if (onExportPressed != null) ...[
              OutlinedButton.icon(
                onPressed: onExportPressed,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Xuất dữ liệu'),
              ),
              const SizedBox(width: 12),
            ],
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ],
    );
  }
}
