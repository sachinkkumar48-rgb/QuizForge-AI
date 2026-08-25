/// Weak Spot Profile Entity (TITAN-KO-023.0 P23 Stage 2).
///
/// Immutable domain model capturing observed evidence-based diagnostic weak spots
/// for ONE learner across a curriculum framework or domain.
///
/// Educational Safety Principles:
/// - Invariant: Zero attempts != weak performance.
/// - Invariant: Sparse attempts (< [minimumEvidenceThreshold]) != weak performance.
/// - An objective is ONLY diagnosed as a weak spot when sufficient evidence is recorded
///   ([attemptCount] >= [minimumEvidenceThreshold]) AND observed accuracy falls below [weaknessThreshold].
/// - This entity does NOT generate recommendation payloads, does NOT invoke P21,
///   and does NOT produce causal remediation prescriptions.
library;

import 'package:meta/meta.dart';

import 'bloom_taxonomy_level.dart';

/// Diagnostic summary of an individual learning objective exhibiting observed weakness.
@immutable
class WeakObjectiveDiagnostic {
  /// Unique identifier of the struggling learning objective.
  final String objectiveId;

  /// Optional curriculum domain identifier.
  final String? domainId;

  /// Total count of attempts recorded for this objective (must meet or exceed evidence threshold).
  final int attemptCount;

  /// Total count of correct attempts recorded.
  final int correctCount;

  /// Observed raw accuracy ratio for this objective in range [0.0, 1.0].
  final double observedAccuracy;

  /// Optional cognitive complexity level of the objective.
  final BloomTaxonomyLevel? bloomLevel;

  /// Number of consecutive incorrect submissions recorded at the tail of attempt history.
  final int consecutiveIncorrectCount;

  /// Normalized deficiency index in range [0.0, 1.0] (higher value = stronger evidence of struggle).
  final double deficiencyScore;

  /// UTC timestamp of the most recent attempt for this objective.
  final DateTime? lastAttemptedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  WeakObjectiveDiagnostic({
    required this.objectiveId,
    this.domainId,
    required this.attemptCount,
    required this.correctCount,
    double? observedAccuracy,
    this.bloomLevel,
    this.consecutiveIncorrectCount = 0,
    double? deficiencyScore,
    DateTime? lastAttemptedAt,
    Map<String, dynamic>? metadata,
  })  : observedAccuracy = attemptCount == 0
            ? 0.0
            : (observedAccuracy ?? (correctCount / attemptCount))
                .clamp(0.0, 1.0),
        deficiencyScore = (deficiencyScore ??
                (attemptCount == 0
                    ? 0.0
                    : (1.0 - (correctCount / attemptCount))))
            .clamp(0.0, 1.0),
        lastAttemptedAt = lastAttemptedAt?.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError(
          'ObjectiveId cannot be empty for WeakObjectiveDiagnostic');
    }
    if (attemptCount < 1) {
      throw ArgumentError(
          'AttemptCount ($attemptCount) must be at least 1 to diagnose a weak spot');
    }
    if (correctCount < 0 || correctCount > attemptCount) {
      throw ArgumentError(
          'CorrectCount ($correctCount) must be between 0 and attemptCount ($attemptCount)');
    }
    if (consecutiveIncorrectCount < 0) {
      throw ArgumentError('ConsecutiveIncorrectCount cannot be negative');
    }
  }

  /// Serializes weak objective diagnostic to JSON map.
  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        if (domainId != null) 'domainId': domainId,
        'attemptCount': attemptCount,
        'correctCount': correctCount,
        'observedAccuracy': observedAccuracy,
        if (bloomLevel != null) 'bloomLevel': bloomLevel!.name,
        'consecutiveIncorrectCount': consecutiveIncorrectCount,
        'deficiencyScore': deficiencyScore,
        if (lastAttemptedAt != null)
          'lastAttemptedAt': lastAttemptedAt!.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes weak objective diagnostic from JSON map.
  factory WeakObjectiveDiagnostic.fromJson(Map<String, dynamic> json) =>
      WeakObjectiveDiagnostic(
        objectiveId: json['objectiveId'] as String? ?? '',
        domainId: json['domainId'] as String?,
        attemptCount: json['attemptCount'] as int? ?? 1,
        correctCount: json['correctCount'] as int? ?? 0,
        observedAccuracy: (json['observedAccuracy'] as num?)?.toDouble(),
        bloomLevel: json['bloomLevel'] != null
            ? BloomTaxonomyLevel.values.firstWhere(
                (e) => e.name == json['bloomLevel'],
                orElse: () => BloomTaxonomyLevel.understand,
              )
            : null,
        consecutiveIncorrectCount:
            json['consecutiveIncorrectCount'] as int? ?? 0,
        deficiencyScore: (json['deficiencyScore'] as num?)?.toDouble(),
        lastAttemptedAt: json['lastAttemptedAt'] != null
            ? DateTime.parse(json['lastAttemptedAt'] as String).toUtc()
            : null,
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeakObjectiveDiagnostic &&
          runtimeType == other.runtimeType &&
          objectiveId == other.objectiveId &&
          domainId == other.domainId &&
          attemptCount == other.attemptCount &&
          correctCount == other.correctCount &&
          observedAccuracy == other.observedAccuracy &&
          bloomLevel == other.bloomLevel &&
          consecutiveIncorrectCount == other.consecutiveIncorrectCount &&
          deficiencyScore == other.deficiencyScore &&
          lastAttemptedAt == other.lastAttemptedAt;

  @override
  int get hashCode => Object.hash(
        objectiveId,
        domainId,
        attemptCount,
        correctCount,
        observedAccuracy,
        bloomLevel,
        consecutiveIncorrectCount,
        deficiencyScore,
        lastAttemptedAt,
      );

  @override
  String toString() =>
      'WeakObjectiveDiagnostic($objectiveId: attempts=$attemptCount, '
      'accuracy=${(observedAccuracy * 100).toStringAsFixed(1)}%, '
      'deficiency=${deficiencyScore.toStringAsFixed(2)})';
}

