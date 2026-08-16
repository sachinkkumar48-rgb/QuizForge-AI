/// Adaptive Recommendation Service (TITAN-KO-021.0 P21).
///
/// Deterministic, offline-first application service implementing multi-factor priority
/// scoring, cold-start safety guards, turn-key session synthesis, and evidence-grounded
/// next-learning-action recommendations.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show
        KnowledgeProductType,
        QuestionKnowledgeProduct,
        QuestionKnowledgeProductService;

import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/question_selection_policy.dart';
import '../domain/entities/question_sequencer_policy.dart';
import '../domain/entities/recommendation_policy.dart';
import '../domain/entities/recommendation_queue.dart';
import '../domain/entities/recommendation_type.dart';
import '../domain/entities/session_configuration.dart';
import '../repository/attempt_repository.dart';
import '../repository/in_memory_recommendation_repository.dart';
import '../repository/progress_repository.dart';
import '../repository/recommendation_repository.dart';
import 'curriculum_service.dart';
import 'recommendation_engine.dart';
import 'spaced_repetition_service.dart';

class AdaptiveRecommendationService implements RecommendationEngine {
  final CurriculumService _curriculumService;
  final ProgressRepository _progressRepository;
  final AttemptRepository _attemptRepository;
  final SpacedRepetitionService _spacedRepetitionService;
  final QuestionKnowledgeProductService _questionService;
  final RecommendationRepository _recommendationRepository;

  List<QuestionKnowledgeProduct>? _cachedQuestionProducts;

  AdaptiveRecommendationService({
    required CurriculumService curriculumService,
    required ProgressRepository progressRepository,
    required AttemptRepository attemptRepository,
    required SpacedRepetitionService spacedRepetitionService,
    QuestionKnowledgeProductService? questionService,
    RecommendationRepository? recommendationRepository,
  })  : _curriculumService = curriculumService,
        _progressRepository = progressRepository,
        _attemptRepository = attemptRepository,
        _spacedRepetitionService = spacedRepetitionService,
        _questionService = questionService ?? QuestionKnowledgeProductService(),
        _recommendationRepository =
            recommendationRepository ?? InMemoryRecommendationRepository();

  List<QuestionKnowledgeProduct> get _allQuestionProducts =>
      _cachedQuestionProducts ??= _questionService.buildAll();

  @override
  Future<RecommendationQueue> generateRecommendations({
    required String learnerId,
    RecommendationPolicy policy = const RecommendationPolicy(),
    DateTime? asOfDate,
  }) async {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }

    final effectiveAsOf = (asOfDate ?? DateTime.now()).toUtc();

    // 1. Gather candidate objectives from curriculum based on policy filters
    List<LearningObjective> candidateObjectives;
    if (policy.targetUnitId != null) {
      final unit = _curriculumService.getUnitById(policy.targetUnitId!);
      candidateObjectives = unit?.objectives ?? const [];
    } else if (policy.targetDomainId != null) {
      final domain = _curriculumService.getDomainById(policy.targetDomainId!);
      candidateObjectives =
          domain?.units.expand((u) => u.objectives).toList() ?? const [];
    } else {
      candidateObjectives = _curriculumService.framework.allObjectives;
    }

    if (candidateObjectives.isEmpty) {
      final emptyQueue = RecommendationQueue(
        learnerId: learnerId,
        items: const [],
        generatedAt: effectiveAsOf,
        policyUsed: policy,
      );
      await _recommendationRepository.saveQueue(emptyQueue);
      return emptyQueue;
    }

    // 2. Evaluate all candidate objectives
    final evaluatedItems = <LearningRecommendation>[];
    for (final obj in candidateObjectives) {
      final rec = await evaluateObjective(
        learnerId: learnerId,
        objectiveId: obj.id,
        policy: policy,
        asOfDate: effectiveAsOf,
      );
      if (rec != null) {
        evaluatedItems.add(rec);
      }
    }

    // 3. Sort deterministically by priorityScore descending, with objectiveId tie-breaker
    evaluatedItems.sort((a, b) {
      final scoreCmp = b.priorityScore.compareTo(a.priorityScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.objectiveId.compareTo(b.objectiveId);
    });

    // 4. Apply maximum recommendations limit
    final truncatedItems = evaluatedItems.length > policy.maxRecommendations
        ? evaluatedItems.sublist(0, policy.maxRecommendations)
        : evaluatedItems;

    final queue = RecommendationQueue(
      learnerId: learnerId,
      items: truncatedItems,
      generatedAt: effectiveAsOf,
      policyUsed: policy,
    );

    await _recommendationRepository.saveQueue(queue);
    return queue;
  }

  @override
  Future<LearningRecommendation?> evaluateObjective({
    required String learnerId,
    required String objectiveId,
    RecommendationPolicy policy = const RecommendationPolicy(),
    DateTime? asOfDate,
  }) async {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('objectiveId cannot be empty');
    }

