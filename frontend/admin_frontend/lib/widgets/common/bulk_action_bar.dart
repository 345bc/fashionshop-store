import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_theme.dart';

class BulkActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDanger;
  final String tooltip;

  const BulkActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDanger ? AppTheme.danger : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isDanger
              ? BorderSide.none
              : const BorderSide(color: AppTheme.border, width: 1),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              icon,
              size: 16,
              color: isDanger ? Colors.white : AppTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}

class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final String itemLabel;
  final VoidCallback onClear;
  final List<Widget> actions;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.itemLabel,
    required this.onClear,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppTheme.borderLight, width: 1),
                  ),
                  child: InkWell(
                    onTap: onClear,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Symbols.close, size: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 16, color: AppTheme.borderLight),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Dark slate
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  itemLabel,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 16, color: AppTheme.borderLight),
                const SizedBox(width: 16),
                Wrap(spacing: 8, children: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
