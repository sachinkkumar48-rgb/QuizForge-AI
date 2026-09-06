/// Topic Mastery Profile Domain Entity (TITAN-KO-040.0 P40).
///
/// Immutable domain model capturing the progressive mastery state, statistical confidence,
/// evidence counts, and explainability breakdown for ONE topic or concept for ONE learner.
library;

import 'package:meta/meta.dart';

import 'mastery_classification.dart';

/// Immutable profile capturing estimated mastery and confidence for a topic.
@immutable
class TopicMasteryProfile {
  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Syllabus topic or concept identifier.
  final String topicId;

  /// Estimated mastery score in range [0.0, 1.0].
  final double masteryScore;

  /// Statistical confidence in range [0.0, 1.0].
  final double confidence;

  /// Total number of evidence items evaluated for this topic.
  final int evidenceCount;

  /// Total count of correct attempts/outcomes.
  final int correctCount;

  /// Total count of incorrect attempts/outcomes.
  final int incorrectCount;

  /// Accuracy over the most recent window of attempts, or null if no attempts.
  final double? recentAccuracy;

  /// Monotonic revision sequence of the authoritative learner state when evaluated.
  final int lastEvaluatedRevision;

  /// UTC timestamp of the most recent evaluation.
  final DateTime lastEvaluatedAt;

  /// Categorical classification level.
  final MasteryClassification classification;

  /// Deterministic human/machine-readable rationale explaining the current mastery state.
  final String explanation;

  /// Granular breakdown of evidence counts by difficulty and source.
  final Map<String, dynamic> contributingEvidenceSummary;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  TopicMasteryProfile({
    required String learnerId,
    required String examId,
    required String topicId,
    required this.masteryScore,
    required this.confidence,
    this.evidenceCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.recentAccuracy,
    this.lastEvaluatedRevision = 1,
    required this.lastEvaluatedAt,
    this.classification = MasteryClassification.notStarted,
    required this.explanation,
    Map<String, dynamic>? contributingEvidenceSummary,
    Map<String, dynamic>? metadata,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        topicId = topicId.trim(),
        contributingEvidenceSummary = Map<String, dynamic>.unmodifiable(
            contributingEvidenceSummary ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty in TopicMasteryProfile');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty in TopicMasteryProfile');
    }
    if (this.topicId.isEmpty) {
      throw ArgumentError('topicId cannot be empty in TopicMasteryProfile');
    }
    if (masteryScore < 0.0 || masteryScore > 1.0) {
      throw ArgumentError('masteryScore ($masteryScore) must be in [0.0, 1.0]');
    }
    if (confidence < 0.0 || confidence > 1.0) {
      throw ArgumentError('confidence ($confidence) must be in [0.0, 1.0]');
    }
    if (evidenceCount < 0) {
      throw ArgumentError('evidenceCount cannot be negative');
    }
    if (correctCount < 0 || incorrectCount < 0) {
      throw ArgumentError('correct/incorrect counts cannot be negative');
    }
    if (correctCount + incorrectCount > evidenceCount) {
      throw ArgumentError(
          'correctCount ($correctCount) + incorrectCount ($incorrectCount) cannot exceed evidenceCount ($evidenceCount)');
    }
    if (lastEvaluatedRevision < 1) {
      throw ArgumentError('lastEvaluatedRevision must be >= 1');
    }
    if (recentAccuracy != null &&
        (recentAccuracy! < 0.0 || recentAccuracy! > 1.0)) {
      throw ArgumentError('recentAccuracy must be in [0.0, 1.0]');
    }
  }

