import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../providers/users_provider.dart';

class UserLockDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserLockDialog({super.key, required this.user});

  @override
  State<UserLockDialog> createState() => _UserLockDialogState();
}

class _UserLockDialogState extends State<UserLockDialog> {
  bool _isLoading = false;

  Future<void> _toggleLock() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<UsersProvider>();

      final data = {
        'username': widget.user['name'],
        'email': widget.user['email'],
        'roles': widget.user['roles'] ?? ['USER'],
        'isActive': !(widget.user['isActive'] as bool),
      };

      await provider.updateItem(widget.user['id'], data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['isActive'] == true
                  ? 'Đã mở khóa tài khoản'
                  : 'Đã khóa tài khoản',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $errorMsg'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentlyActive = widget.user['isActive'] ?? true;
    final String actionText = isCurrentlyActive
        ? 'Khóa tài khoản'
        : 'Mở khóa tài khoản';
    final Color actionColor = isCurrentlyActive
        ? AppTheme.warning
        : AppTheme.success;
    final IconData actionIcon = isCurrentlyActive
        ? Icons.lock_outline
        : Icons.lock_open_outlined;

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
                color: actionColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(actionIcon, color: actionColor, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              actionText,
              style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Tài khoản '),
                  TextSpan(
                    text: widget.user['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  TextSpan(
                    text: isCurrentlyActive
                        ? ' sẽ bị đăng xuất ngay lập tức và không thể truy cập hệ thống. Bạn có muốn tiếp tục?'
                        : ' sẽ được phép truy cập lại vào hệ thống. Bạn có muốn tiếp tục?',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleLock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(actionText),
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
