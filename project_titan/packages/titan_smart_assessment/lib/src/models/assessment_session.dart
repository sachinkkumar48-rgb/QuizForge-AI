import 'package:meta/meta.dart';
import 'adaptive_assessment_state.dart';
import 'assessment_attempt.dart';
import 'enums.dart';

/// Immutable domain model representing an active user assessment session.
@immutable
class AssessmentSession {
  final String id;
  final String assessmentId;
  final String userId;
  final AssessmentStatus status;
  final int currentQuestionIndex;
  final List<AssessmentAttempt> attempts;
  final AdaptiveAssessmentState? adaptiveState;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const AssessmentSession({
    required this.id,
    required this.assessmentId,
    required this.userId,
    this.status = AssessmentStatus.ready,
    this.currentQuestionIndex = 0,
    this.attempts = const [],
    this.adaptiveState,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });

  AssessmentSession copyWith({
    String? id,
    String? assessmentId,
    String? userId,
    AssessmentStatus? status,
    int? currentQuestionIndex,
    List<AssessmentAttempt>? attempts,
    AdaptiveAssessmentState? adaptiveState,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return AssessmentSession(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      attempts: attempts ?? this.attempts,
      adaptiveState: adaptiveState ?? this.adaptiveState,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessmentId': assessmentId,
        'userId': userId,
        'status': status.name,
        'currentQuestionIndex': currentQuestionIndex,
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'adaptiveState': adaptiveState?.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory AssessmentSession.fromJson(Map<String, dynamic> json) =>
      AssessmentSession(
        id: json['id'] as String,
        assessmentId: json['assessmentId'] as String,
        userId: json['userId'] as String,
        status: AssessmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AssessmentStatus.ready,
        ),
        currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
        attempts: (json['attempts'] as List? ?? [])
            .map((e) => AssessmentAttempt.fromJson(e as Map<String, dynamic>))
            .toList(),
        adaptiveState: json['adaptiveState'] != null
            ? AdaptiveAssessmentState.fromJson(
                json['adaptiveState'] as Map<String, dynamic>)
            : null,
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionIdMatches(other);

  bool sessionIdMatches(AssessmentSession other) =>
      assessmentId == other.assessmentId && userId == other.userId;

  @override
  int get hashCode => Object.hash(id, assessmentId, userId);
}
