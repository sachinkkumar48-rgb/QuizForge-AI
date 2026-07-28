import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting an identified skill gap.
class SkillGapCard extends StatelessWidget {
  final SkillGap gap;

  const SkillGapCard({super.key, required this.gap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.warning,
          color: gap.gapSeverity == 'High' ? Colors.red : Colors.orange,
        ),
        title: Text(gap.conceptTitle),
        subtitle: Text(gap.recommendedAction),
        trailing: Chip(
          label: Text(gap.gapSeverity),
          backgroundColor: gap.gapSeverity == 'High'
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.tertiaryContainer,
        ),
      ),
    );
  }
}
