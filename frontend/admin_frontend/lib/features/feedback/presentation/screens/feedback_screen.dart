import 'package:flutter/material.dart';
import '../widgets/feedback_header.dart';
import '../widgets/feedback_toolbar.dart';
import '../widgets/feedback_tabs.dart';
import '../widgets/feedback_table.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
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
            const FeedbackHeader(),
            const SizedBox(height: 32),
            const FeedbackToolbar(),
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
                  FeedbackTabs(
                    activeTab: _activeTab,
                    onTabChanged: (val) => setState(() => _activeTab = val),
                  ),
                  FeedbackTable(activeTab: _activeTab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
