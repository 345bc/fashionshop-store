import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class StaffHeader extends StatelessWidget {
  const StaffHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhân sự',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quản lý danh sách nhân viên và phân công ca làm việc',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // OutlinedButton.icon(
            //   onPressed: () {},
            //   icon: const Icon(Symbols.file_download, size: 18),
            //   label: const Text('Xuất dữ liệu'),
            //   style: OutlinedButton.styleFrom(
            //     foregroundColor: AppTheme.text,
            //     side: const BorderSide(color: AppTheme.borderLight),
            //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //   ),
            // ),
            // const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Symbols.add, size: 18),
              label: const Text('Thêm nhân viên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.text,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
