import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ReportsToolbar extends StatelessWidget {
  final String period;
  final ValueChanged<String> onPeriodChanged;

  const ReportsToolbar({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Lọc theo thời gian:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: period,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                style: const TextStyle(fontSize: 14, color: AppTheme.text),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('Tuần này')),
                  DropdownMenuItem(value: 'month', child: Text('Tháng này')),
                  DropdownMenuItem(value: 'quarter', child: Text('Quý này')),
                  DropdownMenuItem(value: 'year', child: Text('Năm nay')),
                ],
                onChanged: (val) => onPeriodChanged(val!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