    final objective = _curriculumService.getObjectiveById(objectiveId);
    if (objective == null) return null;

    final effectiveAsOf = (asOfDate ?? DateTime.now()).toUtc();
    final progress = _progressRepository.getProgress(learnerId, objectiveId);
    final isAchieved = progress?.status == LearnerObjectiveStatus.achieved;

    // --- Factor 1: Spaced Repetition Urgency U_review ---
    final schedule = await _spacedRepetitionService.getSchedule(learnerId);
    final reviewItem = schedule?.getItem(objectiveId);

    double uReview = 0.0;
    double overdueHours = 0.0;
    if (reviewItem != null && reviewItem.isDue(asOfDate: effectiveAsOf)) {
      final overdueMinutes =
          effectiveAsOf.difference(reviewItem.nextReviewDate).inMinutes;
      overdueHours = overdueMinutes > 0 ? overdueMinutes / 60.0 : 0.0;
      final overdueDays = overdueHours / 24.0;
      uReview = (overdueDays / 7.0).clamp(0.0, 1.0);
      // Ensure minimum non-zero urgency if due today
      if (uReview == 0.0 && reviewItem.isDue(asOfDate: effectiveAsOf)) {
        uReview = 0.10;
      }
    }

    // --- Factor 2: Prerequisite Blocker Severity S_prereq ---
    double sPrereq = 0.0;
    int blockedDownstreamCount = 0;
    if (!isAchieved) {
      final allObjectives = _curriculumService.framework.allObjectives;
      for (final other in allObjectives) {
        if (other.id == objectiveId) continue;
        final otherProg = _progressRepository.getProgress(learnerId, other.id);
        if (otherProg?.status != LearnerObjectiveStatus.achieved) {
          final isPrereq = other.prerequisites.any(
            (p) => p.prerequisiteObjectiveId == objectiveId,
          );
          if (isPrereq) {
            blockedDownstreamCount++;
          }
        }
      }
      if (blockedDownstreamCount > 0) {
        sPrereq = (blockedDownstreamCount / 5.0).clamp(0.0, 1.0);
      }
    }

    // --- Factor 3: Weak Domain Accuracy Gap G_weak (With Cold-Start Guard) ---
    double gWeak = 0.0;
    int domainAttemptCount = 0;
    double domainAccuracy = 0.0;

    final unit = _curriculumService.getUnitById(objective.unitId);
    final domainId = unit?.domainId;
    final domain =
        domainId != null ? _curriculumService.getDomainById(domainId) : null;

    if (domain != null) {
      final domainObjectiveIds =
          domain.units.expand((u) => u.objectives).map((o) => o.id).toSet();
      final learnerAttempts =
          _attemptRepository.getAttemptsForLearner(learnerId);
      final domainAttempts = learnerAttempts
          .where((a) => domainObjectiveIds.contains(a.objectiveId))
          .toList();

      domainAttemptCount = domainAttempts.length;

      // Cold-Start Guard: strictly 0.0 if domain attempt count is below minimum
      if (domainAttemptCount >= policy.minDomainAttempts) {
        var correctCount = 0;
        for (final att in domainAttempts) {
          final res = _attemptRepository.getResultForAttempt(att.attemptId);
          if (res?.isCorrect == true) correctCount++;
        }
        domainAccuracy = correctCount / domainAttemptCount;

        if (domainAccuracy < policy.weakDomainThreshold) {
          gWeak = ((policy.weakDomainThreshold - domainAccuracy) /
                  policy.weakDomainThreshold)
              .clamp(0.0, 1.0);
        }
      }
    }

    // --- Factor 4: Curriculum Advancement Factor P_curric (Strictly Clamped) ---
    double pCurric = 0.0;
    if (!isAchieved) {
      var allPrereqsAchieved = true;
      for (final prereq in objective.prerequisites) {
        final pProg = _progressRepository.getProgress(
            learnerId, prereq.prerequisiteObjectiveId);
        if (pProg?.status != LearnerObjectiveStatus.achieved) {
          allPrereqsAchieved = false;
          break;
        }
      }

      if (allPrereqsAchieved) {
        final closure = _curriculumService.getPrerequisiteClosure(objectiveId);
        final topologicalLevel = closure.length;
        pCurric = (1.0 - (0.05 * topologicalLevel)).clamp(0.0, 1.0);
      }
    }

    // --- Factor 5: Practice Question Density H_density ---
    var mappedQuestionCount = 0;
    for (final mapping in objective.supportedProducts) {
      if (mapping.productType == KnowledgeProductType.question) {
        mappedQuestionCount++;
      }
    }

    // Check P15 questions mapped through supported case/doctrine/statute products
    final allProducts = _allQuestionProducts;
    final supportedProductIds =
        objective.supportedProducts.map((p) => p.productId).toSet();
    for (final prod in allProducts) {
      if (supportedProductIds.contains(prod.productId)) {
        mappedQuestionCount += prod.questions.length;
      }
    }

