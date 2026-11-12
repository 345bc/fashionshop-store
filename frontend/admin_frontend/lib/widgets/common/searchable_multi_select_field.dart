import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SearchableMultiSelectField<T> extends StatelessWidget {
  const SearchableMultiSelectField({
    super.key,
    required this.values,
    required this.decoration,
    required this.options,
    required this.onChanged,
    this.leadingBuilder,
    this.singleSelection = false,
    this.validator,
  });

  final Set<T> values;
  final InputDecoration decoration;
  final Map<T, String> options;
  final ValueChanged<Set<T>> onChanged;
  final Widget? Function(T)? leadingBuilder;
  final bool singleSelection;
  final FormFieldValidator<Set<T>>? validator;

  @override
  Widget build(BuildContext context) => FormField<Set<T>>(
    initialValue: values,
    validator: validator,
    builder: (field) {
      final selected = options.entries
          .where((item) => values.contains(item.key))
          .map((item) => item.value)
          .join(', ');
      return InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final next = await showDialog<Set<T>>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.24),
            builder: (_) => _MultiOptionsDialog<T>(
              options: options,
              initialValues: values,
              leadingBuilder: leadingBuilder,
              singleSelection: singleSelection,
              title: (decoration.labelText ?? decoration.hintText ?? 'Chọn mục')
                  .replaceAll('*', '')
                  .trim(),
            ),
          );
          if (next == null || !field.mounted) return;
          field.didChange(next);
          onChanged(next);
        },
        child: InputDecorator(
          isEmpty: selected.isEmpty,
          decoration: decoration.copyWith(
            errorText: decoration.errorText ?? field.errorText,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: selected.isEmpty
              ? null
              : Text(selected, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
    },
  );
}

class _MultiOptionsDialog<T> extends StatefulWidget {
  const _MultiOptionsDialog({
    required this.options,
    required this.initialValues,
    required this.leadingBuilder,
    required this.singleSelection,
    required this.title,
  });

  final Map<T, String> options;
  final Set<T> initialValues;
  final Widget? Function(T)? leadingBuilder;
  final bool singleSelection;
  final String title;

  @override
  State<_MultiOptionsDialog<T>> createState() => _MultiOptionsDialogState<T>();
}

class _MultiOptionsDialogState<T> extends State<_MultiOptionsDialog<T>> {
  final _scrollController = ScrollController();
  String _query = '';
  late final _selected = Set<T>.of(widget.initialValues);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options.entries
        .where((item) => item.value.toLowerCase().contains(_query))
        .toList();

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
        height:
            (140 +
                    (widget.singleSelection ? 0 : 54) +
                    (widget.options.length.clamp(1, 6) * 48))
                .toDouble(),
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
                          final selected = _selected.contains(item.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              leading: widget.leadingBuilder?.call(item.key),
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
                              title: Text(
                                item.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.font.style(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: AppTheme.text,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: AppTheme.text,
                                    )
                                  : null,
                              onTap: () {
                                if (widget.singleSelection) {
                                  Navigator.of(context).pop({item.key});
                                  return;
                                }
                                setState(() {
                                  if (selected) {
                                    _selected.remove(item.key);
                                  } else {
                                    _selected.add(item.key);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (!widget.singleSelection) ...[
              const Divider(height: 1, color: AppTheme.borderLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('Xong'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
