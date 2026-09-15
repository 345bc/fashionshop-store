// GENERATED FROM TEMPLATE: templates/feature_dialog_confirm.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UserDeleteDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDeleteDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Xóa vĩnh viễn tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                children: [
                  const TextSpan(text: 'Tài khoản '),
                  TextSpan(text: user['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text)),
                  const TextSpan(text: ' và toàn bộ dữ liệu liên quan sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác!'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Xóa vĩnh viễn'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

