// GENERATED FROM TEMPLATE: templates/feature_dialog_detail.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class UserDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailsDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết Tài khoản',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Họ và tên', user['name']?.toString() ?? 'N/A'),
                    _buildInfoRow('Email', user['email']?.toString() ?? 'N/A'),
                    _buildInfoRow('Vai trò', user['role']?.toString() ?? 'N/A'),
                    _buildInfoRow('Trạng thái', user['status']?.toString() ?? 'N/A'),
                    _buildInfoRow('Xác thực 2FA', user['2fa'] == true ? 'Đang bật' : 'Chưa bật'),
                    _buildInfoRow('Đăng nhập lần cuối', user['last_login']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

