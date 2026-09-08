import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:titan_core/titan_core.dart';

import '../services/adaptive_learning_runtime_coordinator.dart';
import '../services/pyq_corpus_adapter_service.dart';

/// Production-grade Adaptive Practice Page for QuizForge AI.
///
/// Executes the complete step-by-step adaptive learning loop:
/// question presentation -> answer submission -> outcome consolidation ->
/// state reconciliation -> authoritative persistence -> durable checkpoints -> resumption.
class AdaptivePracticePage extends StatefulWidget {
  final AdaptiveLearningJourneyController? controller;
  final String? targetTopic;
  final String examId;
  final String? learnerId;
  final List<NormalizedQuestion>? corpus;
  final int questionCount;
  final bool isResumeMode;
  final String? resumeSessionId;
  final bool isDiagnosticMode;
  final String? targetObjectiveId;

  const AdaptivePracticePage({
    super.key,
    this.controller,
    this.targetTopic,
    this.examId = 'upsc_prelims_gs1',
    this.learnerId,
    this.corpus,
    this.questionCount = 5,
    this.isResumeMode = false,
    this.resumeSessionId,
    this.isDiagnosticMode = false,
    this.targetObjectiveId,
  });

  @override
  State<AdaptivePracticePage> createState() => _AdaptivePracticePageState();
}

class _AdaptivePracticePageState extends State<AdaptivePracticePage> {
  late final AdaptiveLearningJourneyController _controller;
  bool _ownsController = false;

  String? _selectedOptionKey;
  bool _isSubmitting = false;
  PracticeQuestionResult? _feedbackResult;
  DiagnosticPlacementResult? _diagnosticResult;

