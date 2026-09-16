// GENERATED FROM TEMPLATE: templates/feature_header.dart.template
import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../dialogs/user_edit_dialog.dart';

class UsersHeader extends StatelessWidget {
  const UsersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản hệ thống',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Quản lý tài khoản và phân quyền truy cập',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Xuất dữ liệu'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const UserEditDialog(),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ],
    );
  }
}
