/// Adaptive Question Selection Result Domain Entity (TITAN-KO-033.0 P33).
///
/// Encapsulates the output of the adaptive question selection pipeline,
/// containing winning practice questions alongside the comprehensive candidate audit log.
///
/// Educational Safety & Audit Invariants:
/// - Preserves 100% of question provenance and metadata.
/// - Unmodifiable result lists preventing downstream mutation.
/// - Explicit constraint limit reporting when diversity restricts full allocation.
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import 'adaptive_question_candidate.dart';
import 'adaptive_question_selection_config.dart';

@immutable
class AdaptiveQuestionSelectionResult {
  /// Target examination identifier.
  final String examId;

  /// Ordered list of selected questions for the practice session.
  final List<NormalizedQuestion> selectedQuestions;

  /// Ordered list of winning evaluated candidates.
  final List<AdaptiveQuestionCandidate> selectedCandidates;

  /// Complete audit trail of all evaluated questions with eligibility and exclusion reasons.
  final List<AdaptiveQuestionCandidate> allCandidates;

  /// Number of questions requested in config.
  final int requestedCount;

  /// Actual number of questions successfully selected.
  final int selectedCount;

  /// Total count of questions in corpus that met exam, scope, and exposure criteria.
  final int eligibleCount;

  /// Total count of questions evaluated but excluded.
  final int excludedCount;

  /// Configuration used to drive this selection.
  final AdaptiveQuestionSelectionConfig config;

  /// Caller-supplied evaluation timestamp.
  final DateTime? selectedAt;

  /// Topic and examination year allocation breakdown.
  final Map<String, int> diversitySummary;

  /// Whether fewer questions than requested were returned due to diversity or pool limits.
  final bool isConstraintLimited;

  /// Diagnostic explanation when [isConstraintLimited] is true.
  final String? constraintLimitReason;

  AdaptiveQuestionSelectionResult({
    required String examId,
    required List<NormalizedQuestion> selectedQuestions,
    required List<AdaptiveQuestionCandidate> selectedCandidates,
    required List<AdaptiveQuestionCandidate> allCandidates,
    required this.requestedCount,
    required this.eligibleCount,
    required this.config,
    this.selectedAt,
    Map<String, int>? diversitySummary,
    this.isConstraintLimited = false,
    this.constraintLimitReason,
  })  : examId = examId.trim().toLowerCase(),
        selectedQuestions =
            List<NormalizedQuestion>.unmodifiable(selectedQuestions),
        selectedCandidates =
            List<AdaptiveQuestionCandidate>.unmodifiable(selectedCandidates),
        allCandidates =
            List<AdaptiveQuestionCandidate>.unmodifiable(allCandidates),
        selectedCount = selectedQuestions.length,
        excludedCount = allCandidates.length - selectedQuestions.length,
        diversitySummary = Map<String, int>.unmodifiable(
            diversitySummary ?? const <String, int>{});

  /// Empty result for safe failure.
  factory AdaptiveQuestionSelectionResult.empty({
    required String examId,
    required AdaptiveQuestionSelectionConfig config,
    DateTime? selectedAt,
    String? reason,
  }) =>
      AdaptiveQuestionSelectionResult(
        examId: examId,
        selectedQuestions: const [],
        selectedCandidates: const [],
        allCandidates: const [],
        requestedCount: config.targetQuestionCount,
        eligibleCount: 0,
        config: config,
        selectedAt: selectedAt,
        isConstraintLimited: true,
        constraintLimitReason:
            reason ?? 'Corpus empty or no eligible questions',
      );

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'requestedCount': requestedCount,
        'selectedCount': selectedCount,
        'eligibleCount': eligibleCount,
        'excludedCount': excludedCount,
        if (selectedAt != null) 'selectedAt': selectedAt!.toIso8601String(),
        'isConstraintLimited': isConstraintLimited,
        if (constraintLimitReason != null)
          'constraintLimitReason': constraintLimitReason,
        'diversitySummary': diversitySummary,
        'config': config.toJson(),
        'selectedQuestions': selectedQuestions.map((q) => q.toJson()).toList(),
        'selectedCandidates':
            selectedCandidates.map((c) => c.toJson()).toList(),
        'allCandidates': allCandidates.map((c) => c.toJson()).toList(),
      };

  @override
  String toString() =>
      'AdaptiveQuestionSelectionResult(exam: $examId, selected: $selectedCount/$requestedCount, eligible: $eligibleCount, limited: $isConstraintLimited)';
}
