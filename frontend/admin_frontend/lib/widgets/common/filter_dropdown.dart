import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_theme.dart';

class FilterOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const FilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

class FilterDropdown<T> extends StatefulWidget {
  final String label;
  final String? searchHint;
  final List<FilterOption<T>> options;
  final T value;
  final T defaultValue;
  final ValueChanged<T> onChanged;
  final VoidCallback? onReset;

  const FilterDropdown({
    super.key,
    required this.label,
    this.searchHint,
    required this.options,
    required this.value,
    required this.defaultValue,
    required this.onChanged,
    this.onReset,
  });

  @override
  State<FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.value != widget.defaultValue;
    final selectedOption = widget.options.where((o) => o.value == widget.value).firstOrNull;

    final filteredOptions = _searchQuery.isEmpty
        ? widget.options
        : widget.options.where((o) => o.label.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MenuAnchor(
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            elevation: WidgetStatePropertyAll(6),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                side: BorderSide(color: AppTheme.borderLight),
              ),
            ),
          ),
          builder: (context, controller, child) {
            return InkWell(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  setState(() => _searchQuery = '');
                  controller.open();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasSelection
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: hasSelection
                      ? AppTheme.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.add_circle,
                      size: 16,
                      color: hasSelection ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasSelection ? AppTheme.primary : AppTheme.text,
                      ),
                    ),
                    if (hasSelection && selectedOption != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 16,
                        color: AppTheme.borderLight,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedOption.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          menuChildren: [
            if (widget.searchHint != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Symbols.search,
                        size: 16, color: AppTheme.textSecondary),
                    prefixIconConstraints: const BoxConstraints(minWidth: 28),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintStyle:
                        const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 4),
            ],
            for (final option in filteredOptions)
              MenuItemButton(
                onPressed: () => widget.onChanged(option.value),
                style: MenuItemButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(220, 36),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: widget.value == option.value
                            ? AppTheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.value == option.value
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: widget.value == option.value
                          ? const Icon(Symbols.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    if (option.icon != null) ...[
                      Icon(option.icon,
                          size: 14,
                          color: option.iconColor ?? AppTheme.textSecondary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      option.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            if (hasSelection) ...[
              const SizedBox(height: 4),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 4),
              MenuItemButton(
                onPressed: () {
                  widget.onChanged(widget.defaultValue);
                  if (widget.onReset != null) widget.onReset!();
                },
                style: MenuItemButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(220, 36),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Xóa bộ lọc',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (hasSelection) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              widget.onChanged(widget.defaultValue);
              if (widget.onReset != null) widget.onReset!();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reset',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Symbols.close, size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
