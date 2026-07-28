import 'package:meta/meta.dart';

/// Immutable domain model representing Item Response Theory (IRT) adaptive assessment state.
@immutable
class AdaptiveAssessmentState {
  final String sessionId;
  final double currentTheta; // Ability estimate theta (-3.0 to +3.0)
  final double standardError;
  final int itemsAdministered;
  final double lastItemDifficulty;
  final int consecutiveCorrect;

  const AdaptiveAssessmentState({
    required this.sessionId,
    this.currentTheta = 0.0,
    this.standardError = 1.0,
    this.itemsAdministered = 0,
    this.lastItemDifficulty = 0.0,
    this.consecutiveCorrect = 0,
  });

  AdaptiveAssessmentState copyWith({
    String? sessionId,
    double? currentTheta,
    double? standardError,
    int? itemsAdministered,
    double? lastItemDifficulty,
    int? consecutiveCorrect,
  }) {
    return AdaptiveAssessmentState(
      sessionId: sessionId ?? this.sessionId,
      currentTheta: currentTheta ?? this.currentTheta,
      standardError: standardError ?? this.standardError,
      itemsAdministered: itemsAdministered ?? this.itemsAdministered,
      lastItemDifficulty: lastItemDifficulty ?? this.lastItemDifficulty,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'currentTheta': currentTheta,
        'standardError': standardError,
        'itemsAdministered': itemsAdministered,
        'lastItemDifficulty': lastItemDifficulty,
        'consecutiveCorrect': consecutiveCorrect,
      };

  factory AdaptiveAssessmentState.fromJson(Map<String, dynamic> json) =>
      AdaptiveAssessmentState(
        sessionId: json['sessionId'] as String,
        currentTheta: (json['currentTheta'] as num? ?? 0.0).toDouble(),
        standardError: (json['standardError'] as num? ?? 1.0).toDouble(),
        itemsAdministered: json['itemsAdministered'] as int? ?? 0,
        lastItemDifficulty:
            (json['lastItemDifficulty'] as num? ?? 0.0).toDouble(),
        consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveAssessmentState &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          currentTheta == other.currentTheta;

  @override
  int get hashCode => Object.hash(sessionId, currentTheta);
}