/// Aggregated evidence-based weak-spot profile for ONE learner.
@immutable
class WeakSpotProfile {
  /// Default accuracy threshold below which an objective is classified as weak.
  static const double defaultWeaknessThreshold = 0.60;

  /// Default minimum attempt count required to consider an objective diagnostically evaluable.
  static const int defaultEvidenceThreshold = 5;

  /// Target learner identifier.
  final String learnerId;

  /// Optional curriculum scope identifier (e.g. framework ID or domain ID).
  final String? scopeId;

  /// Total count of learning objectives evaluated in scope.
  final int totalEvaluatedObjectives;

  /// Count of evaluated learning objectives that met the minimum evidence threshold.
  final int evaluatedWithSufficientEvidence;

  /// Unmodifiable list of diagnosed weak objectives, sorted deterministically by deficiency score descending.
  final List<WeakObjectiveDiagnostic> weakObjectives;

  /// Configured accuracy threshold below which an objective is classified as weak.
  final double weaknessThreshold;

  /// Minimum attempt threshold required for an objective to qualify for weak-spot analysis.
  final int minimumEvidenceThreshold;

  /// UTC timestamp when this weak-spot profile was evaluated.
  final DateTime evaluatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  WeakSpotProfile({
    required this.learnerId,
    this.scopeId,
    required this.totalEvaluatedObjectives,
    required this.evaluatedWithSufficientEvidence,
    List<WeakObjectiveDiagnostic>? weakObjectives,
    double weaknessThreshold = defaultWeaknessThreshold,
    this.minimumEvidenceThreshold = defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : weaknessThreshold = weaknessThreshold.clamp(0.0, 1.0),
        evaluatedAt = evaluatedAt.toUtc(),
        weakObjectives = List<WeakObjectiveDiagnostic>.unmodifiable(
          _sortWeakObjectives(
              weakObjectives ?? const <WeakObjectiveDiagnostic>[]),
        ),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for WeakSpotProfile');
    }
    if (totalEvaluatedObjectives < 0) {
      throw ArgumentError('TotalEvaluatedObjectives cannot be negative');
    }
    if (evaluatedWithSufficientEvidence < 0 ||
        evaluatedWithSufficientEvidence > totalEvaluatedObjectives) {
      throw ArgumentError(
          'EvaluatedWithSufficientEvidence ($evaluatedWithSufficientEvidence) must be between 0 and totalEvaluatedObjectives ($totalEvaluatedObjectives)');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }
  }

