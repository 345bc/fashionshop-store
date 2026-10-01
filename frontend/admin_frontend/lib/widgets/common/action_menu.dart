import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ActionMenuItem {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isDivider;

  const ActionMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.isDivider = false,
  });

  factory ActionMenuItem.divider() {
    return const ActionMenuItem(value: 'divider', label: '', isDivider: true);
  }
}

class ActionMenu extends StatelessWidget {
  final List<ActionMenuItem> items;
  final ValueChanged<String> onSelected;

  const ActionMenu({super.key, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppTheme.textSecondary,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map<PopupMenuEntry<String>>((item) {
          if (item.isDivider) {
            return const PopupMenuDivider();
          }
          return PopupMenuItem<String>(
            value: item.value,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18, color: item.color),
                  const SizedBox(width: 8),
                ],
                Text(item.label, style: TextStyle(color: item.color)),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
