import 'package:flutter/material.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

/// Interactive horizontal scrollable strip displaying question statuses and quick jump navigation.
class QuestionProgressStrip extends StatelessWidget {
  final int currentIndex;
  final List<QuizQuestion> questions;
  final Map<String, InteractiveQuestionState> questionStates;
  final ValueChanged<int>? onQuestionTapped;

  const QuestionProgressStrip({
    super.key,
    required this.currentIndex,
    required this.questions,
    required this.questionStates,
    this.onQuestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final q = questions[index];
          final state = questionStates[q.id];
          final isCurrent = index == currentIndex;

          Color bgColor = colorScheme.surface;
          Color textColor = colorScheme.onSurface;
          Color borderColor = colorScheme.outlineVariant;

          if (state?.isSubmitted == true) {
            if (state?.isCorrect == true) {
              bgColor = Colors.green;
              textColor = Colors.white;
              borderColor = Colors.green;
            } else {
              bgColor = colorScheme.error;
              textColor = colorScheme.onError;
              borderColor = colorScheme.error;
            }
          } else if (isCurrent) {
            bgColor = colorScheme.primaryContainer;
            textColor = colorScheme.onPrimaryContainer;
            borderColor = colorScheme.primary;
          } else if (state?.isSelected == true) {
            bgColor = colorScheme.secondaryContainer;
            textColor = colorScheme.onSecondaryContainer;
          }

          return Semantics(
            label:
                'Question ${index + 1} status: ${state?.status.name ?? "unanswered"}',
            button: true,
            child: InkWell(
              onTap: onQuestionTapped != null
                  ? () => onQuestionTapped!(index)
                  : null,
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (state?.isMarkedForReview == true)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
