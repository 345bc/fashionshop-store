import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class SupplierActionMenu extends StatelessWidget {
  const SupplierActionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      color: Colors.white,
      elevation: 4,
      onSelected: (value) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('Xem chi tiết', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history_outlined, size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('Lịch sử nhập hàng', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('Chỉnh sửa', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'suspend',
          child: Row(
            children: [
              Icon(Icons.block_outlined, size: 18, color: AppTheme.danger),
              SizedBox(width: 8),
              Text('Ngừng hợp tác', style: TextStyle(fontSize: 14, color: AppTheme.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
