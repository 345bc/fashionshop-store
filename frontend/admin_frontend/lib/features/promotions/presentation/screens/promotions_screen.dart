import 'package:flutter/material.dart';
import '../widgets/promotions_header.dart';
import '../widgets/promotions_toolbar.dart';
import '../widgets/promotions_tabs.dart';
import '../widgets/promotions_table.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
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
            const PromotionsHeader(),
            const SizedBox(height: 32),
            const PromotionsToolbar(),
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
                  PromotionsTabs(
                    activeTab: _activeTab,
                    onTabChanged: (val) => setState(() => _activeTab = val),
                  ),
                  PromotionsTable(activeTab: _activeTab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
