import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../theme/app_theme.dart';

enum ToastType { success, warning, error, info }

class ZellaToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
  }) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        icon = Symbols.check_circle;
        iconColor = AppTheme.success;
        break;
      case ToastType.warning:
        icon = Symbols.error_circle_rounded; // Or warning
        iconColor = AppTheme.warning;
        break;
      case ToastType.error:
        icon = Symbols.cancel;
        iconColor = AppTheme.danger;
        break;
      case ToastType.info:
        icon = Symbols.info;
        iconColor = AppTheme.primary;
        break;
    }

    final fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              fToast.removeCustomToast();
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Symbols.close,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    // Xoá thông báo cũ nếu đang hiện
    fToast.removeCustomToast();
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.TOP_RIGHT,
      toastDuration: const Duration(seconds: 4),
    );
  }
}
