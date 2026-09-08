/// Assessment Result Domain Entities (TITAN-KO-049.0 P49).
///
/// Production domain models representing calculated exam scores, question-level
/// breakdowns, pass/fail evaluations, and cohort performance summaries.
library;

import 'package:meta/meta.dart';

import 'assessment.dart';

/// Evaluated result for a single question within an assessment.
@immutable
class AssessmentQuestionResult {
  final String questionId;
  final String? submittedAnswer;
  final String expectedAnswer;
  final bool isCorrect;
  final bool isAttempted;
  final double marksAwarded;
  final String? explanation;

  const AssessmentQuestionResult({
    required this.questionId,
    this.submittedAnswer,
    required this.expectedAnswer,
    required this.isCorrect,
    required this.isAttempted,
    required this.marksAwarded,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        if (submittedAnswer != null) 'submittedAnswer': submittedAnswer,
        'expectedAnswer': expectedAnswer,
        'isCorrect': isCorrect,
        'isAttempted': isAttempted,
        'marksAwarded': marksAwarded,
        if (explanation != null) 'explanation': explanation,
      };

  factory AssessmentQuestionResult.fromJson(Map<String, dynamic> json) =>
      AssessmentQuestionResult(
        questionId: json['questionId'] as String? ?? '',
        submittedAnswer: json['submittedAnswer'] as String?,
        expectedAnswer: json['expectedAnswer'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        isAttempted: json['isAttempted'] as bool? ?? false,
        marksAwarded: (json['marksAwarded'] as num?)?.toDouble() ?? 0.0,
        explanation: json['explanation'] as String?,
      );

  @override
  String toString() =>
      'AssessmentQuestionResult(q: $questionId, correct: $isCorrect, marks: $marksAwarded)';
}

/// Immutable evaluation result for a complete assessment attempt.
@immutable
class AssessmentResult {
  /// Unique canonical result identifier.
  final String resultId;

  /// Associated assessment identifier.
  final String assessmentId;

  /// Associated attempt identifier.
  final String attemptId;

  /// Evaluated learner identifier.
  final String learnerId;

  /// Total calculated marks achieved.
  final double score;

  /// Total maximum marks possible.
  final double maxScore;

  /// Performance percentage in range [0.0, 100.0].
  final double percentage;

  /// Whether the score satisfies the passing percentage threshold.
  final bool isPassed;

  /// Number of questions answered.
  final int attemptedCount;

  /// Number of questions answered correctly.
  final int correctCount;

  /// Number of questions answered incorrectly.
  final int incorrectCount;

  /// Number of questions left unanswered.
  final int unansweredCount;

  /// Granular question-level evaluation records.
  final List<AssessmentQuestionResult> questionResults;

  /// UTC evaluation timestamp.
  final DateTime evaluatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AssessmentResult({
    required this.resultId,
    required this.assessmentId,
    required this.attemptId,
    required this.learnerId,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.isPassed,
    this.attemptedCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.unansweredCount = 0,
    Iterable<AssessmentQuestionResult>? questionResults,
    DateTime? evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : questionResults = List<AssessmentQuestionResult>.unmodifiable(
            questionResults ?? const <AssessmentQuestionResult>[]),
        evaluatedAt = (evaluatedAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (attemptId.trim().isEmpty) {
      throw ArgumentError('attemptId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'resultId': resultId,
        'assessmentId': assessmentId,
        'attemptId': attemptId,
        'learnerId': learnerId,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'isPassed': isPassed,
        'attemptedCount': attemptedCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'unansweredCount': unansweredCount,
        'questionResults': questionResults.map((q) => q.toJson()).toList(),
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AssessmentResult.fromJson(Map<String, dynamic> json) =>
      AssessmentResult(
        resultId: json['resultId'] as String? ?? '',
        assessmentId: json['assessmentId'] as String? ?? '',
        attemptId: json['attemptId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        maxScore: (json['maxScore'] as num?)?.toDouble() ?? 0.0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        isPassed: json['isPassed'] as bool? ?? false,
        attemptedCount: (json['attemptedCount'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        incorrectCount: (json['incorrectCount'] as num?)?.toInt() ?? 0,
        unansweredCount: (json['unansweredCount'] as num?)?.toInt() ?? 0,
        questionResults: (json['questionResults'] as List<dynamic>?)?.map((e) =>
                AssessmentQuestionResult.fromJson(
                    Map<String, dynamic>.from(e as Map))) ??
            const [],
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentResult &&
          resultId == other.resultId &&
          assessmentId == other.assessmentId &&
          attemptId == other.attemptId &&
          learnerId == other.learnerId &&
          score == other.score &&
          maxScore == other.maxScore &&
          isPassed == other.isPassed;

  @override
  int get hashCode => Object.hash(resultId, assessmentId, attemptId, learnerId);

  @override
  String toString() =>
      'AssessmentResult(id: $resultId, score: $score/$maxScore, passed: $isPassed, acc: ${percentage.toStringAsFixed(1)}%)';
}

/// Cohort performance aggregate for an assessment.
@immutable
class AssessmentCohortSummary {
  final Assessment assessment;
  final String cohortId;
  final int totalLearners;
  final int attemptedCount;
  final int submittedCount;
  final double averageScore;
  final double averagePercentage;
  final int passCount;
  final int failCount;
  final List<AssessmentResult> results;

  AssessmentCohortSummary({
    required this.assessment,
    required this.cohortId,
    required this.totalLearners,
    required this.attemptedCount,
    required this.submittedCount,
    required this.averageScore,
    required this.averagePercentage,
    required this.passCount,
    required this.failCount,
    Iterable<AssessmentResult>? results,
  }) : results = List<AssessmentResult>.unmodifiable(
            results ?? const <AssessmentResult>[]);

  Map<String, dynamic> toJson() => {
        'assessment': assessment.toJson(),
        'cohortId': cohortId,
        'totalLearners': totalLearners,
        'attemptedCount': attemptedCount,
        'submittedCount': submittedCount,
        'averageScore': averageScore,
        'averagePercentage': averagePercentage,
        'passCount': passCount,
        'failCount': failCount,
        'results': results.map((r) => r.toJson()).toList(),
      };

  @override
  String toString() =>
      'AssessmentCohortSummary(assessment: "${assessment.title}", cohort: $cohortId, submitted: $submittedCount/$totalLearners, avg: ${averagePercentage.toStringAsFixed(1)}%)';
}
