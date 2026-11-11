import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  final bool showIcons;
  final Widget? trigger;

  const ActionMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.showIcons = false,
    this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      elevation: 6,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      menuPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      constraints: const BoxConstraints(
        minWidth: 140,
        maxWidth: 220,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFEAECF0),
          width: 1,
        ),
      ),
      onSelected: onSelected,
      child: _ActionMenuTrigger(customTrigger: trigger),
      itemBuilder: (context) {
        final activeNotifier = ValueNotifier<String?>(null);
        return items.map<PopupMenuEntry<String>>((item) {
          if (item.isDivider) {
            return const _ActionMenuDivider();
          }
          return _ActionPopupMenuItem(
            item: item,
            showIcon: showIcons,
            activeNotifier: activeNotifier,
          );
        }).toList();
      },
    );
  }
}

class _ActionMenuTrigger extends StatefulWidget {
  final Widget? customTrigger;
  const _ActionMenuTrigger({this.customTrigger});

  @override
  State<_ActionMenuTrigger> createState() => _ActionMenuTriggerState();
}

class _ActionMenuTriggerState extends State<_ActionMenuTrigger> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.customTrigger != null) {
      return widget.customTrigger!;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF2F4F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          Symbols.more_vert,
          color: _isHovered ? const Color(0xFF1D2939) : const Color(0xFF667085),
          size: 18,
        ),
      ),
    );
  }
}

class _ActionPopupMenuItem extends PopupMenuEntry<String> {
  final ActionMenuItem item;
  final bool showIcon;
  final ValueNotifier<String?> activeNotifier;

  const _ActionPopupMenuItem({
    required this.item,
    required this.activeNotifier,
    this.showIcon = false,
  });

  @override
  double get height => 38.0;

  @override
  bool represents(String? value) => false;

  @override
  State<_ActionPopupMenuItem> createState() => _ActionPopupMenuItemState();
}

class _ActionPopupMenuItemState extends State<_ActionPopupMenuItem> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDanger = item.color == AppTheme.danger;

    final hoverBgColor = isDanger
        ? const Color(0xFFFEF3F2)
        : const Color(0xFFF2F4F7);

    return ValueListenableBuilder<String?>(
      valueListenable: widget.activeNotifier,
      builder: (context, activeValue, _) {
        final isHovered = activeValue == item.value;

        final textColor = isDanger
            ? (isHovered ? const Color(0xFFB42318) : AppTheme.danger)
            : (isHovered
                ? const Color(0xFF1D2939)
                : (item.color ?? const Color(0xFF344054)));

        return MouseRegion(
          onEnter: (_) {
            widget.activeNotifier.value = item.value;
          },
          onExit: (_) {
            if (widget.activeNotifier.value == item.value) {
              widget.activeNotifier.value = null;
            }
          },
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).pop(item.value);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isHovered ? hoverBgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (widget.showIcon && item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 16,
                      color: textColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionMenuDivider extends PopupMenuEntry<String> {
  const _ActionMenuDivider();

  @override
  double get height => 9.0;

  @override
  bool represents(String? value) => false;

  @override
  State<_ActionMenuDivider> createState() => _ActionMenuDividerState();
}

class _ActionMenuDividerState extends State<_ActionMenuDivider> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF2F4F7),
      ),
    );
  }
}
