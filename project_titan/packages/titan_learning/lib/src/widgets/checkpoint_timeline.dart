import 'package:flutter/material.dart';

import '../models/learning_session_models.dart';

/// Visual timeline rendering current progress through the 14 steps of the learning pipeline.
class CheckpointTimeline extends StatelessWidget {
  final LearningFlowStep currentStep;
  final void Function(LearningFlowStep step)? onStepTap;

  const CheckpointTimeline({
    super.key,
    required this.currentStep,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final steps = [
      LearningFlowStep.learningContent,
      LearningFlowStep.mediaPlayback,
      LearningFlowStep.smartNotes,
      LearningFlowStep.aiTutor,
      LearningFlowStep.quickQuiz,
      LearningFlowStep.adaptiveAssessment,
      LearningFlowStep.instantFeedback,
      LearningFlowStep.revisionPlan,
    ];

    return Semantics(
      label: 'Learning Step Timeline',
      container: true,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: colorScheme.surfaceContainerLow,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: steps.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final step = steps[index];
            final isCurrent = step == currentStep;
            final isPassed = currentStep.index > step.index;

            Color bgColor;
            Color textColor;
            if (isCurrent) {
              bgColor = colorScheme.primary;
              textColor = colorScheme.onPrimary;
            } else if (isPassed) {
              bgColor = colorScheme.primaryContainer;
              textColor = colorScheme.onPrimaryContainer;
            } else {
              bgColor = colorScheme.surfaceContainerHighest;
              textColor = colorScheme.onSurfaceVariant;
            }

            return InkWell(
              onTap: () => onStepTap?.call(step),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (isPassed)
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: textColor)
                    else
                      Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _getStepLabel(step),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getStepLabel(LearningFlowStep step) {
    switch (step) {
      case LearningFlowStep.learningContent:
        return 'Content';
      case LearningFlowStep.mediaPlayback:
        return 'Media';
      case LearningFlowStep.smartNotes:
        return 'Notes';
      case LearningFlowStep.aiTutor:
        return 'AI Tutor';
      case LearningFlowStep.quickQuiz:
        return 'Quiz';
      case LearningFlowStep.adaptiveAssessment:
        return 'Assessment';
      case LearningFlowStep.instantFeedback:
        return 'Feedback';
      case LearningFlowStep.revisionPlan:
        return 'Revision';
      default:
        return 'Step';
    }
  }
}
