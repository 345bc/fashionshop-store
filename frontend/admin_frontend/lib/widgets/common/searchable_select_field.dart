import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A compact picker with a fixed search bar and lazily built options.
class SearchableSelectField<T> extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.initialValue,
    required this.decoration,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final T? initialValue;
  final InputDecoration decoration;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) => FormField<T>(
    initialValue: initialValue,
    validator: validator,
    builder: (field) {
      final selected = items.where((item) => item.value == field.value);
      return InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final value = await showDialog<T>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.24),
            builder: (_) => _OptionsDialog<T>(
              items: items,
              selectedValue: field.value,
              title: (decoration.labelText ?? decoration.hintText ?? 'Chọn mục')
                  .replaceAll('*', '')
                  .trim(),
            ),
          );
          if (value == null || !field.mounted) return;
          field.didChange(value);
          onChanged(value);
        },
        child: InputDecorator(
          isEmpty: selected.isEmpty,
          decoration: decoration.copyWith(
            errorText: decoration.errorText ?? field.errorText,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: selected.isEmpty
              ? null
              : DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: selected.first.child,
                ),
        ),
      );
    },
  );
}

class _OptionsDialog<T> extends StatefulWidget {
  const _OptionsDialog({
    required this.items,
    required this.selectedValue,
    required this.title,
  });

  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final String title;

  @override
  State<_OptionsDialog<T>> createState() => _OptionsDialogState<T>();
}

class _OptionsDialogState<T> extends State<_OptionsDialog<T>> {
  final _scrollController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      final child = item.child;
      final label = child is Text
          ? (child.data ?? child.textSpan?.toPlainText() ?? '')
          : '';
      return label.toLowerCase().contains(_query);
    }).toList();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        height: (140 + (widget.items.length.clamp(1, 6) * 48)).toDouble(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.font.style(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      style: AppTheme.font.style(
                        fontSize: 13,
                        color: AppTheme.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: AppTheme.font.style(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.surface,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: AppTheme.textSecondary,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                      onChanged: (value) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                        setState(() => _query = value.trim().toLowerCase());
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy kết quả',
                        style: AppTheme.font.style(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      radius: const Radius.circular(8),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemExtent: 48,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final selected = item.value == widget.selectedValue;
                          final label = item.child is Text
                              ? item.child as Text
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              hoverColor: AppTheme.surface,
                              selectedTileColor: const Color(0xFFF0F0EE),
                              selectedColor: AppTheme.text,
                              selected: selected,
                              title: label != null
                                  ? Text(
                                      label.data ??
                                          label.textSpan?.toPlainText() ??
                                          '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.font.style(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: item.enabled
                                            ? AppTheme.text
                                            : AppTheme.textMuted,
                                      ),
                                    )
                                  : DefaultTextStyle.merge(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      child: item.child,
                                    ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: AppTheme.text,
                                    )
                                  : null,
                              onTap: item.enabled
                                  ? () => Navigator.of(context).pop(item.value)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
