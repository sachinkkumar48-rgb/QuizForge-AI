import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

import '../localization/app_localization.dart';
import '../navigation/app_routes.dart';
import '../providers/application_provider.dart';
import '../providers/interactive_quiz_controller.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/quiz/immediate_feedback_card.dart';
import '../widgets/quiz/interactive_option_tile.dart';
import '../widgets/quiz/question_progress_strip.dart';
import '../widgets/responsive_layout.dart';

/// Screen representing interactive assessment session with immediate feedback and remedial study integration.
class QuizScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const QuizScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _initialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }

  Future<void> _initializeQuiz() async {
    try {
      final coordinator = ref.read(applicationCoordinatorProvider);
      final session =
          await coordinator.quizSessionRepository.loadSession(widget.sessionId);
      if (session == null) {
        setState(() => _initError = 'Session [${widget.sessionId}] not found.');
        return;
      }

      final quiz = await coordinator.quizRepository.loadQuiz(session.quizId);
      if (quiz == null) {
        setState(() =>
            _initError = 'Associated quiz [${session.quizId}] not found.');
        return;
      }

      ref.read(interactiveQuizControllerProvider.notifier).initialize(
            quiz: quiz,
            session: session,
          );

      if (mounted) {
        setState(() {
          _initialized = true;
          _initError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initError = 'Failed to load assessment: $e');
      }
    }
  }

  Future<void> _completeAssessment() async {
    final controller = ref.read(interactiveQuizControllerProvider.notifier);
    final performance = await controller.completeAssessment();
    if (performance != null && mounted) {
      context.goNamed(
        AppRoutes.result,
        pathParameters: {'id': widget.sessionId},
      );
    }
  }

  Future<void> _handleStudySource(
    InteractiveQuestionState questionState,
    InteractiveQuizState quizState,
  ) async {
    final docId = quizState.quiz?.sourceDocumentId ?? 'document';
    final pageNum = questionState.pageNumber ?? 1;
    final chunkId = questionState.sourceChunkId;

    final request = ReaderDeepLinkRequest(
      documentId: docId,
      pageNumber: pageNum,
      chunkId: chunkId,
      source: 'quiz_interactive_feedback',
    );

    final success = await ref
        .read(interactiveQuizControllerProvider.notifier)
        .studySourceInReader(request);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document source unavailable (Page $pageNum).'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quizState = ref.watch(interactiveQuizControllerProvider);

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppLocalization.navQuiz)),
        body: EmptyState(
          title: 'Assessment Not Found',
          message: _initError!,
          action: ElevatedButton(
            onPressed: () => context.goNamed(AppRoutes.home),
            child: const Text(AppLocalization.btnBackToHome),
          ),
        ),
      );
    }

    if (!_initialized || quizState.quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppLocalization.navQuiz)),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final quiz = quizState.quiz!;
    final currentQ = quizState.currentQuestion;
    final currentQState = quizState.currentQuestionState;

    if (currentQ == null || currentQState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppLocalization.navQuiz)),
        body: EmptyState(
          title: 'Empty Assessment',
          message: 'No questions available in this assessment.',
          action: ElevatedButton(
            onPressed: () => context.goNamed(AppRoutes.home),
            child: const Text(AppLocalization.btnBackToHome),
          ),
        ),
      );
    }

    final isLastQuestion =
        quizState.currentIndex == quizState.totalQuestions - 1;
    final isMultipleSelect =
        currentQState.questionType == AssessmentQuestionType.multipleSelect;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          quiz.title.isNotEmpty ? quiz.title : 'Assessment',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentQState.isMarkedForReview
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: currentQState.isMarkedForReview ? Colors.amber : null,
            ),
            tooltip: currentQState.isMarkedForReview
                ? 'Marked for Review'
                : 'Mark for Review',
            onPressed: () => ref
                .read(interactiveQuizControllerProvider.notifier)
                .toggleMarkForReview(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: quizState.isLoading,
        message: 'Evaluating response...',
        child: ResponsiveLayout(
          mobile: _buildContent(
            context,
            theme,
            colorScheme,
            quizState,
            currentQ,
            currentQState,
            isLastQuestion,
            isMultipleSelect,
          ),
          desktop: Center(
            child: SizedBox(
              width: 840,
              child: _buildContent(
                context,
                theme,
                colorScheme,
                quizState,
                currentQ,
                currentQState,
                isLastQuestion,
                isMultipleSelect,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    InteractiveQuizState quizState,
    QuizQuestion currentQ,
    InteractiveQuestionState currentQState,
    bool isLastQuestion,
    bool isMultipleSelect,
  ) {
    return Column(
      children: [
        // 1. Progress Indicators
        LinearProgressIndicator(value: quizState.progress),
        const SizedBox(height: 4),
        QuestionProgressStrip(
          currentIndex: quizState.currentIndex,
          questions: quizState.quiz!.questions,
          questionStates: quizState.questionStates,
          onQuestionTapped: (index) => ref
              .read(interactiveQuizControllerProvider.notifier)
              .jumpToQuestion(index),
        ),
        const Divider(height: 1),

        // 2. Question Details & Options (Scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Q${quizState.currentIndex + 1} of ${quizState.totalQuestions}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (currentQ.topic != null && currentQ.topic!.isNotEmpty)
                      Chip(
                        label: Text(currentQ.topic!),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    const Spacer(),
                    Text(
                      '+${currentQ.marks.toStringAsFixed(0)} / -${currentQ.negativeMarks.toStringAsFixed(1)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Question text card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Text(
                      currentQ.question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Question options
                ...List.generate(currentQ.options.length, (index) {
                  final opt = currentQ.options[index];
                  final optText = opt.text;
                  final isSelected =
                      currentQState.selectedOptionIndices.contains(index);
                  final isCorrectOpt = index == currentQ.correctAnswerIndex;

                  return InteractiveOptionTile(
                    optionIndex: index,
                    optionText: optText,
                    isSelected: isSelected,
                    isEvaluated: currentQState.isSubmitted,
                    isCorrectOption: isCorrectOpt,
                    isMultipleSelect: isMultipleSelect,
                    onTap: () => ref
                        .read(interactiveQuizControllerProvider.notifier)
                        .selectOption(index),
                  );
                }),

                // 3. Immediate Feedback Card (Visible once submitted)
                if (currentQState.isSubmitted) ...[
                  const SizedBox(height: AppSpacing.md),
                  ImmediateFeedbackCard(
                    isCorrect: currentQState.isCorrect,
                    explanation:
                        currentQ.explanation ?? 'No explanation provided.',
                    pageNumber: currentQState.pageNumber,
                    sourceChunkId: currentQState.sourceChunkId,
                    onStudySource: () =>
                        _handleStudySource(currentQState, quizState),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 4. Bottom Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: quizState.currentIndex > 0
                    ? () => ref
                        .read(interactiveQuizControllerProvider.notifier)
                        .previousQuestion()
                    : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Previous'),
              ),
              if (!currentQState.isSubmitted)
                ElevatedButton.icon(
                  onPressed: currentQState.isSelected
                      ? () => ref
                          .read(interactiveQuizControllerProvider.notifier)
                          .submitCurrentAnswer()
                      : null,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Submit Answer'),
                )
              else if (!isLastQuestion)
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(interactiveQuizControllerProvider.notifier)
                      .nextQuestion(),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text(AppLocalization.btnNextQuestion),
                )
              else
                FilledButton.icon(
                  onPressed: _completeAssessment,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Finish Assessment'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
