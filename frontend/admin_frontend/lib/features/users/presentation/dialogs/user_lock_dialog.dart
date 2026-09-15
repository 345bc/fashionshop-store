// GENERATED FROM TEMPLATE: templates/feature_dialog_confirm.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UserLockDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserLockDialog({super.key, required this.user});

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
                color: AppTheme.warning.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppTheme.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Khóa tài khoản',
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
                  const TextSpan(text: ' sẽ bị đăng xuất ngay lập tức và không thể truy cập hệ thống. Bạn có muốn tiếp tục?'),
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
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Khóa tài khoản'),
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

