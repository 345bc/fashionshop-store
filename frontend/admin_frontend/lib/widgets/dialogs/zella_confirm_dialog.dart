import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'zella_dialog.dart';

class ZellaConfirmDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData icon;
  final Color iconColor;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isLoading;

  const ZellaConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon = Symbols.warning,
    this.iconColor = AppTheme.error,
    this.cancelText = 'Hủy',
    this.confirmText = 'Xác nhận',
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ZellaDialog(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 12),
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            child: content,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.text,
                  side: const BorderSide(color: AppTheme.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  cancelText,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
