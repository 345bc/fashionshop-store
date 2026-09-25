import 'package:flutter/material.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_toolbar.dart';
import '../widgets/reports_summary_cards.dart';
import '../widgets/reports_tabs.dart';
import '../widgets/reports_table.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'month';
  String _activeTab = 'revenue'; // 'revenue' | 'products'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ReportsHeader(),
            const SizedBox(height: 32),
            ReportsToolbar(
              period: _period,
              onPeriodChanged: (val) => setState(() => _period = val),
            ),
            const SizedBox(height: 24),
            const ReportsSummaryCards(),
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
                  ReportsTabs(
                    activeTab: _activeTab,
                    onTabChanged: (val) => setState(() => _activeTab = val),
                  ),
                  ReportsTable(activeTab: _activeTab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