  bool get _isDiagnostic =>
      widget.isDiagnosticMode ||
      (widget.targetTopic?.toLowerCase().contains('diagnostic') ?? false);

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      final orchestrator = _resolveOrchestrator();
      _controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
    }

    _controller.addListener(_onControllerChanged);
    _initializeSession();
  }

  AdaptiveLearningJourneyOrchestrator _resolveOrchestrator() {
    try {
      if (TitanServiceLocator.instance
          .isRegistered<AdaptiveLearningJourneyOrchestrator>()) {
        return TitanServiceLocator.instance
            .get<AdaptiveLearningJourneyOrchestrator>();
      }
    } catch (_) {}

    final authRepo = TitanServiceLocator.instance
            .isRegistered<AuthoritativeLearningStateRepository>()
        ? TitanServiceLocator.instance
            .get<AuthoritativeLearningStateRepository>()
        : InMemoryAuthoritativeLearningStateRepository();

    final authRecovery = TitanServiceLocator.instance
            .isRegistered<AuthoritativeLearningStateRecoveryService>()
        ? TitanServiceLocator.instance
            .get<AuthoritativeLearningStateRecoveryService>()
        : AuthoritativeLearningStateRecoveryService(repository: authRepo);

    final checkpointRepo =
        TitanServiceLocator.instance.isRegistered<SessionCheckpointRepository>()
            ? TitanServiceLocator.instance.get<SessionCheckpointRepository>()
            : InMemorySessionCheckpointRepository();

    final sessionRecovery = TitanServiceLocator.instance
            .isRegistered<LearningSessionRecoveryService>()
        ? TitanServiceLocator.instance.get<LearningSessionRecoveryService>()
        : LearningSessionRecoveryService(
            checkpointRepository: checkpointRepo,
            authoritativeRecoveryService: authRecovery,
          );

    final diagService =
        TitanServiceLocator.instance.isRegistered<DiagnosticAssessmentService>()
            ? TitanServiceLocator.instance.get<DiagnosticAssessmentService>()
            : null;

    return AdaptiveLearningJourneyOrchestrator(
      authRepository: authRepo,
      authRecoveryService: authRecovery,
      checkpointRepository: checkpointRepo,
      sessionRecoveryService: sessionRecovery,
      diagnosticService: diagService,
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeSession() async {
    final effectiveLearner = widget.learnerId ?? _resolveLearnerId();

    try {
      if (TitanServiceLocator.instance.isRegistered<LearnerRepository>()) {
        final lRepo = TitanServiceLocator.instance.get<LearnerRepository>();
        if (!lRepo.exists(effectiveLearner)) {
          lRepo.save(Learner(
            id: effectiveLearner,
            name: 'Learner $effectiveLearner',
            createdAt: DateTime.utc(2026, 8, 29),
          ));
        }
      }
    } catch (_) {}

    List<NormalizedQuestion> effectiveCorpus;

    if (widget.corpus != null) {
      effectiveCorpus = widget.corpus!;
    } else {
      try {
        final adapter =
            TitanServiceLocator.instance.isRegistered<PyqCorpusAdapterService>()
                ? TitanServiceLocator.instance.get<PyqCorpusAdapterService>()
                : PyqCorpusAdapterService();
        effectiveCorpus = await adapter.getCorpus(topic: widget.targetTopic);
      } catch (_) {
        effectiveCorpus = PyqCorpusAdapterService.getDefaultSeedCorpus();
      }
    }

    String? effectiveObjective = widget.targetObjectiveId ?? widget.targetTopic;
    final target = effectiveObjective;
    if (target != null &&
        !effectiveCorpus.any((q) => q.objectiveIds.contains(target))) {
      final matching = effectiveCorpus.where((q) =>
          q.topic.toLowerCase() == target.toLowerCase() ||
          q.subject.toLowerCase() == target.toLowerCase());
      if (matching.isNotEmpty && matching.first.objectiveIds.isNotEmpty) {
        effectiveObjective = matching.first.objectiveIds.first;
      } else {
        try {
          if (TitanServiceLocator.instance.isRegistered<CurriculumService>()) {
            final curService =
                TitanServiceLocator.instance.get<CurriculumService>();
            final seq = curService.getDeterministicSequence();
            if (seq.isNotEmpty) {
              effectiveObjective = seq.first.id;
            }
          }
        } catch (_) {
          effectiveObjective = null;
        }
      }
    }

    if (widget.isResumeMode && widget.resumeSessionId != null) {
      await _controller.resumeJourney(
        learnerId: effectiveLearner,
        examId: widget.examId,
        sessionId: widget.resumeSessionId!,
        corpus: effectiveCorpus,
      );
    } else {
      await _controller.startJourney(
        learnerId: effectiveLearner,
        examId: widget.examId,
        corpus: effectiveCorpus,
        targetObjectiveId: effectiveObjective,
        questionCount: widget.questionCount,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _resolveLearnerId() {
    try {
      if (TitanServiceLocator.instance
          .isRegistered<AdaptiveLearningRuntimeCoordinator>()) {
        return TitanServiceLocator.instance
            .get<AdaptiveLearningRuntimeCoordinator>()
            .activeLearnerId;
      }
    } catch (_) {}
    return 'default_learner';
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleAnswerSubmit() async {
    if (_selectedOptionKey == null ||
        _isSubmitting ||
        !_controller.canSubmitAnswer) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final currentQ = _controller.currentQuestion;
    final effectiveLearner = widget.learnerId ?? _resolveLearnerId();
    final chosenAnswer = _selectedOptionKey!;

    await _controller.submitAnswer(answer: chosenAnswer);
    final res = _controller.lastAnswerResult;

    // Record attempt into AttemptRepository so diagnostic evaluator has attempt evidence
    if (res != null && currentQ != null) {
      try {
        if (TitanServiceLocator.instance.isRegistered<AttemptRepository>()) {
          final attemptRepo =
              TitanServiceLocator.instance.get<AttemptRepository>();
          final attId =
              'att_${DateTime.now().millisecondsSinceEpoch}_${currentQ.id}';
          final objId = currentQ.objectiveIds.isNotEmpty
              ? currentQ.objectiveIds.first
              : (widget.targetObjectiveId ?? 'lo_basic_structure_doctrine');
          attemptRepo.saveAttempt(QuestionAttempt(
            attemptId: attId,
            learnerId: effectiveLearner,
            questionId: currentQ.id,
            objectiveId: objId,
            submittedAnswer: chosenAnswer,
            sessionId: _controller.session?.sessionId,
          ));
          attemptRepo.saveResult(AttemptResult(
            attemptId: attId,
            isCorrect: res.isCorrect,
            score: res.isCorrect ? 1.0 : 0.0,
            evaluationMethod: EvaluationMethod.multipleChoice,
          ));
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _feedbackResult = _controller.lastAnswerResult;
      });
    }
  }

  void _handleNextQuestion() {
    setState(() {
      _selectedOptionKey = null;
      _feedbackResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_controller.isCompleted) {
          _controller.interruptJourney(reason: 'user_navigated_away');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isDiagnostic
                ? "Diagnostic: ${widget.targetTopic ?? 'Baseline Placement'}"
                : (widget.targetTopic != null
                    ? "Adaptive Drill: ${widget.targetTopic}"
                    : "Adaptive Practice Session"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            if (_isDiagnostic)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "DIAGNOSTIC",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_controller.isCompleted && _controller.session != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Rev ${_controller.session?.authoritativeState.revision ?? 1}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.session == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Preparing Adaptive Learning Session...",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_controller.errorMessage != null && _controller.session == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 16),
              Text(
                "Unable to Start Session",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeSession,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.isCompleted) {
      return _buildCompletionSummary(context);
    }

    final currentQ = _controller.currentQuestion;
    if (currentQ == null) {
      return const Center(
        child: Text("No question available."),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(context),
          const SizedBox(height: 16),
          _buildQuestionCard(context, currentQ),
          const SizedBox(height: 16),
          if (_feedbackResult != null)
            _buildFeedbackCard(context, _feedbackResult!),
          const SizedBox(height: 24),
          _buildActionControls(context),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _controller.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${_controller.completedCount + 1} of ${_controller.totalQuestions}",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "${(progress * 100).toInt()}% Done",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, NormalizedQuestion question) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAnswered = _feedbackResult != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(question.topic),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      colorScheme.secondaryContainer.withValues(alpha: 0.5),
                ),
                Chip(
                  label: Text(question.difficulty),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _getDifficultyColor(question.difficulty)
                      .withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _getDifficultyColor(question.difficulty),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label:
                      Text("${question.examId.toUpperCase()} ${question.year}"),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.normalizedText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ...question.options.map((opt) {
              final isSelected = _selectedOptionKey == opt.key;
              final isCorrectKey =
                  question.officialAnswer.correctOptionKeys.contains(opt.key);

              Color cardBorderColor = colorScheme.outlineVariant;
              Color cardBgColor = Colors.transparent;

              if (isAnswered) {
                if (isCorrectKey) {
                  cardBorderColor = Colors.green;
                  cardBgColor = Colors.green.withValues(alpha: 0.1);
                } else if (isSelected && !isCorrectKey) {
                  cardBorderColor = Colors.red;
                  cardBgColor = Colors.red.withValues(alpha: 0.1);
                }
              } else if (isSelected) {
                cardBorderColor = colorScheme.primary;
                cardBgColor =
                    colorScheme.primaryContainer.withValues(alpha: 0.2);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: isAnswered
                      ? null
                      : () {
                          setState(() {
                            _selectedOptionKey = opt.key;
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: cardBorderColor,
                          width: isSelected || (isAnswered && isCorrectKey)
                              ? 2
                              : 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          child: Text(
                            opt.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.text,
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isAnswered && isCorrectKey)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20)
                        else if (isAnswered && isSelected && !isCorrectKey)
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
      BuildContext context, PracticeQuestionResult result) {
    final isCorrect = result.isCorrect;

    return Card(
      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isCorrect ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color:
                      isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  isCorrect ? "Correct! Well done." : "Incorrect Attempt",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
            if (result.question.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                "Explanation:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                result.question.explanation,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionControls(BuildContext context) {
    if (_feedbackResult != null) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: _handleNextQuestion,
          icon: const Icon(Icons.arrow_forward),
          label: const Text(
            "Continue to Next Question",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _selectedOptionKey == null || _isSubmitting
            ? null
            : _handleAnswerSubmit,
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "Submit Answer",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _ensureDiagnosticEvaluated() {
    if (!_isDiagnostic || _diagnosticResult != null) return;

    final effectiveLearner = widget.learnerId ?? _resolveLearnerId();
    final curriculumService =
        TitanServiceLocator.instance.isRegistered<CurriculumService>()
            ? TitanServiceLocator.instance.get<CurriculumService>()
            : null;

    final targetObjs = <String>[];
    if (curriculumService != null) {
      if (widget.targetObjectiveId != null &&
          curriculumService.getObjectiveById(widget.targetObjectiveId!) !=
              null) {
        targetObjs.add(widget.targetObjectiveId!);
      }
      final session = _controller.session;
      if (session != null) {
        for (final q in session.spec.orderedQuestions) {
          for (final oid in q.objectiveIds) {
            if (curriculumService.getObjectiveById(oid) != null &&
                !targetObjs.contains(oid)) {
              targetObjs.add(oid);
            }
          }
        }
      }
      if (targetObjs.isEmpty) {
        final seq = curriculumService.getDeterministicSequence();
        if (seq.isNotEmpty) {
          targetObjs.add(seq.first.id);
        }
      }
    }

    if (targetObjs.isNotEmpty) {
      try {
        final diagRes = _controller.executeDiagnosticPlacement(
          learnerId: effectiveLearner,
          targetObjectiveIds: targetObjs,
        );
        if (diagRes != null) {
          _diagnosticResult = diagRes;
        }
      } catch (_) {}
    }
  }

  Widget _buildDiagnosticCompletionSummary(BuildContext context) {
    final theme = Theme.of(context);
    final diag = _diagnosticResult!;
    final session = _controller.session;
    final totalQ = session?.totalQuestions ?? widget.questionCount;
    final results =
        session?.executionState.questionResults.values.toList() ?? [];
    final correctCount = results.where((r) => r.isCorrect).length;
    final accuracy = totalQ > 0 ? (correctCount / totalQ) * 100 : 0.0;
    final demonstratedCount = diag.demonstratedObjectivesCount;
    final activeFrontierCount = diag.frontier.activeFrontierObjectiveIds.length;
    final remediationCount = diag.frontier.remediationTargetObjectiveIds.length;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.assignment_turned_in,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              "Diagnostic Placement Established!",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Baseline knowledge frontier verified across ${diag.totalAssessedObjectives} curriculum objective(s)",
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                        "Demonstrated", "$demonstratedCount", Colors.green),
                    _buildMetricColumn(
                        "Frontier", "$activeFrontierCount", Colors.blue),
                    _buildMetricColumn(
                        "Remediation", "$remediationCount", Colors.orange),
                    _buildMetricColumn(
                        "Accuracy", "${accuracy.toInt()}%", Colors.deepPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.radar,
                            color: Colors.deepPurple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Baseline Knowledge Frontier",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      remediationCount > 0
                          ? "Diagnostic assessment identified conceptual vulnerabilities in $remediationCount objective(s). Your learning path has scheduled targeted remedial reinforcement before standard practice drills."
                          : "Baseline placement confirmed. Foundational competencies demonstrated. You are ready to advance to your next learning objective along the curriculum.",
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("Dashboard"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.alt_route),
                    label: const Text("View Learning Path"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSummary(BuildContext context) {
    _ensureDiagnosticEvaluated();
    if (_isDiagnostic && _diagnosticResult != null) {
      return _buildDiagnosticCompletionSummary(context);
    }

    final theme = Theme.of(context);
    final session = _controller.session;
    final totalQ = session?.totalQuestions ?? widget.questionCount;
    final results =
        session?.executionState.questionResults.values.toList() ?? [];
    final correctCount = results.where((r) => r.isCorrect).length;
    final accuracy = totalQ > 0 ? (correctCount / totalQ) * 100 : 0.0;
    final authRevision = session?.authoritativeState.revision ?? 1;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: Icon(Icons.celebration, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              "Adaptive Session Completed!",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Authoritative state updated to Revision $authRevision",
              style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn("Answered", "$totalQ", Colors.blue),
                    _buildMetricColumn(
                        "Correct", "$correctCount", Colors.green),
                    _buildMetricColumn(
                        "Accuracy", "${accuracy.toInt()}%", Colors.deepPurple),
                  ],
                ),
              ),
            ),
            if (correctCount < totalQ) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Remedial Recommendation",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Target Topic: ${widget.targetTopic ?? 'General Practice'}\nDeficiencies identified in ${totalQ - correctCount} question(s). A targeted remedial reinforcement drill is recommended.",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("Dashboard"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedOptionKey = null;
                        _feedbackResult = null;
                      });
                      _initializeSession();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Continue Learning"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
