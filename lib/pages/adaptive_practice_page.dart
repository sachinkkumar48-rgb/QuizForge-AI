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

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      final orchestrator = _resolveOrchestrator();
      _controller = AdaptiveLearningJourneyController(orchestrator: orchestrator);
    }

    _controller.addListener(_onControllerChanged);
    _initializeSession();
  }

  AdaptiveLearningJourneyOrchestrator _resolveOrchestrator() {
    try {
      if (TitanServiceLocator.instance.isRegistered<AdaptiveLearningJourneyOrchestrator>()) {
        return TitanServiceLocator.instance.get<AdaptiveLearningJourneyOrchestrator>();
      }
    } catch (_) {}

    final authRepo = TitanServiceLocator.instance.isRegistered<AuthoritativeLearningStateRepository>()
        ? TitanServiceLocator.instance.get<AuthoritativeLearningStateRepository>()
        : InMemoryAuthoritativeLearningStateRepository();

    final authRecovery = TitanServiceLocator.instance.isRegistered<AuthoritativeLearningStateRecoveryService>()
        ? TitanServiceLocator.instance.get<AuthoritativeLearningStateRecoveryService>()
        : AuthoritativeLearningStateRecoveryService(repository: authRepo);

    final checkpointRepo = TitanServiceLocator.instance.isRegistered<SessionCheckpointRepository>()
        ? TitanServiceLocator.instance.get<SessionCheckpointRepository>()
        : InMemorySessionCheckpointRepository();

    final sessionRecovery = TitanServiceLocator.instance.isRegistered<LearningSessionRecoveryService>()
        ? TitanServiceLocator.instance.get<LearningSessionRecoveryService>()
        : LearningSessionRecoveryService(
            checkpointRepository: checkpointRepo,
            authoritativeRecoveryService: authRecovery,
          );

    return AdaptiveLearningJourneyOrchestrator(
      authRepository: authRepo,
      authRecoveryService: authRecovery,
      checkpointRepository: checkpointRepo,
      sessionRecoveryService: sessionRecovery,
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeSession() async {
    final effectiveLearner = widget.learnerId ?? _resolveLearnerId();
    List<NormalizedQuestion> effectiveCorpus = widget.corpus ?? [];

    if (effectiveCorpus.isEmpty) {
      try {
        final adapter = TitanServiceLocator.instance.isRegistered<PyqCorpusAdapterService>()
            ? TitanServiceLocator.instance.get<PyqCorpusAdapterService>()
            : PyqCorpusAdapterService();
        effectiveCorpus = await adapter.getCorpus(topic: widget.targetTopic);
      } catch (_) {
        effectiveCorpus = PyqCorpusAdapterService.getDefaultSeedCorpus();
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
        targetObjectiveId: widget.targetTopic,
        questionCount: widget.questionCount,
      );
    }
  }

  String _resolveLearnerId() {
    try {
      if (TitanServiceLocator.instance.isRegistered<AdaptiveLearningRuntimeCoordinator>()) {
        return TitanServiceLocator.instance.get<AdaptiveLearningRuntimeCoordinator>().activeLearnerId;
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
    if (_selectedOptionKey == null || _isSubmitting || !_controller.canSubmitAnswer) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await _controller.submitAnswer(answer: _selectedOptionKey!);

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
            widget.targetTopic != null
                ? "Adaptive Drill: ${widget.targetTopic}"
                : "Adaptive Practice Session",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            if (!_controller.isCompleted && _controller.session != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
          if (_feedbackResult != null) _buildFeedbackCard(context, _feedbackResult!),
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                  backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                ),
                Chip(
                  label: Text(question.difficulty),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _getDifficultyColor(question.difficulty).withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _getDifficultyColor(question.difficulty),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text("${question.examId.toUpperCase()} ${question.year}"),
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
              final isCorrectKey = question.officialAnswer.correctOptionKeys.contains(opt.key);

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
                cardBgColor = colorScheme.primaryContainer.withValues(alpha: 0.2);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: isAnswered ? null : () {
                    setState(() {
                      _selectedOptionKey = opt.key;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorderColor, width: isSelected || (isAnswered && isCorrectKey) ? 2 : 1),
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
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
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
                          const Icon(Icons.check_circle, color: Colors.green, size: 20)
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

  Widget _buildFeedbackCard(BuildContext context, PracticeQuestionResult result) {
    final isCorrect = result.isCorrect;

    return Card(
      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCorrect ? Colors.green.shade300 : Colors.red.shade300),
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
                  color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  isCorrect ? "Correct! Well done." : "Incorrect Attempt",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
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
        onPressed: _selectedOptionKey == null || _isSubmitting ? null : _handleAnswerSubmit,
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "Submit Answer",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCompletionSummary(BuildContext context) {
    final theme = Theme.of(context);
    final session = _controller.session;
    final totalQ = session?.totalQuestions ?? widget.questionCount;
    final results = session?.executionState.questionResults.values.toList() ?? [];
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
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Authoritative state updated to Revision $authRevision",
              style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
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
                    _buildMetricColumn("Correct", "$correctCount", Colors.green),
                    _buildMetricColumn("Accuracy", "${accuracy.toInt()}%", Colors.deepPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.home),
                label: const Text(
                  "Return to Dashboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
