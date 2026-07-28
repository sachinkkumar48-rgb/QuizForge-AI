import 'package:meta/meta.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'assessment_blueprint.dart';
import 'enums.dart';

/// Immutable domain model representing a complete Assessment.
@immutable
class Assessment {
  final String id;
  final String title;
  final String description;
  final AssessmentType type;
  final AssessmentBlueprint blueprint;
  final List<QuizQuestion> questions;
  final int totalDurationMinutes;
  final DateTime createdAt;

  const Assessment({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.blueprint,
    this.questions = const [],
    this.totalDurationMinutes = 30,
    required this.createdAt,
  });

  Assessment copyWith({
    String? id,
    String? title,
    String? description,
    AssessmentType? type,
    AssessmentBlueprint? blueprint,
    List<QuizQuestion>? questions,
    int? totalDurationMinutes,
    DateTime? createdAt,
  }) {
    return Assessment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      blueprint: blueprint ?? this.blueprint,
      questions: questions ?? this.questions,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'blueprint': blueprint.toJson(),
        'questions': questions
            .map((q) => {
                  'id': q.id,
                  'question': q.question,
                  'correctAnswerIndex': q.correctAnswerIndex,
                  'explanation': q.explanation,
                  'topic': q.topic,
                  'marks': q.marks,
                  'negativeMarks': q.negativeMarks,
                })
            .toList(),
        'totalDurationMinutes': totalDurationMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: AssessmentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AssessmentType.practiceTest,
        ),
        blueprint: AssessmentBlueprint.fromJson(
            json['blueprint'] as Map<String, dynamic>),
        questions: (json['questions'] as List? ?? [])
            .map((e) => QuizQuestion(
                  id: e['id'] as String? ?? '',
                  question: e['question'] as String? ?? '',
                  options: const [],
                  correctAnswerIndex: e['correctAnswerIndex'] as int? ?? 0,
                  explanation: e['explanation'] as String?,
                  topic: e['topic'] as String?,
                  marks: (e['marks'] as num? ?? 1.0).toDouble(),
                  negativeMarks:
                      (e['negativeMarks'] as num? ?? 0.33).toDouble(),
                ))
            .toList(),
        totalDurationMinutes: json['totalDurationMinutes'] as int? ?? 30,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Assessment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, title, type);
}
