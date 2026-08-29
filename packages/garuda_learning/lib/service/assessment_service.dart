/// Assessment Service (TITAN-KO-018.0 P18).
///
/// Central application orchestrator for question attempt submission, validation,
/// deterministic answer evaluation, result persistence, and progress tracking.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show LegalQuestion, QuestionKnowledgeProductService;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/question_attempt.dart';
import '../evaluation/answer_evaluator.dart';
import '../evaluation/manual_evaluator.dart';
import '../evaluation/multiple_choice_evaluator.dart';
import '../evaluation/short_answer_evaluator.dart';
import '../evaluation/true_false_evaluator.dart';
import '../provider/question_provider.dart';
import '../repository/attempt_repository.dart';
import '../repository/learner_repository.dart';
import 'curriculum_service.dart';
import 'progress_tracker.dart';
import 'session_manager.dart';

class AssessmentService {
  final LearnerRepository _learnerRepository;
  final AttemptRepository _attemptRepository;
  final CurriculumService _curriculumService;
  final QuestionProvider _questionProvider;
  final QuestionKnowledgeProductService? _legacyQuestionService;
  final ProgressTracker _progressTracker;
  final SessionManager? _sessionManager;

  final Map<EvaluationMethod, AnswerEvaluator> _evaluators;
  static int _attemptCounter = 0;

  AssessmentService({
    required LearnerRepository learnerRepository,
    required AttemptRepository attemptRepository,
    required CurriculumService curriculumService,
    QuestionProvider? questionProvider,
    QuestionKnowledgeProductService? questionService,
    required ProgressTracker progressTracker,
    SessionManager? sessionManager,
    Map<EvaluationMethod, AnswerEvaluator>? customEvaluators,
  })  : _learnerRepository = learnerRepository,
        _attemptRepository = attemptRepository,
        _curriculumService = curriculumService,
        _questionProvider = questionProvider ??
            CaseLawQuestionProvider(
              questionService:
                  questionService ?? QuestionKnowledgeProductService(),
            ),
        _legacyQuestionService = questionService,
        _progressTracker = progressTracker,
        _sessionManager = sessionManager,
        _evaluators = customEvaluators ??
            const {
              EvaluationMethod.multipleChoice: MultipleChoiceEvaluator(),
              EvaluationMethod.trueFalse: TrueFalseEvaluator(),
              EvaluationMethod.shortAnswerKeyword: ShortAnswerEvaluator(),
              EvaluationMethod.manual: ManualEvaluator(),
            };

  /// Submits and evaluates a question attempt.
  ///
  /// Rejects non-existent learners, questions, objectives, or invalid references.
  AttemptResult submitAttempt({
    required String learnerId,
    required String questionId,
    required String objectiveId,
    required String submittedAnswer,
    String? attemptId,
    String? sessionId,
    EvaluationMethod? evaluationMethod,
  }) {
    // 1. Validate Learner
    if (!_learnerRepository.exists(learnerId)) {
      throw ArgumentError('Learner "$learnerId" does not exist in repository');
    }

    // 2. Validate Objective
    final objective = _curriculumService.getObjectiveById(objectiveId);
    if (objective == null) {
      throw ArgumentError(
          'Learning objective "$objectiveId" does not exist in curriculum framework');
    }

    // 3. Validate Question
    final question = _resolveQuestion(questionId);
    if (question == null) {
      throw ArgumentError(
          'P15 question "$questionId" does not exist in question knowledge products');
    }

    // 4. Create QuestionAttempt
    final id = attemptId ??
        'att_${learnerId}_${questionId}_${DateTime.now().toUtc().microsecondsSinceEpoch}_${_attemptCounter++}';

    final attempt = QuestionAttempt(
      attemptId: id,
      learnerId: learnerId,
      questionId: questionId,
      objectiveId: objectiveId,
      submittedAnswer: submittedAnswer,
      attemptedAt: DateTime.now().toUtc(),
      sessionId: sessionId,
    );

    // Persist attempt
    _attemptRepository.saveAttempt(attempt);

    // 5. Select Evaluator & Evaluate Answer
    final method = evaluationMethod ?? _inferEvaluationMethod(question);
    final evaluator = _evaluators[method] ?? const MultipleChoiceEvaluator();

    final result = evaluator.evaluate(
      attempt: attempt,
      question: question,
    );

    // Persist evaluation result
    _attemptRepository.saveResult(result);

    // 6. Update Session if active
    final mgr = _sessionManager;
    if (sessionId != null && mgr != null) {
      mgr.addAttemptToSession(
        sessionId: sessionId,
        attempt: attempt,
      );
    }

    // 7. Update Progress
    _progressTracker.updateProgress(
      learnerId: learnerId,
      objectiveId: objectiveId,
    );

    return result;
  }

  /// Resolves a question across available question providers and legacy products.
  LegalQuestion? _resolveQuestion(String questionId) {
    final q = _questionProvider.getQuestionById(questionId);
    if (q is LegalQuestion) return q as LegalQuestion;

    if (_legacyQuestionService != null) {
      final allProducts = _legacyQuestionService!.buildAll();
      for (final product in allProducts) {
        for (final item in product.questions) {
          if (item.questionId == questionId) return item;
        }
      }
    }
    return null;
  }

  /// Infers evaluation method from question type if not explicitly supplied.
  static EvaluationMethod _inferEvaluationMethod(LegalQuestion question) {
    final text = question.questionText.toLowerCase();
    final ans = question.answer.answerText.toLowerCase();

    if (ans == 'true' || ans == 'false' || text.contains('true or false')) {
      return EvaluationMethod.trueFalse;
    }
    if (text.contains('essay') || text.contains('analyze in detail')) {
      return EvaluationMethod.manual;
    }
    if (question.answer.principles.isNotEmpty) {
      return EvaluationMethod.shortAnswerKeyword;
    }
    return EvaluationMethod.multipleChoice;
  }
}
