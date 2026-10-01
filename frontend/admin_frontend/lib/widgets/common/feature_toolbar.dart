import 'package:flutter/material.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          if (widget.filterWidget != null) ...[
            const SizedBox(width: 16),
            widget.filterWidget!,
          ],
        ],
      ),
    );
  }
}
