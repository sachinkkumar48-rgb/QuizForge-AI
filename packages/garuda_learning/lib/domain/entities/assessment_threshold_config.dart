/// Assessment Threshold Config (TITAN-KO-018.0 P18).
///
/// Configurable achievement criteria used by progress tracking.
library;

import 'package:meta/meta.dart';

@immutable
class AssessmentThresholdConfig {
  /// Minimum required question attempts before an objective can be achieved.
  final int minimumAttempts;

  /// Minimum required success rate (between 0.0 and 1.0) for achievement.
  final double minimumSuccessRate;

  const AssessmentThresholdConfig({
    this.minimumAttempts = 5,
    this.minimumSuccessRate = 0.80,
  })  : assert(minimumAttempts >= 1, 'minimumAttempts must be at least 1'),
        assert(minimumSuccessRate >= 0.0 && minimumSuccessRate <= 1.0,
            'minimumSuccessRate must be between 0.0 and 1.0');

  /// Determines whether the given attempt count and success rate satisfy achievement.
  bool isAchieved({required int attemptCount, required double successRate}) {
    return attemptCount >= minimumAttempts && successRate >= minimumSuccessRate;
  }

  Map<String, dynamic> toJson() => {
        'minimumAttempts': minimumAttempts,
        'minimumSuccessRate': minimumSuccessRate,
      };

  factory AssessmentThresholdConfig.fromJson(Map<String, dynamic> json) =>
      AssessmentThresholdConfig(
        minimumAttempts: json['minimumAttempts'] as int? ?? 5,
        minimumSuccessRate:
            (json['minimumSuccessRate'] as num?)?.toDouble() ?? 0.80,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentThresholdConfig &&
          minimumAttempts == other.minimumAttempts &&
          minimumSuccessRate == other.minimumSuccessRate;

  @override
  int get hashCode => Object.hash(minimumAttempts, minimumSuccessRate);

  @override
  String toString() =>
      'AssessmentThresholdConfig(minAttempts: $minimumAttempts, minSuccessRate: $minimumSuccessRate)';
}
