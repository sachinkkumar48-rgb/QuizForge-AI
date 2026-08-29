/// Diagnostic Assessment Service (TITAN-KO-026.0 P26).
///
/// Orchestrates diagnostic assessment question preparation, evidence evaluation,
/// placement calculation, and persistence.
library;

import '../domain/entities/diagnostic_assessment_request.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/question_entity.dart';
import '../provider/question_provider.dart';
import '../repository/attempt_repository.dart';
import '../repository/diagnostic_placement_repository.dart';
import '../repository/learner_repository.dart';
import 'curriculum_service.dart';
import 'deterministic_diagnostic_evaluator.dart';

class DiagnosticAssessmentService {
  final LearnerRepository _learnerRepository;
  final CurriculumService _curriculumService;
  final QuestionProvider _questionProvider;
  final AttemptRepository _attemptRepository;
  final DiagnosticPlacementRepository _diagnosticRepository;
  final DeterministicDiagnosticEvaluator _evaluator;

  DiagnosticAssessmentService({
    required LearnerRepository learnerRepository,
    required CurriculumService curriculumService,
    required QuestionProvider questionProvider,
    required AttemptRepository attemptRepository,
    required DiagnosticPlacementRepository diagnosticRepository,
    DeterministicDiagnosticEvaluator? evaluator,
  })  : _learnerRepository = learnerRepository,
        _curriculumService = curriculumService,
        _questionProvider = questionProvider,
        _attemptRepository = attemptRepository,
        _diagnosticRepository = diagnosticRepository,
        _evaluator = evaluator ??
            DeterministicDiagnosticEvaluator(
              curriculumService: curriculumService,
            );

  /// Prepares a deterministic list of diagnostic questions mapped to the [objectiveIds].
  List<IQuestionEntity> prepareDiagnosticQuestions({
    required List<String> objectiveIds,
    int questionsPerObjective = 3,
  }) {
    if (objectiveIds.isEmpty) return const [];

    final selected = <IQuestionEntity>[];
    final seenQuestionIds = <String>{};

    for (final objId in objectiveIds) {
      final candidates = _questionProvider.getQuestionsForObjectives([objId]);
      int addedForThisObj = 0;

      for (final q in candidates) {
        if (addedForThisObj >= questionsPerObjective) break;
        if (seenQuestionIds.add(q.id)) {
          selected.add(q);
          addedForThisObj++;
        }
      }
    }

    selected.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(selected);
  }

  /// Evaluates and records diagnostic placement for a learner according to [request].
  DiagnosticPlacementResult evaluatePlacement(
      DiagnosticAssessmentRequest request) {
    // 1. Verify learner exists
    if (!_learnerRepository.exists(request.learnerId)) {
      throw ArgumentError(
          'Learner "${request.learnerId}" not found in learner repository');
    }

    // 2. Validate target objectives exist in framework
    for (final objId in request.targetObjectiveIds) {
      if (_curriculumService.getObjectiveById(objId) == null) {
        throw ArgumentError(
            'Objective "$objId" is not defined in curriculum framework');
      }
    }

    // 3. Evaluate placement deterministically
    final result = _evaluator.evaluate(
      request: request,
      attemptRepository: _attemptRepository,
    );

    // 4. Persist result
    _diagnosticRepository.saveResult(result);

    return result;
  }

  /// Retrieves the latest placement result for a learner.
  DiagnosticPlacementResult? getLatestPlacement(String learnerId) {
    return _diagnosticRepository.getLatestResultForLearner(learnerId);
  }
}
