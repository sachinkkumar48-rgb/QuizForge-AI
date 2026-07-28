import 'package:meta/meta.dart';

/// Immutable domain model representing AI Tutor/Mentor feedback for an assessment.
@immutable
class AssessmentFeedback {
  final String id;
  final String assessmentId;
  final String motivationalNote;
  final String strategicGuidance;
  final List<String> strengthsSummary;
  final List<String> weaknessSummary;

  const AssessmentFeedback({
    required this.id,
    required this.assessmentId,
    required this.motivationalNote,
    required this.strategicGuidance,
    this.strengthsSummary = const [],
    this.weaknessSummary = const [],
  });

  AssessmentFeedback copyWith({
    String? id,
    String? assessmentId,
    String? motivationalNote,
    String? strategicGuidance,
    List<String>? strengthsSummary,
    List<String>? weaknessSummary,
  }) {
    return AssessmentFeedback(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      motivationalNote: motivationalNote ?? this.motivationalNote,
      strategicGuidance: strategicGuidance ?? this.strategicGuidance,
      strengthsSummary: strengthsSummary ?? this.strengthsSummary,
      weaknessSummary: weaknessSummary ?? this.weaknessSummary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessmentId': assessmentId,
        'motivationalNote': motivationalNote,
        'strategicGuidance': strategicGuidance,
        'strengthsSummary': strengthsSummary,
        'weaknessSummary': weaknessSummary,
      };

  factory AssessmentFeedback.fromJson(Map<String, dynamic> json) =>
      AssessmentFeedback(
        id: json['id'] as String,
        assessmentId: json['assessmentId'] as String,
        motivationalNote: json['motivationalNote'] as String? ?? '',
        strategicGuidance: json['strategicGuidance'] as String? ?? '',
        strengthsSummary:
            (json['strengthsSummary'] as List? ?? []).cast<String>(),
        weaknessSummary:
            (json['weaknessSummary'] as List? ?? []).cast<String>(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentFeedback &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assessmentId == other.assessmentId;

  @override
  int get hashCode => Object.hash(id, assessmentId);
}
