/// Diagnostic Assessment Request (TITAN-KO-026.0 P26).
///
/// Input parameters requesting diagnostic assessment and placement evaluation.
library;

import 'package:meta/meta.dart';

import 'diagnostic_threshold_config.dart';

@immutable
class DiagnosticAssessmentRequest {
  final String requestId;
  final String learnerId;
  final List<String> targetObjectiveIds;
  final DateTime requestedAt;
  final DiagnosticThresholdConfig thresholdConfig;

  DiagnosticAssessmentRequest({
    required this.requestId,
    required this.learnerId,
    required List<String> targetObjectiveIds,
    required this.requestedAt,
    this.thresholdConfig = const DiagnosticThresholdConfig(),
  })  : assert(requestId.trim().isNotEmpty, 'requestId cannot be empty'),
        assert(learnerId.trim().isNotEmpty, 'learnerId cannot be empty'),
        assert(targetObjectiveIds.isNotEmpty,
            'targetObjectiveIds must contain at least one objective'),
        targetObjectiveIds = List.unmodifiable(targetObjectiveIds);

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'learnerId': learnerId,
        'targetObjectiveIds': targetObjectiveIds,
        'requestedAt': requestedAt.toIso8601String(),
        'thresholdConfig': thresholdConfig.toJson(),
      };

  factory DiagnosticAssessmentRequest.fromJson(Map<String, dynamic> json) =>
      DiagnosticAssessmentRequest(
        requestId: json['requestId'] as String,
        learnerId: json['learnerId'] as String,
        targetObjectiveIds:
            List<String>.from(json['targetObjectiveIds'] as List? ?? []),
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        thresholdConfig: json['thresholdConfig'] != null
            ? DiagnosticThresholdConfig.fromJson(
                json['thresholdConfig'] as Map<String, dynamic>)
            : const DiagnosticThresholdConfig(),
      );
}