  /// Sorts weak objectives deterministically: deficiency score descending, then objectiveId ascending.
  static List<WeakObjectiveDiagnostic> _sortWeakObjectives(
      List<WeakObjectiveDiagnostic> list) {
    final copy = List<WeakObjectiveDiagnostic>.from(list);
    copy.sort((a, b) {
      final scoreComparison = b.deficiencyScore.compareTo(a.deficiencyScore);
      if (scoreComparison != 0) return scoreComparison;
      return a.objectiveId.compareTo(b.objectiveId);
    });
    return copy;
  }

  /// Total count of diagnosed weak spots.
  int get identifiedWeakSpotsCount => weakObjectives.length;

  /// Whether any weak spots were identified with sufficient evidence.
  bool get hasWeakSpots => weakObjectives.isNotEmpty;

  /// Serializes weak-spot profile to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        if (scopeId != null) 'scopeId': scopeId,
        'totalEvaluatedObjectives': totalEvaluatedObjectives,
        'evaluatedWithSufficientEvidence': evaluatedWithSufficientEvidence,
        'weakObjectives': weakObjectives.map((e) => e.toJson()).toList(),
        'weaknessThreshold': weaknessThreshold,
        'minimumEvidenceThreshold': minimumEvidenceThreshold,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes weak-spot profile from JSON map.
  factory WeakSpotProfile.fromJson(Map<String, dynamic> json) =>
      WeakSpotProfile(
        learnerId: json['learnerId'] as String? ?? '',
        scopeId: json['scopeId'] as String?,
        totalEvaluatedObjectives: json['totalEvaluatedObjectives'] as int? ?? 0,
        evaluatedWithSufficientEvidence:
            json['evaluatedWithSufficientEvidence'] as int? ?? 0,
        weakObjectives: (json['weakObjectives'] as List<dynamic>?)
            ?.map((e) =>
                WeakObjectiveDiagnostic.fromJson(e as Map<String, dynamic>))
            .toList(),
        weaknessThreshold: (json['weaknessThreshold'] as num?)?.toDouble() ??
            defaultWeaknessThreshold,
        minimumEvidenceThreshold: json['minimumEvidenceThreshold'] as int? ??
            defaultEvidenceThreshold,
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeakSpotProfile &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          scopeId == other.scopeId &&
          totalEvaluatedObjectives == other.totalEvaluatedObjectives &&
          evaluatedWithSufficientEvidence ==
              other.evaluatedWithSufficientEvidence &&
          weaknessThreshold == other.weaknessThreshold &&
          minimumEvidenceThreshold == other.minimumEvidenceThreshold &&
          evaluatedAt == other.evaluatedAt &&
          _listEquals(weakObjectives, other.weakObjectives);

  static bool _listEquals(
      List<WeakObjectiveDiagnostic> a, List<WeakObjectiveDiagnostic> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var listHash = 0;
    for (final item in weakObjectives) {
      listHash ^= item.hashCode;
    }
    return Object.hash(
      learnerId,
      scopeId,
      totalEvaluatedObjectives,
      evaluatedWithSufficientEvidence,
      listHash,
      weaknessThreshold,
      minimumEvidenceThreshold,
      evaluatedAt,
    );
  }

  @override
  String toString() =>
      'WeakSpotProfile(learnerId: $learnerId, identifiedWeakSpots: $identifiedWeakSpotsCount, '
      'sufficientEvidence: $evaluatedWithSufficientEvidence/$totalEvaluatedObjectives)';
}
