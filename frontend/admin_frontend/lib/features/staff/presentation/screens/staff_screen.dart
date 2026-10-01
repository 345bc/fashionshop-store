import 'package:flutter/material.dart';
import '../widgets/staff_header.dart';
import '../widgets/staff_toolbar.dart';
import '../widgets/staff_tabs.dart';
import '../widgets/staff_table.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _activeTab = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StaffHeader(),
            const SizedBox(height: 32),
            const StaffToolbar(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF0F0F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  StaffTabs(
                    activeTab: _activeTab,
                    onTabChanged: (val) => setState(() => _activeTab = val),
                  ),
                  StaffTable(activeTab: _activeTab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
