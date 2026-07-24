import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import '../localization/app_localization.dart';
import '../navigation/app_routes.dart';
import '../providers/application_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/responsive_layout.dart';

/// Screen representing active quiz attempt session UI architecture.
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
  int _currentIndex = 0;

  Future<void> _completeSession() async {
    final summary = await ref
        .read(sessionProvider.notifier)
        .completeSession(widget.sessionId);
    if (summary != null && mounted) {
      context.goNamed(
        AppRoutes.result,
        pathParameters: {'id': widget.sessionId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final appState = ref.watch(applicationStateProvider);
    final theme = Theme.of(context);

    final currentSession = appState.currentSession;
    if (currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppLocalization.navQuiz)),
        body: EmptyState(
          title: 'Session Not Active',
          message: 'No active session found for ID [${widget.sessionId}].',
          action: ElevatedButton(
            onPressed: () => context.goNamed(AppRoutes.home),
            child: const Text(AppLocalization.btnBackToHome),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Quiz Session (${_currentIndex + 1}/${currentSession.answers.length})'),
      ),
      body: LoadingOverlay(
        isLoading: sessionState.isLoading,
        message: 'Processing answer...',
        child: ResponsiveLayout(
          mobile: _buildContent(context, currentSession, theme, sessionState),
          desktop: Center(
            child: SizedBox(
              width: 800,
              child:
                  _buildContent(context, currentSession, theme, sessionState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    QuizSession session,
    ThemeData theme,
    AsyncValue sessionState,
  ) {
    if (sessionState.hasError) {
      return Padding(
        padding: AppSpacing.paddingLg,
        child: ErrorCard(
          message: AppLocalization.formatErrorMessage(sessionState.error),
          onRetry: () =>
              ref.read(applicationStateProvider.notifier).updateState(),
        ),
      );
    }

    final answer = session.answers[_currentIndex];

    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / session.answers.length,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Text(
                'Question ID: ${answer.questionId}',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _currentIndex--),
                  child: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              if (_currentIndex < session.answers.length - 1)
                ElevatedButton(
                  onPressed: () => setState(() => _currentIndex++),
                  child: const Text(AppLocalization.btnNextQuestion),
                )
              else
                ElevatedButton(
                  onPressed: _completeSession,
                  child: const Text(AppLocalization.btnCompleteQuiz),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