    final hDensity = (mappedQuestionCount / 10.0).clamp(0.0, 1.0);

    // --- Composite Score Formulation ---
    final cReview = policy.weightSpacedReview * uReview;
    final cPrereq = policy.weightPrerequisiteGap * sPrereq;
    final cWeak = policy.weightWeakDomain * gWeak;
    final cCurric = policy.weightCurriculumAdvance * pCurric;
    final cDensity = policy.weightPracticeDensity * hDensity;

    final rawScore = cReview + cPrereq + cWeak + cCurric + cDensity;
    final priorityScore = rawScore.clamp(0.0, 1.0);

    // --- Determine Dominant Recommendation Strategy ---
    final contributions = [
      (RecommendationType.spacedReview, cReview),
      (RecommendationType.prerequisiteGap, cPrereq),
      (RecommendationType.weakDomainRemediation, cWeak),
      (RecommendationType.curriculumAdvance, cCurric),
      (RecommendationType.practiceDensity, cDensity),
    ];
    contributions.sort((a, b) => b.$2.compareTo(a.$2));

    RecommendationType strategyType;
    if (contributions.first.$2 > 0.0) {
      strategyType = contributions.first.$1;
    } else {
      strategyType = isAchieved
          ? RecommendationType.practiceDensity
          : RecommendationType.curriculumAdvance;
    }

    // --- Build Evidence-Grounded Rationale String ---
    final String rationale = switch (strategyType) {
      RecommendationType.spacedReview =>
        'Scheduled review is overdue by ${overdueHours.toStringAsFixed(1)} hours based on SM-2 recall history.',
      RecommendationType.prerequisiteGap =>
        'Unachieved prerequisite objective blocking $blockedDownstreamCount downstream learning objective${blockedDownstreamCount == 1 ? '' : 's'} in curriculum.',
      RecommendationType.weakDomainRemediation =>
        'Domain accuracy is ${(domainAccuracy * 100).toStringAsFixed(1)}% across $domainAttemptCount attempts (below ${(policy.weakDomainThreshold * 100).toStringAsFixed(1)}% target threshold).',
      RecommendationType.curriculumAdvance =>
        'Next sequential curriculum objective with all prerequisite requirements satisfied.',
      RecommendationType.practiceDensity =>
        'Objective has $mappedQuestionCount validated practice question${mappedQuestionCount == 1 ? '' : 's'} available for active retrieval practice.',
    };

    // --- Turn-Key P19 SessionConfiguration Synthesis ---
    final QuestionSelectionPolicy selectionPolicy;
    final QuestionSequencerPolicy sequencerPolicy;

    switch (strategyType) {
      case RecommendationType.spacedReview:
        selectionPolicy = QuestionSelectionPolicy.balanced;
        sequencerPolicy = QuestionSequencerPolicy.difficultyAscending;
        break;
      case RecommendationType.prerequisiteGap:
        selectionPolicy = QuestionSelectionPolicy.allObjectiveQuestions;
        sequencerPolicy = QuestionSequencerPolicy.curriculumOrder;
        break;
      case RecommendationType.weakDomainRemediation:
        selectionPolicy = QuestionSelectionPolicy.incorrectFocus;
        sequencerPolicy = QuestionSequencerPolicy.difficultyAscending;
        break;
      case RecommendationType.curriculumAdvance:
        selectionPolicy = QuestionSelectionPolicy.unattemptedOnly;
        sequencerPolicy = QuestionSequencerPolicy.curriculumOrder;
        break;
      case RecommendationType.practiceDensity:
        selectionPolicy = QuestionSelectionPolicy.allObjectiveQuestions;
        sequencerPolicy = QuestionSequencerPolicy.sequential;
        break;
    }

    final suggestedConfig = SessionConfiguration(
      learnerId: learnerId,
      objectiveIds: [objectiveId],
      questionLimit: 10,
      selectionPolicy: selectionPolicy,
      sequencerPolicy: sequencerPolicy,
      allowRepeatAttempts: true,
    );

    final recommendationId =
        'rec_${learnerId}_${objectiveId}_${effectiveAsOf.millisecondsSinceEpoch}';

    return LearningRecommendation(
      recommendationId: recommendationId,
      learnerId: learnerId,
      objectiveId: objectiveId,
      type: strategyType,
      priorityScore: priorityScore,
      rationale: rationale,
      suggestedConfig: suggestedConfig,
      generatedAt: effectiveAsOf,
      metadata: {
        'uReview': uReview,
        'sPrereq': sPrereq,
        'gWeak': gWeak,
        'pCurric': pCurric,
        'hDensity': hDensity,
        'overdueHours': overdueHours,
        'blockedCount': blockedDownstreamCount,
        'domainAttempts': domainAttemptCount,
        'domainAccuracy': domainAccuracy,
        'mappedQuestions': mappedQuestionCount,
      },
    );
  }
}
