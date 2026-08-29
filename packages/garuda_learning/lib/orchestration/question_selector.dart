/// Question Selector (TITAN-KO-019.0 P19).
///
/// Deterministic question selection engine linking P15 Questions, P17 Objectives,
/// and P18 Learner Attempts.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show LegalQuestion, QuestionKnowledgeProductService;

import '../domain/entities/question_selection_policy.dart';
import '../provider/question_provider.dart';
import '../repository/attempt_repository.dart';
import '../service/curriculum_service.dart';

class QuestionSelector {
  final QuestionProvider _questionProvider;
  final QuestionKnowledgeProductService? _questionService;
  final CurriculumService _curriculumService;
  final AttemptRepository? _attemptRepository;
  final bool _hasCustomProvider;

  QuestionSelector({
    QuestionProvider? questionProvider,
    QuestionKnowledgeProductService? questionService,
    required CurriculumService curriculumService,
    AttemptRepository? attemptRepository,
  })  : _hasCustomProvider = questionProvider != null,
        _questionProvider = questionProvider ??
            CaseLawQuestionProvider(
              questionService:
                  questionService ?? QuestionKnowledgeProductService(),
            ),
        _questionService = questionService,
        _curriculumService = curriculumService,
        _attemptRepository = attemptRepository;

  /// Selects questions mapped to the given [objectiveIds] according to [policy].
  List<LegalQuestion> selectQuestions({
    required List<String> objectiveIds,
    required String learnerId,
    QuestionSelectionPolicy policy =
        QuestionSelectionPolicy.allObjectiveQuestions,
    int? limit,
  }) {
    if (objectiveIds.isEmpty) return const [];

    // 1. Gather all candidate questions for the target objectives
    final candidateQuestions = <LegalQuestion>[];
    final seenQuestionIds = <String>{};

    if (_hasCustomProvider) {
      final fromProvider =
          _questionProvider.getQuestionsForObjectives(objectiveIds);
      for (final q in fromProvider) {
        if (q is LegalQuestion &&
            seenQuestionIds.add((q as LegalQuestion).questionId)) {
          candidateQuestions.add(q as LegalQuestion);
        }
      }
      if (candidateQuestions.isEmpty) {
        for (final q in _questionProvider.getAllQuestions()) {
          if (q is LegalQuestion &&
              seenQuestionIds.add((q as LegalQuestion).questionId)) {
            candidateQuestions.add(q as LegalQuestion);
          }
        }
      }
    } else {
      final qService = _questionService ?? QuestionKnowledgeProductService();
      final allProducts = qService.buildAll();
      final objectiveMappedProductIds = <String>{};

      for (final objId in objectiveIds) {
        final obj = _curriculumService.getObjectiveById(objId);
        if (obj != null) {
          for (final p in obj.supportedProducts) {
            objectiveMappedProductIds.add(p.productId);
          }
        }
      }

      for (final product in allProducts) {
        final isProductMapped =
            objectiveMappedProductIds.contains(product.productId);

        for (final q in product.questions) {
          if (isProductMapped || objectiveMappedProductIds.isEmpty) {
            if (seenQuestionIds.add(q.questionId)) {
              candidateQuestions.add(q);
            }
          }
        }
      }

      if (candidateQuestions.isEmpty) {
        for (final product in allProducts) {
          for (final q in product.questions) {
            if (seenQuestionIds.add(q.questionId)) {
              candidateQuestions.add(q);
            }
          }
        }
      }
    }

    // Sort candidate list deterministically by canonical questionId as initial baseline
    candidateQuestions.sort((a, b) => a.questionId.compareTo(b.questionId));

    // 2. Apply Selection Policy filtering
    List<LegalQuestion> filtered = candidateQuestions;
    final repo = _attemptRepository;

    if (repo != null && learnerId.trim().isNotEmpty) {
      final pastAttempts = repo.getAttemptsForLearner(learnerId);
      final attemptedQuestionIds =
          pastAttempts.map((a) => a.questionId).toSet();

      final incorrectAttemptQuestionIds = <String>{};
      for (final att in pastAttempts) {
        final res = repo.getResultForAttempt(att.attemptId);
        if (res != null && !res.isCorrect) {
          incorrectAttemptQuestionIds.add(att.questionId);
        }
      }

      switch (policy) {
        case QuestionSelectionPolicy.allObjectiveQuestions:
          filtered = candidateQuestions;
          break;

        case QuestionSelectionPolicy.unattemptedOnly:
          filtered = candidateQuestions
              .where((q) => !attemptedQuestionIds.contains(q.questionId))
              .toList();
          break;

        case QuestionSelectionPolicy.incorrectFocus:
          filtered = candidateQuestions
              .where((q) => incorrectAttemptQuestionIds.contains(q.questionId))
              .toList();
          // Fall back to all if no incorrect questions exist
          if (filtered.isEmpty) filtered = candidateQuestions;
          break;

        case QuestionSelectionPolicy.balanced:
          final unattempted = candidateQuestions
              .where((q) => !attemptedQuestionIds.contains(q.questionId))
              .toList();
          final incorrect = candidateQuestions
              .where((q) => incorrectAttemptQuestionIds.contains(q.questionId))
              .toList();
          final combined = <LegalQuestion>[...unattempted, ...incorrect];
          final uniqueCombined = <LegalQuestion>[];
          final added = <String>{};
          for (final q in combined) {
            if (added.add(q.questionId)) uniqueCombined.add(q);
          }
          filtered =
              uniqueCombined.isNotEmpty ? uniqueCombined : candidateQuestions;
          break;
      }
    }

    // 3. Apply limit if requested
    if (limit != null && limit > 0 && filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }

    return List.unmodifiable(filtered);
  }
}
