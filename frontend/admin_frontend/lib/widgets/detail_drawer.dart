import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DetailDrawer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  const DetailDrawer({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 480, // Fixed width for detail panel
      backgroundColor: AppTheme.background,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (onClose != null) {
                      onClose!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Drawer Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
