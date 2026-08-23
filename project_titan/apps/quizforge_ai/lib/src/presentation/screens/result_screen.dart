import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_quiz/titan_quiz.dart';

import '../localization/app_localization.dart';
import '../navigation/app_routes.dart';
import '../providers/application_provider.dart';
import '../providers/result_controller.dart';

import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_card.dart';
import '../widgets/loading_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/result/mentor_result_card.dart';
import '../widgets/result/mistake_analysis_card.dart';
import '../widgets/result/pyq_card.dart';
import '../widgets/result/remedial_study_card.dart';
import '../widgets/result/revision_card.dart';
import '../widgets/result/score_card.dart';
import '../widgets/result/topic_analysis_card.dart';
import '../providers/adaptive_learning_controller.dart';
import '../providers/interactive_quiz_controller.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

/// Intelligent Results Dashboard screen using Clean Architecture via [ResultController].
class ResultScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ResultScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAnalytics();
    });
  }

  void _initAnalytics() {
    final appState = ref.read(applicationStateProvider);
    final summary = appState.currentResult;
    if (summary != null) {
      final quizResult = QuizResult(
        quizId: widget.sessionId,
        attempted: summary.attempted,
        correct: summary.correct,
        wrong: summary.wrong,
        unanswered: summary.unanswered,
        score: summary.score,
        maxScore: summary.maxScore,
        percentage: summary.percentage,
      );
      ref.read(resultControllerProvider.notifier).analyzeQuizResult(quizResult);

      final interactiveState = ref.read(interactiveQuizControllerProvider);
      if (interactiveState.performance != null) {
        final coordinator = ref.read(applicationCoordinatorProvider);
        coordinator
            .updateLearnerProfileAfterAssessment(
          sessionId: widget.sessionId,
          performance: interactiveState.performance!,
          questionStates: interactiveState.questionStates,
        )
            .then((_) {
          ref.read(adaptiveLearningProvider.notifier).refresh();
        }).catchError((_) {});
      }
    }
  }

  Future<void> _handleRetryIncorrect() async {
    try {
      final coordinator = ref.read(applicationCoordinatorProvider);
      final retrySession = await coordinator.createRetrySession(
        originalSessionId: widget.sessionId,
        retryMode: RetryMode.incorrect,
      );
      if (mounted) {
        context.goNamed(
          AppRoutes.quiz,
          pathParameters: {'id': retrySession.sessionId},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create retry session: $e')),
        );
      }
    }
  }

  Future<void> _handleStudySource(RemedialStudyRecommendation rec) async {
    if (rec.deepLinkRequest == null) return;
    final coordinator = ref.read(applicationCoordinatorProvider);
    final success =
        await coordinator.navigateToReaderSource(rec.deepLinkRequest!);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Document source unavailable (Page ${rec.primaryPageNumber}).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(applicationStateProvider);
    final result = appState.currentResult;
    final resultState = ref.watch(resultControllerProvider);
    final interactiveState = ref.watch(interactiveQuizControllerProvider);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppLocalization.navResult)),
        body: EmptyState(
          title: 'Result Not Found',
          message:
              'No result summary available for session ID [${widget.sessionId}].',
          action: ElevatedButton(
            onPressed: () => context.goNamed(AppRoutes.home),
            child: const Text(AppLocalization.btnBackToHome),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalization.navResult),
      ),
      body: ResponsiveLayout(
        mobile: _buildContent(context, resultState, result, interactiveState),
        desktop: Center(
          child: SizedBox(
            width: 720,
            child:
                _buildContent(context, resultState, result, interactiveState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic resultState,
    dynamic result,
    InteractiveQuizState interactiveState,
  ) {
    if (resultState.isLoading) {
      return const LoadingScreen(message: 'Analyzing performance metrics...');
    }

    if (resultState.isError) {
      return Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorCard(
              message:
                  resultState.errorMessage ?? 'Unable to compute analytics.',
              onRetry: () => _initAnalytics(),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.home),
              child: const Text(AppLocalization.btnBackToHome),
            ),
          ],
        ),
      );
    }

    final analytics = resultState.analytics;
    if (analytics == null) {
      return const LoadingScreen(message: 'Preparing dashboard...');
    }

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Score Card
          ScoreCard(metrics: analytics.scoreMetrics),
          const SizedBox(height: AppSpacing.md),

          // 2. Remedial Study Card (TITAN Reader Deep Link & Retry)
          RemedialStudyCard(
            recommendations: interactiveState.recommendations,
            onStudySource: _handleStudySource,
            onRetryIncorrect: _handleRetryIncorrect,
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. AI Mentor Result Card
          MentorResultCard(feedback: analytics.mentorFeedback),
          const SizedBox(height: AppSpacing.md),

          // 4. Topic Analysis Card
          TopicAnalysisCard(topics: analytics.topicPerformances),
          const SizedBox(height: AppSpacing.md),

          // 5. Mistake Analysis Card
          MistakeAnalysisCard(mistakeAnalysis: analytics.mistakeAnalysis),
          const SizedBox(height: AppSpacing.md),

          // 6. Revision Card
          RevisionCard(revision: analytics.revisionRecommendation),
          const SizedBox(height: AppSpacing.md),

          // 7. PYQ Correlation Card
          PYQCard(pyq: analytics.pyqCorrelation),
          const SizedBox(height: AppSpacing.xl),

          // Action Button
          ElevatedButton.icon(
            onPressed: () => context.goNamed(AppRoutes.home),
            icon: const Icon(Icons.home),
            label: const Text(AppLocalization.btnBackToHome),
          ),
        ],
      ),
    );
  }
}
