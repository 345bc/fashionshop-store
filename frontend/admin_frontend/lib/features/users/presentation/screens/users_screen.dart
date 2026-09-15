// GENERATED FROM TEMPLATE: templates/feature_screen.dart.template
import 'package:flutter/material.dart';
import '../widgets/users_header.dart';
import '../widgets/users_toolbar.dart';
import '../widgets/users_tabs.dart';
import '../widgets/users_table.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by AppLayout
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UsersHeader(),
            const SizedBox(height: 32),
            const UsersToolbar(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F0F0)), // AppTheme.borderLight
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  UsersTabs(),
                  UsersTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

