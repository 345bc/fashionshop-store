import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'dart:async';

import '../../theme/app_theme.dart';

class FeatureToolbar extends StatefulWidget {
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget? filterWidget;
  final String? initialSearchText;

  const FeatureToolbar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    this.filterWidget,
    this.initialSearchText,
  });

  @override
  State<FeatureToolbar> createState() => _FeatureToolbarState();
}

class _FeatureToolbarState extends State<FeatureToolbar> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
  }

  @override
  void didUpdateWidget(covariant FeatureToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchText != oldWidget.initialSearchText &&
        widget.initialSearchText != _searchController.text) {
      _searchController.text = widget.initialSearchText ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: constraints.maxWidth < 320 ? constraints.maxWidth : 300,
            child: SizedBox(
              height: 38,
              child: Tooltip(
                message: widget.searchHint,
                preferBelow: true,
                waitDuration: const Duration(milliseconds: 600),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 13, color: AppTheme.text),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.searchHint,
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    // Ô tìm kiếm
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    prefixIcon: const Icon(
                      Symbols.search,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
          ),
          if (widget.filterWidget != null) widget.filterWidget!,
        ],
      ),
    );
  }
}
