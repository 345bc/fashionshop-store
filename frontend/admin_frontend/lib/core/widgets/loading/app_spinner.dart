import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AppSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppSpinner({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppTheme.primary),
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
