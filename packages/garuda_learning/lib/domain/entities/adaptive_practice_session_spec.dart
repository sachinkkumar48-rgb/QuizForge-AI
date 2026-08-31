/// Adaptive Practice Session Specification Domain Entity (TITAN-KO-034.0 P34).
///
/// Encapsulates the orchestrated specification of an evidence-ready practice session,
/// including deterministic question sequencing, pedagogical section construction,
/// multi-dimensional distribution analytics, and time/workload estimation.
///
/// Educational Safety & Non-Predictive Invariants:
/// - Organizes verified questions deterministically; zero question fabrication.
/// - Zero predictions regarding future exam appearances.
/// - Preserves complete source provenance and P33 selection audit trail.
/// - Immutable collections preventing runtime tampering.
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import 'adaptive_practice_session_config.dart';
import 'adaptive_question_candidate.dart';
import 'adaptive_question_selection_config.dart';
import 'adaptive_question_selection_result.dart';
import 'learning_session.dart';
import 'learning_session_state.dart';
import 'session_configuration.dart';

/// Structured section/block within an orchestrated practice session.
@immutable
class PracticeSessionSection {
  /// Deterministic section identifier (e.g., 'sec_1_warmup', 'sec_2_core').
  final String sectionId;

  /// Human-readable section heading.
  final String title;

  /// Pedagogical intent or description of this section.
  final String description;

  /// Ordered list of question IDs included in this section.
  final List<String> questionIds;

  /// Ordered list of questions included in this section.
  final List<NormalizedQuestion> questions;

  /// Evaluation candidate audit data for questions in this section.
  final List<AdaptiveQuestionCandidate> candidateMetadata;

  /// Estimated workload in seconds for completing this section.
  final int estimatedSeconds;

  PracticeSessionSection({
    required this.sectionId,
    required this.title,
    required this.description,
    required List<String> questionIds,
    required List<NormalizedQuestion> questions,
    required List<AdaptiveQuestionCandidate> candidateMetadata,
    required this.estimatedSeconds,
  })  : questionIds = List<String>.unmodifiable(questionIds),
        questions = List<NormalizedQuestion>.unmodifiable(questions),
        candidateMetadata =
            List<AdaptiveQuestionCandidate>.unmodifiable(candidateMetadata) {
    if (sectionId.trim().isEmpty) {
      throw ArgumentError(
          'sectionId cannot be empty for PracticeSessionSection');
    }
    if (estimatedSeconds < 0) {
      throw ArgumentError(
          'estimatedSeconds cannot be negative ($estimatedSeconds)');
    }
  }

