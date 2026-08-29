/// Diagnostic Threshold Configuration (TITAN-KO-026.0 P26).
///
/// Encapsulates deterministic, configurable threshold values for evidence
/// sufficiency and placement determinations.
library;

import 'package:meta/meta.dart';

@immutable
class DiagnosticThresholdConfig {
  /// Minimum number of attempts required to establish sufficient evidence.
  final int minimumEvidenceThreshold;

  /// Accuracy ratio threshold [0.0, 1.0] for demonstrated placement.
  final double masteryThreshold;

  /// Accuracy ratio threshold [0.0, 1.0] below which remediation is targeted.
  final double developingThreshold;

  const DiagnosticThresholdConfig({
    this.minimumEvidenceThreshold = 3,
    this.masteryThreshold = 0.70,
    this.developingThreshold = 0.50,
  })  : assert(minimumEvidenceThreshold >= 1,
            'minimumEvidenceThreshold must be at least 1'),
        assert(masteryThreshold >= 0.0 && masteryThreshold <= 1.0,
            'masteryThreshold must be in [0.0, 1.0]'),
        assert(
            developingThreshold >= 0.0 &&
                developingThreshold <= masteryThreshold,
            'developingThreshold must be in [0.0, masteryThreshold]');

  Map<String, dynamic> toJson() => {
        'minimumEvidenceThreshold': minimumEvidenceThreshold,
        'masteryThreshold': masteryThreshold,
        'developingThreshold': developingThreshold,
      };

  factory DiagnosticThresholdConfig.fromJson(Map<String, dynamic> json) =>
      DiagnosticThresholdConfig(
        minimumEvidenceThreshold:
            (json['minimumEvidenceThreshold'] as num?)?.toInt() ?? 3,
        masteryThreshold:
            (json['masteryThreshold'] as num?)?.toDouble() ?? 0.70,
        developingThreshold:
            (json['developingThreshold'] as num?)?.toDouble() ?? 0.50,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticThresholdConfig &&
          runtimeType == other.runtimeType &&
          minimumEvidenceThreshold == other.minimumEvidenceThreshold &&
          masteryThreshold == other.masteryThreshold &&
          developingThreshold == other.developingThreshold;

  @override
  int get hashCode => Object.hash(
        minimumEvidenceThreshold,
        masteryThreshold,
        developingThreshold,
      );
}
