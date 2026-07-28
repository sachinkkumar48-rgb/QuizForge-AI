import 'package:meta/meta.dart';
import 'enums.dart';
import 'tutor_exercise.dart';
import 'tutor_evaluation.dart';
import 'tutor_progress.dart';

/// Immutable domain model representing an active or completed tutoring session.
@immutable
class TutorSession {
  final String id;
  final String learnerId;
  final String conceptId;
  final TutorSessionStatus status;
  final TutorPersona persona;
  final DateTime startedAt;
  final DateTime updatedAt;
  final List<TutorExercise> exercises;
  final TutorEvaluation? evaluation;
  final String currentGoalId;
  final String memoryId;
  final TutorProgress? progress;

  const TutorSession({
    required this.id,
    required this.learnerId,
    required this.conceptId,
    this.status = TutorSessionStatus.idle,
    this.persona = TutorPersona.intermediate,
    required this.startedAt,
    required this.updatedAt,
    this.exercises = const [],
    this.evaluation,
    this.currentGoalId = '',
    this.memoryId = '',
    this.progress,
  });

  TutorSession copyWith({
    String? id,
    String? learnerId,
    String? conceptId,
    TutorSessionStatus? status,
    TutorPersona? persona,
    DateTime? startedAt,
    DateTime? updatedAt,
    List<TutorExercise>? exercises,
    TutorEvaluation? evaluation,
    String? currentGoalId,
    String? memoryId,
    TutorProgress? progress,
  }) {
    return TutorSession(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      conceptId: conceptId ?? this.conceptId,
      status: status ?? this.status,
      persona: persona ?? this.persona,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
      evaluation: evaluation ?? this.evaluation,
      currentGoalId: currentGoalId ?? this.currentGoalId,
      memoryId: memoryId ?? this.memoryId,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learnerId': learnerId,
        'conceptId': conceptId,
        'status': status.name,
        'persona': persona.name,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'evaluation': evaluation?.toJson(),
        'currentGoalId': currentGoalId,
        'memoryId': memoryId,
        'progress': progress?.toJson(),
      };

  factory TutorSession.fromJson(Map<String, dynamic> json) => TutorSession(
        id: json['id'] as String,
        learnerId: json['learnerId'] as String,
        conceptId: json['conceptId'] as String,
        status: TutorSessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TutorSessionStatus.idle,
        ),
        persona: TutorPersona.values.firstWhere(
          (e) => e.name == json['persona'],
          orElse: () => TutorPersona.intermediate,
        ),
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => TutorExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        evaluation: json['evaluation'] != null
            ? TutorEvaluation.fromJson(
                json['evaluation'] as Map<String, dynamic>)
            : null,
        currentGoalId: json['currentGoalId'] as String? ?? '',
        memoryId: json['memoryId'] as String? ?? '',
        progress: json['progress'] != null
            ? TutorProgress.fromJson(json['progress'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          learnerId == other.learnerId &&
          conceptId == other.conceptId;

  @override
  int get hashCode => Object.hash(id, learnerId, conceptId);
}