  /// Total questions in this section.
  int get questionCount => questions.length;

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'title': title,
        'description': description,
        'questionIds': questionIds,
        'questions': questions.map((q) => q.toJson()).toList(),
        'candidateMetadata': candidateMetadata.map((c) => c.toJson()).toList(),
        'estimatedSeconds': estimatedSeconds,
      };

  factory PracticeSessionSection.fromJson(Map<String, dynamic> json) =>
      PracticeSessionSection(
        sectionId: json['sectionId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        questionIds: (json['questionIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((e) => NormalizedQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        candidateMetadata: (json['candidateMetadata'] as List<dynamic>? ??
                const [])
            .map((e) =>
                AdaptiveQuestionCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        estimatedSeconds: json['estimatedSeconds'] as int? ?? 0,
      );

  @override
  String toString() =>
      'PracticeSessionSection($sectionId: "$title", count: $questionCount, est: ${estimatedSeconds}s)';
}

/// Multi-dimensional distribution breakdown for the orchestrated session.
@immutable
class PracticeSessionDistribution {
  /// Question count per learning objective ID.
  final Map<String, int> objectiveCounts;

  /// Question count per syllabus topic.
  final Map<String, int> topicCounts;

  /// Question count per examination year.
  final Map<int, int> yearCounts;

  /// Question count per difficulty tier (e.g. 'easy', 'medium', 'hard', 'unspecified').
  final Map<String, int> difficultyCounts;

  /// Total count of questions originating from historical PYQ examination papers.
  final int historicalQuestionCount;

  /// Ratio of historical PYQ questions relative to total session questions (in [0.0, 1.0]).
  final double historicalQuestionRatio;

  /// Count of historical questions from the most recent 3 examination years.
  final int recentHistoricalQuestionCount;

  /// Count of questions not tied to historical examination years.
  final int nonHistoricalQuestionCount;

  /// Count of questions addressing high learner weakness (observed deficiency >= 0.6).
  final int highWeaknessCount;

  /// Count of questions addressing moderate learner weakness (0.2 <= deficiency < 0.6).
  final int mediumWeaknessCount;

  /// Count of questions addressing low/no learner weakness (deficiency < 0.2).
  final int lowWeaknessCount;

  PracticeSessionDistribution({
    Map<String, int>? objectiveCounts,
    Map<String, int>? topicCounts,
    Map<int, int>? yearCounts,
    Map<String, int>? difficultyCounts,
    required this.historicalQuestionCount,
    required this.historicalQuestionRatio,
    required this.recentHistoricalQuestionCount,
    required this.nonHistoricalQuestionCount,
    required this.highWeaknessCount,
    required this.mediumWeaknessCount,
    required this.lowWeaknessCount,
  })  : objectiveCounts = Map<String, int>.unmodifiable(
            objectiveCounts ?? const <String, int>{}),
        topicCounts =
            Map<String, int>.unmodifiable(topicCounts ?? const <String, int>{}),
        yearCounts =
            Map<int, int>.unmodifiable(yearCounts ?? const <int, int>{}),
        difficultyCounts = Map<String, int>.unmodifiable(
            difficultyCounts ?? const <String, int>{}) {
    if (historicalQuestionCount < 0 ||
        recentHistoricalQuestionCount < 0 ||
        nonHistoricalQuestionCount < 0 ||
        highWeaknessCount < 0 ||
        mediumWeaknessCount < 0 ||
        lowWeaknessCount < 0) {
      throw ArgumentError('Distribution counts cannot be negative');
    }
    if (historicalQuestionRatio.isNaN ||
        historicalQuestionRatio.isInfinite ||
        historicalQuestionRatio < 0.0 ||
        historicalQuestionRatio > 1.0) {
      throw ArgumentError(
          'historicalQuestionRatio must be bounded in [0.0, 1.0] (got $historicalQuestionRatio)');
    }
  }

  Map<String, dynamic> toJson() => {
        'objectiveCounts': objectiveCounts,
        'topicCounts': topicCounts,
        'yearCounts': yearCounts.map((k, v) => MapEntry(k.toString(), v)),
        'difficultyCounts': difficultyCounts,
        'historicalQuestionCount': historicalQuestionCount,
        'historicalQuestionRatio': historicalQuestionRatio,
        'recentHistoricalQuestionCount': recentHistoricalQuestionCount,
        'nonHistoricalQuestionCount': nonHistoricalQuestionCount,
        'highWeaknessCount': highWeaknessCount,
        'mediumWeaknessCount': mediumWeaknessCount,
        'lowWeaknessCount': lowWeaknessCount,
      };

  factory PracticeSessionDistribution.fromJson(Map<String, dynamic> json) =>
      PracticeSessionDistribution(
        objectiveCounts:
            (json['objectiveCounts'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as int)),
        topicCounts: (json['topicCounts'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as int)),
        yearCounts: (json['yearCounts'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        difficultyCounts:
            (json['difficultyCounts'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as int)),
        historicalQuestionCount: json['historicalQuestionCount'] as int? ?? 0,
        historicalQuestionRatio:
            (json['historicalQuestionRatio'] as num?)?.toDouble() ?? 0.0,
        recentHistoricalQuestionCount:
            json['recentHistoricalQuestionCount'] as int? ?? 0,
        nonHistoricalQuestionCount:
            json['nonHistoricalQuestionCount'] as int? ?? 0,
        highWeaknessCount: json['highWeaknessCount'] as int? ?? 0,
        mediumWeaknessCount: json['mediumWeaknessCount'] as int? ?? 0,
        lowWeaknessCount: json['lowWeaknessCount'] as int? ?? 0,
      );

  @override
  String toString() =>
      'PracticeSessionDistribution(pyq: $historicalQuestionCount (${(historicalQuestionRatio * 100).toStringAsFixed(1)}%), weak: H:$highWeaknessCount M:$mediumWeaknessCount L:$lowWeaknessCount)';
}

/// Comprehensive, evidence-ready specification of an orchestrated practice session.
@immutable
class AdaptivePracticeSessionSpec {
  /// Deterministic SHA-256 fingerprint identifying this exact session composition.
  final String sessionId;

  /// Target examination identifier.
  final String examId;

  /// Associated learner identifier, if provided.
  final String? learnerId;

  /// Orchestration mode.
  final PracticeSessionMode sessionMode;

  /// Completion requirements policy.
  final PracticeCompletionPolicy completionPolicy;

  /// Deterministically ordered sequence of questions for presentation.
  final List<NormalizedQuestion> orderedQuestions;

  /// Deterministically ordered sequence of question IDs.
  final List<String> orderedQuestionIds;

  /// Candidate audit metadata for the ordered questions.
  final List<AdaptiveQuestionCandidate> orderedCandidates;

  /// Ordered sequence of pedagogical sections composing the session.
  final List<PracticeSessionSection> sections;

  /// Multi-dimensional distribution summary.
  final PracticeSessionDistribution distribution;

  /// Total estimated session workload in seconds.
  final int totalEstimatedSeconds;

  /// Whether session question count was constrained by pool availability or diversity limits.
  final bool isConstraintLimited;

  /// Diagnostic reason when [isConstraintLimited] is true.
  final String? constraintLimitReason;

  /// Configuration driving this orchestration.
  final AdaptivePracticeSessionConfig config;

  /// Upstream selection audit result from P33.
  final AdaptiveQuestionSelectionResult selectionAudit;

  /// Caller-supplied timestamp when orchestration was performed.
  final DateTime? orchestratedAt;

  AdaptivePracticeSessionSpec({
    required String sessionId,
    required String examId,
    this.learnerId,
    required this.sessionMode,
    required this.completionPolicy,
    required List<NormalizedQuestion> orderedQuestions,
    required List<AdaptiveQuestionCandidate> orderedCandidates,
    required List<PracticeSessionSection> sections,
    required this.distribution,
    required this.totalEstimatedSeconds,
    this.isConstraintLimited = false,
    this.constraintLimitReason,
    required this.config,
    required this.selectionAudit,
    this.orchestratedAt,
  })  : sessionId = sessionId.trim(),
        examId = examId.trim().toLowerCase(),
        orderedQuestions =
            List<NormalizedQuestion>.unmodifiable(orderedQuestions),
        orderedQuestionIds = List<String>.unmodifiable(
            orderedQuestions.map((q) => q.id).toList()),
        orderedCandidates =
            List<AdaptiveQuestionCandidate>.unmodifiable(orderedCandidates),
        sections = List<PracticeSessionSection>.unmodifiable(sections) {
    if (this.sessionId.isEmpty) {
      throw ArgumentError(
          'sessionId cannot be empty for AdaptivePracticeSessionSpec');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for AdaptivePracticeSessionSpec');
    }
    if (totalEstimatedSeconds < 0) {
      throw ArgumentError(
          'totalEstimatedSeconds cannot be negative ($totalEstimatedSeconds)');
    }
  }

  /// Total question count in this orchestrated session.
  int get totalQuestions => orderedQuestions.length;

  /// Total section count in this orchestrated session.
  int get totalSections => sections.length;

  /// Adapts this orchestration specification into a standard P19 [LearningSession]
  /// for persistence and attempt recording by P19 services without mutating P19 models.
  LearningSession toLearningSession({
    String? targetLearnerId,
    DateTime? startedAt,
  }) {
    final effectiveLearnerId =
        targetLearnerId ?? learnerId ?? 'learner_anonymous';
    final targetObjectiveIds = distribution.objectiveCounts.keys.toList();
    final effectiveObjectiveIds = targetObjectiveIds.isNotEmpty
        ? targetObjectiveIds
        : const ['lo_general'];

    return LearningSession(
      sessionId: sessionId,
      learnerId: effectiveLearnerId,
      configuration: SessionConfiguration(
        learnerId: effectiveLearnerId,
        objectiveIds: effectiveObjectiveIds,
        questionLimit: totalQuestions > 0 ? totalQuestions : 10,
      ),
      orderedQuestionIds: orderedQuestionIds,
      currentQuestionIndex: 0,
      state: LearningSessionState.created,
      startedAt: startedAt,
    );
  }

  /// Factory for safe empty session specification.
  factory AdaptivePracticeSessionSpec.empty({
    required String sessionId,
    required String examId,
    required AdaptivePracticeSessionConfig config,
    required AdaptiveQuestionSelectionResult selectionAudit,
    DateTime? orchestratedAt,
    String? reason,
  }) =>
      AdaptivePracticeSessionSpec(
        sessionId: sessionId,
        examId: examId,
        learnerId: config.learnerId,
        sessionMode: config.sessionMode,
        completionPolicy: config.completionPolicy,
        orderedQuestions: const [],
        orderedCandidates: const [],
        sections: const [],
        distribution: PracticeSessionDistribution(
          historicalQuestionCount: 0,
          historicalQuestionRatio: 0.0,
          recentHistoricalQuestionCount: 0,
          nonHistoricalQuestionCount: 0,
          highWeaknessCount: 0,
          mediumWeaknessCount: 0,
          lowWeaknessCount: 0,
        ),
        totalEstimatedSeconds: 0,
        isConstraintLimited: true,
        constraintLimitReason: reason ?? 'No questions available for session',
        config: config,
        selectionAudit: selectionAudit,
        orchestratedAt: orchestratedAt,
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'examId': examId,
        if (learnerId != null) 'learnerId': learnerId,
        'sessionMode': sessionMode.name,
        'completionPolicy': completionPolicy.name,
        'totalQuestions': totalQuestions,
        'totalSections': totalSections,
        'totalEstimatedSeconds': totalEstimatedSeconds,
        'isConstraintLimited': isConstraintLimited,
        if (constraintLimitReason != null)
          'constraintLimitReason': constraintLimitReason,
        if (orchestratedAt != null)
          'orchestratedAt': orchestratedAt!.toIso8601String(),
        'config': config.toJson(),
        'distribution': distribution.toJson(),
        'orderedQuestionIds': orderedQuestionIds,
        'orderedQuestions': orderedQuestions.map((q) => q.toJson()).toList(),
        'orderedCandidates': orderedCandidates.map((c) => c.toJson()).toList(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'selectionAudit': selectionAudit.toJson(),
      };

  factory AdaptivePracticeSessionSpec.fromJson(Map<String, dynamic> json) =>
      AdaptivePracticeSessionSpec(
        sessionId: json['sessionId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        learnerId: json['learnerId'] as String?,
        sessionMode: PracticeSessionMode.values.firstWhere(
          (m) => m.name == json['sessionMode'],
          orElse: () => PracticeSessionMode.standard,
        ),
        completionPolicy: PracticeCompletionPolicy.values.firstWhere(
          (c) => c.name == json['completionPolicy'],
          orElse: () => PracticeCompletionPolicy.allRequired,
        ),
        orderedQuestions: (json['orderedQuestions'] as List<dynamic>? ??
                const [])
            .map((q) => NormalizedQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        orderedCandidates: (json['orderedCandidates'] as List<dynamic>? ??
                const [])
            .map((c) =>
                AdaptiveQuestionCandidate.fromJson(c as Map<String, dynamic>))
            .toList(),
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((s) =>
                PracticeSessionSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        distribution: json['distribution'] != null
            ? PracticeSessionDistribution.fromJson(
                json['distribution'] as Map<String, dynamic>)
            : PracticeSessionDistribution(
                historicalQuestionCount: 0,
                historicalQuestionRatio: 0.0,
                recentHistoricalQuestionCount: 0,
                nonHistoricalQuestionCount: 0,
                highWeaknessCount: 0,
                mediumWeaknessCount: 0,
                lowWeaknessCount: 0,
              ),
        totalEstimatedSeconds: json['totalEstimatedSeconds'] as int? ?? 0,
        isConstraintLimited: json['isConstraintLimited'] as bool? ?? false,
        constraintLimitReason: json['constraintLimitReason'] as String?,
        config: json['config'] != null
            ? AdaptivePracticeSessionConfig.fromJson(
                json['config'] as Map<String, dynamic>)
            : AdaptivePracticeSessionConfig(examId: 'upsc'),
        selectionAudit: json['selectionAudit'] != null
            ? AdaptiveQuestionSelectionResult(
                examId: json['examId'] as String? ?? '',
                selectedQuestions: const [],
                selectedCandidates: const [],
                allCandidates: const [],
                requestedCount: 0,
                eligibleCount: 0,
                config: AdaptiveQuestionSelectionConfig(examId: 'upsc'),
              )
            : AdaptiveQuestionSelectionResult.empty(
                examId: json['examId'] as String? ?? '',
                config: AdaptiveQuestionSelectionConfig(examId: 'upsc'),
              ),
        orchestratedAt: json['orchestratedAt'] != null
            ? DateTime.parse(json['orchestratedAt'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'AdaptivePracticeSessionSpec($sessionId [$examId]: $totalQuestions questions across $totalSections sections, est: ${totalEstimatedSeconds}s)';
}
