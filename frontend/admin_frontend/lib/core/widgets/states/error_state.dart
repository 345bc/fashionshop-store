import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message = 'Đã xảy ra lỗi không xác định',
    this.onRetry,
    this.icon = Symbols.error,
  });

  factory ErrorStateWidget.network({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      message: 'Mất kết nối mạng. Vui lòng kiểm tra lại đường truyền.',
      icon: Symbols.wifi_off,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.danger.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.danger,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Symbols.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
