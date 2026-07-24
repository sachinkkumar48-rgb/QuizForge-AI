import 'package:meta/meta.dart';

/// Immutable model representing a user's attempt on a single quiz question.
@immutable
class QuestionAttempt {
  final String questionId;
  final String? selectedOptionId;
  final bool isAnswered;
  final DateTime? answeredAt;
  final Duration timeSpent;

  const QuestionAttempt({
    required this.questionId,
    this.selectedOptionId,
    this.isAnswered = false,
    this.answeredAt,
    this.timeSpent = Duration.zero,
  });

  const QuestionAttempt.unanswered(this.questionId)
      : selectedOptionId = null,
        isAnswered = false,
        answeredAt = null,
        timeSpent = Duration.zero;

  QuestionAttempt copyWith({
    String? questionId,
    String? selectedOptionId,
    bool? isAnswered,
    DateTime? answeredAt,
    Duration? timeSpent,
  }) {
    return QuestionAttempt(
      questionId: questionId ?? this.questionId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isAnswered: isAnswered ?? this.isAnswered,
      answeredAt: answeredAt ?? this.answeredAt,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAttempt &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          selectedOptionId == other.selectedOptionId &&
          isAnswered == other.isAnswered &&
          answeredAt == other.answeredAt &&
          timeSpent == other.timeSpent;

  @override
  int get hashCode => Object.hash(
        questionId,
        selectedOptionId,
        isAnswered,
        answeredAt,
        timeSpent,
      );

  @override
  String toString() =>
      'QuestionAttempt(q: $questionId, opt: $selectedOptionId, answered: $isAnswered, time: ${timeSpent.inSeconds}s)';
}