  /// Creates a clean unattempted profile for a topic.
  factory TopicMasteryProfile.initial({
    required String learnerId,
    required String examId,
    required String topicId,
    double initialScore = 0.15,
    DateTime? evaluatedAt,
    int revision = 1,
  }) {
    final effectiveTs = (evaluatedAt ?? DateTime.utc(2026, 1, 1)).toUtc();
    return TopicMasteryProfile(
      learnerId: learnerId,
      examId: examId,
      topicId: topicId,
      masteryScore: initialScore,
      confidence: 0.0,
      evidenceCount: 0,
      correctCount: 0,
      incorrectCount: 0,
      recentAccuracy: null,
      lastEvaluatedRevision: revision,
      lastEvaluatedAt: effectiveTs,
      classification: MasteryClassification.notStarted,
      explanation: 'Unattempted topic; baseline profile established.',
    );
  }

  TopicMasteryProfile copyWith({
    double? masteryScore,
    double? confidence,
    int? evidenceCount,
    int? correctCount,
    int? incorrectCount,
    double? recentAccuracy,
    int? lastEvaluatedRevision,
    DateTime? lastEvaluatedAt,
    MasteryClassification? classification,
    String? explanation,
    Map<String, dynamic>? contributingEvidenceSummary,
    Map<String, dynamic>? metadata,
  }) {
    return TopicMasteryProfile(
      learnerId: learnerId,
      examId: examId,
      topicId: topicId,
      masteryScore: masteryScore ?? this.masteryScore,
      confidence: confidence ?? this.confidence,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      recentAccuracy: recentAccuracy ?? this.recentAccuracy,
      lastEvaluatedRevision:
          lastEvaluatedRevision ?? this.lastEvaluatedRevision,
      lastEvaluatedAt: lastEvaluatedAt ?? this.lastEvaluatedAt,
      classification: classification ?? this.classification,
      explanation: explanation ?? this.explanation,
      contributingEvidenceSummary:
          contributingEvidenceSummary ?? this.contributingEvidenceSummary,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'examId': examId,
        'topicId': topicId,
        'masteryScore': masteryScore,
        'confidence': confidence,
        'evidenceCount': evidenceCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        if (recentAccuracy != null) 'recentAccuracy': recentAccuracy,
        'lastEvaluatedRevision': lastEvaluatedRevision,
        'lastEvaluatedAt': lastEvaluatedAt.toUtc().toIso8601String(),
        'classification': classification.toJson(),
        'explanation': explanation,
        'contributingEvidenceSummary': contributingEvidenceSummary,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory TopicMasteryProfile.fromJson(Map<String, dynamic> json) {
    return TopicMasteryProfile(
      learnerId: json['learnerId'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (json['incorrectCount'] as num?)?.toInt() ?? 0,
      recentAccuracy: (json['recentAccuracy'] as num?)?.toDouble(),
      lastEvaluatedRevision:
          (json['lastEvaluatedRevision'] as num?)?.toInt() ?? 1,
      lastEvaluatedAt: DateTime.parse(
              json['lastEvaluatedAt'] as String? ?? '2026-01-01T00:00:00.000Z')
          .toUtc(),
      classification:
          MasteryClassification.fromJson(json['classification'] as String?),
      explanation: json['explanation'] as String? ?? '',
      contributingEvidenceSummary:
          (json['contributingEvidenceSummary'] as Map<String, dynamic>?) ??
              const {},
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicMasteryProfile &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          topicId == other.topicId &&
          masteryScore == other.masteryScore &&
          confidence == other.confidence &&
          evidenceCount == other.evidenceCount &&
          correctCount == other.correctCount &&
          incorrectCount == other.incorrectCount &&
          recentAccuracy == other.recentAccuracy &&
          lastEvaluatedRevision == other.lastEvaluatedRevision &&
          lastEvaluatedAt == other.lastEvaluatedAt &&
          classification == other.classification;

  @override
  int get hashCode => Object.hash(
        learnerId,
        examId,
        topicId,
        masteryScore,
        confidence,
        evidenceCount,
        correctCount,
        incorrectCount,
        recentAccuracy,
        lastEvaluatedRevision,
        lastEvaluatedAt,
        classification,
      );

  @override
  String toString() =>
      'TopicMasteryProfile($topicId: score=${masteryScore.toStringAsFixed(2)}, conf=${confidence.toStringAsFixed(2)}, ${classification.name})';
}
