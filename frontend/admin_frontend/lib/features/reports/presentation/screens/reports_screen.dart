import 'package:flutter/material.dart';

import '../../../dashboard/data/models/analytics_models.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

/// Compatibility route. All analytics now share the Dashboard feature.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const DashboardScreen(initialSection: AnalyticsSection.revenue);
}
