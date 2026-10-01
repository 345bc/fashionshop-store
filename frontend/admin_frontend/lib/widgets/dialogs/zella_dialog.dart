import 'package:flutter/material.dart';

class ZellaDialog extends StatelessWidget {
  final double width;
  final double? height;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ZellaDialog({
    super.key,
    this.width = 400,
    this.height,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        child: child,
      ),
    );
  }
}
