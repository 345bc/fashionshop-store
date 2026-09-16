// GENERATED FROM TEMPLATE: templates/feature_screen.dart.template
import 'package:flutter/material.dart';
import '../widgets/suppliers_header.dart';
import '../widgets/suppliers_toolbar.dart';
import '../widgets/suppliers_tabs.dart';
import '../widgets/suppliers_table.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SuppliersHeader(),
            const SizedBox(height: 32),
            const SuppliersToolbar(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF0F0F0)), // AppTheme.borderLight
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5), // 0.02 opacity
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  SuppliersTabs(),
                  SuppliersTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

