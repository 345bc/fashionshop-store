import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AppProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: backgroundColor ?? AppTheme.borderLight,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppTheme.primary),
      ),
    );
  }
}
