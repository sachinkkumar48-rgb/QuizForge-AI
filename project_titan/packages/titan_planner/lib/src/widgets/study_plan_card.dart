import 'package:flutter/material.dart';

import '../models/planner_models.dart';
import 'daily_summary_card.dart';
import 'progress_indicator_card.dart';
import 'study_timeline.dart';

/// Material 3 master plan container card displaying daily plan summary,
/// progress indicator, and expandable chronological study timeline.
class StudyPlanCard extends StatefulWidget {
  final StudyPlan plan;
  final ValueChanged<StudyTask>? onTaskToggle;
  final ValueChanged<StudyTask>? onTaskTap;
  final bool initiallyExpanded;

  const StudyPlanCard({
    super.key,
    required this.plan,
    this.onTaskToggle,
    this.onTaskTap,
    this.initiallyExpanded = true,
  });

  @override
  State<StudyPlanCard> createState() => _StudyPlanCardState();
}

class _StudyPlanCardState extends State<StudyPlanCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Summary Header Card
        DailySummaryCard(
          summary: widget.plan.summary,
          targetStudyTimeMinutes: widget.plan.targetStudyTimeMinutes,
        ),

        const SizedBox(height: 10.0),

        // Progress Indicator Card
        ProgressIndicatorCard(
          summary: widget.plan.summary,
        ),

        const SizedBox(height: 12.0),

        // Expand / Collapse Timeline Toggle Header
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 20.0,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Chronological Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8.0),

        // Animated Timeline List View
        if (_isExpanded)
          StudyTimeline(
            tasks: widget.plan.tasks,
            onTaskToggle: widget.onTaskToggle,
            onTaskTap: widget.onTaskTap,
          ),
      ],
    );
  }
}
