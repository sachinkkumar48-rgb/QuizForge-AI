import 'package:meta/meta.dart';

@immutable
class QuestionTrap {
  final String id;
  final String questionId;
  final String trapType; // e.g. Extreme Words, Misleading Assertion, Half Truth, Distractor Match
  final String commonMistake;
  final String expectedThinking;
  final String wrongEliminationStrategy;
  final String correctEliminationStrategy;

  const QuestionTrap({
    required this.id,
    required this.questionId,
    required this.trapType,
    required this.commonMistake,
    required this.expectedThinking,
    required this.wrongEliminationStrategy,
    required this.correctEliminationStrategy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionId': questionId,
        'trapType': trapType,
        'commonMistake': commonMistake,
        'expectedThinking': expectedThinking,
        'wrongEliminationStrategy': wrongEliminationStrategy,
        'correctEliminationStrategy': correctEliminationStrategy,
      };

  factory QuestionTrap.fromJson(Map<String, dynamic> json) => QuestionTrap(
        id: json['id'] as String,
        questionId: json['questionId'] as String,
        trapType: json['trapType'] as String,
        commonMistake: json['commonMistake'] as String? ?? '',
        expectedThinking: json['expectedThinking'] as String? ?? '',
        wrongEliminationStrategy:
            json['wrongEliminationStrategy'] as String? ?? '',
        correctEliminationStrategy:
            json['correctEliminationStrategy'] as String? ?? '',
      );
}
