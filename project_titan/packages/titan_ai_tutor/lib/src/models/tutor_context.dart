import 'package:meta/meta.dart';
import 'enums.dart';
import 'tutor_difficulty.dart';

/// Immutable domain model representing context passed to the AI Tutor engine.
@immutable
class TutorContext {
  final String learnerId;
  final String targetConceptId;
  final TutorPersona persona;
  final TutorDifficulty currentDifficulty;
  final double studentMasteryScore;
  final List<String> recentMisconceptions;
  final List<String> userNotes;
  final List<String> availableVideos;
  final String activeGoalId;

  const TutorContext({
    required this.learnerId,
    required this.targetConceptId,
    this.persona = TutorPersona.intermediate,
    this.currentDifficulty = const TutorDifficulty(),
    this.studentMasteryScore = 0.0,
    this.recentMisconceptions = const [],
    this.userNotes = const [],
    this.availableVideos = const [],
    this.activeGoalId = '',
  });

  TutorContext copyWith({
    String? learnerId,
    String? targetConceptId,
    TutorPersona? persona,
    TutorDifficulty? currentDifficulty,
    double? studentMasteryScore,
    List<String>? recentMisconceptions,
    List<String>? userNotes,
    List<String>? availableVideos,
    String? activeGoalId,
  }) {
    return TutorContext(
      learnerId: learnerId ?? this.learnerId,
      targetConceptId: targetConceptId ?? this.targetConceptId,
      persona: persona ?? this.persona,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      studentMasteryScore: studentMasteryScore ?? this.studentMasteryScore,
      recentMisconceptions: recentMisconceptions ?? this.recentMisconceptions,
      userNotes: userNotes ?? this.userNotes,
      availableVideos: availableVideos ?? this.availableVideos,
      activeGoalId: activeGoalId ?? this.activeGoalId,
    );
  }

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'targetConceptId': targetConceptId,
        'persona': persona.name,
        'currentDifficulty': currentDifficulty.toJson(),
        'studentMasteryScore': studentMasteryScore,
        'recentMisconceptions': recentMisconceptions,
        'userNotes': userNotes,
        'availableVideos': availableVideos,
        'activeGoalId': activeGoalId,
      };

  factory TutorContext.fromJson(Map<String, dynamic> json) => TutorContext(
        learnerId: json['learnerId'] as String,
        targetConceptId: json['targetConceptId'] as String,
        persona: TutorPersona.values.firstWhere(
          (e) => e.name == json['persona'],
          orElse: () => TutorPersona.intermediate,
        ),
        currentDifficulty: json['currentDifficulty'] != null
            ? TutorDifficulty.fromJson(
                json['currentDifficulty'] as Map<String, dynamic>)
            : const TutorDifficulty(),
        studentMasteryScore:
            (json['studentMasteryScore'] as num? ?? 0.0).toDouble(),
        recentMisconceptions:
            (json['recentMisconceptions'] as List? ?? []).cast<String>(),
        userNotes: (json['userNotes'] as List? ?? []).cast<String>(),
        availableVideos:
            (json['availableVideos'] as List? ?? []).cast<String>(),
        activeGoalId: json['activeGoalId'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorContext &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          targetConceptId == other.targetConceptId &&
          persona == other.persona;

  @override
  int get hashCode => Object.hash(learnerId, targetConceptId, persona);
}
