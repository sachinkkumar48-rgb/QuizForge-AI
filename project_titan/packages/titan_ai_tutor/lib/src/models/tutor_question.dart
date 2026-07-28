import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a question posed by the AI Tutor.
@immutable
class TutorQuestion {
  final String id;
  final String conceptId;
  final String questionText;
  final TutorQuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final TutorDifficultyLevel difficulty;
  final String misconceptionTarget;

  const TutorQuestion({
    required this.id,
    required this.conceptId,
    required this.questionText,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    required this.explanation,
    this.difficulty = TutorDifficultyLevel.intermediate,
    this.misconceptionTarget = '',
  });

  TutorQuestion copyWith({
    String? id,
    String? conceptId,
    String? questionText,
    TutorQuestionType? type,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    TutorDifficultyLevel? difficulty,
    String? misconceptionTarget,
  }) {
    return TutorQuestion(
      id: id ?? this.id,
      conceptId: conceptId ?? this.conceptId,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      misconceptionTarget: misconceptionTarget ?? this.misconceptionTarget,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conceptId': conceptId,
        'questionText': questionText,
        'type': type.name,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'difficulty': difficulty.name,
        'misconceptionTarget': misconceptionTarget,
      };

  factory TutorQuestion.fromJson(Map<String, dynamic> json) => TutorQuestion(
        id: json['id'] as String,
        conceptId: json['conceptId'] as String,
        questionText: json['questionText'] as String,
        type: TutorQuestionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TutorQuestionType.socratic,
        ),
        options: (json['options'] as List? ?? []).cast<String>(),
        correctAnswer: json['correctAnswer'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        difficulty: TutorDifficultyLevel.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => TutorDifficultyLevel.intermediate,
        ),
        misconceptionTarget: json['misconceptionTarget'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conceptId == other.conceptId &&
          questionText == other.questionText;

  @override
  int get hashCode => Object.hash(id, conceptId, questionText);
}
