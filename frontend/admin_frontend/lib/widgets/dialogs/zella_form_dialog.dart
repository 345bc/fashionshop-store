import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'zella_dialog.dart';

class ZellaFormDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isLoading;
  final Key? formKey;

  const ZellaFormDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = 'Hủy',
    this.confirmText = 'Lưu',
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
    this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    Widget formContent = content;
    if (formKey != null) {
      formContent = Form(key: formKey, child: content);
    }

    return ZellaDialog(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Flexible(child: formContent),

          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderLight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(cancelText),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(confirmText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
