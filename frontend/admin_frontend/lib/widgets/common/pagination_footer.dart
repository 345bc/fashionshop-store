import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalElements == 0) return const SizedBox.shrink();

    final start = currentPage * pageSize + 1;
    final end = (start + pageSize - 1).clamp(1, totalElements);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start-$end trong số $totalElements mục',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(
                Icons.chevron_left,
                onPressed: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(),
              const SizedBox(width: 8),
              _buildPageButton(
                Icons.chevron_right,
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> items = [];
    const int maxVisiblePages = 5;

    if (totalPages <= maxVisiblePages) {
      for (int i = 0; i < totalPages; i++) {
        items.add(_buildPageNumber(i));
        if (i < totalPages - 1) items.add(const SizedBox(width: 4));
      }
    } else {
      items.add(_buildPageNumber(0));
      items.add(const SizedBox(width: 4));

      if (currentPage > 2) {
        items.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('...', style: TextStyle(color: AppTheme.textSecondary)),
        ));
        items.add(const SizedBox(width: 4));
      }

      int startPage = (currentPage - 1).clamp(1, totalPages - 3);
      int endPage = (currentPage + 1).clamp(2, totalPages - 2);

      for (int i = startPage; i <= endPage; i++) {
        items.add(_buildPageNumber(i));
        items.add(const SizedBox(width: 4));
      }

      if (currentPage < totalPages - 3) {
        items.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('...', style: TextStyle(color: AppTheme.textSecondary)),
        ));
        items.add(const SizedBox(width: 4));
      }

      items.add(_buildPageNumber(totalPages - 1));
    }

    return items;
  }

  Widget _buildPageNumber(int pageIndex) {
    final isActive = pageIndex == currentPage;
    return InkWell(
      onTap: isActive ? null : () => onPageChanged(pageIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${pageIndex + 1}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: onPressed != null ? AppTheme.border : AppTheme.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppTheme.text : AppTheme.border,
        ),
      ),
    );
  }
}
