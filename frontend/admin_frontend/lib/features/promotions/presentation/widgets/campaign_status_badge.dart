import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/status_badge.dart';
import '../../data/models/campaign_model.dart';

class CampaignStatusBadge extends StatelessWidget {
  final CampaignStatus status;
  const CampaignStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CampaignStatus.active => AppTheme.success,
      CampaignStatus.scheduled => AppTheme.warning,
      CampaignStatus.expired || CampaignStatus.exhausted => AppTheme.danger,
      CampaignStatus.paused => AppTheme.textSecondary,
    };
    return StatusBadge(
      text: status.label,
      textColor: color,
      backgroundColor: color.withAlpha(25),
    );
  }
}
