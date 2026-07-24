import 'package:meta/meta.dart';

/// Immutable model representing an option in a quiz question.
@immutable
class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          isCorrect == other.isCorrect;

  @override
  int get hashCode => Object.hash(id, text, isCorrect);

  @override
  String toString() => 'QuizOption($id: "$text", correct: $isCorrect)';
}
