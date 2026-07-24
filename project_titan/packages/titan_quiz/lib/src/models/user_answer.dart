import 'package:meta/meta.dart';

/// Immutable model representing a user's answer submission for a single question.
@immutable
class UserAnswer {
  final String questionId;
  final int? selectedOptionIndex;

  const UserAnswer({
    required this.questionId,
    this.selectedOptionIndex,
  });

  bool get isAnswered => selectedOptionIndex != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAnswer &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          selectedOptionIndex == other.selectedOptionIndex;

  @override
  int get hashCode => questionId.hashCode ^ selectedOptionIndex.hashCode;

  @override
  String toString() =>
      'UserAnswer(q:$questionId, option:${selectedOptionIndex ?? "unanswered"})';
}
