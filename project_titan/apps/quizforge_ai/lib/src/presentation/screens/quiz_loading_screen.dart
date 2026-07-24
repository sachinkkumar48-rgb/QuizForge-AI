import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../states/quiz_workflow_state.dart';
import '../navigation/app_routes.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/error_card.dart';
import '../widgets/loading_screen.dart';

/// Screen displayed while the PDF import and AI quiz generation workflow runs.
class QuizLoadingScreen extends ConsumerStatefulWidget {
  const QuizLoadingScreen({super.key});

  @override
  ConsumerState<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends ConsumerState<QuizLoadingScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWorkflow());
  }

  Future<void> _startWorkflow() async {
    if (_started || !mounted) return;
    _started = true;
    await ref.read(quizProvider.notifier).createQuizFromPdf();
  }

  Future<void> _retryWorkflow() async {
    _started = false;
    await _startWorkflow();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuizWorkflowState>(quizProvider, (previous, next) {
      final session = next.session;
      if (session != null && next.stage == QuizWorkflowStage.ready) {
        context.goNamed(
          AppRoutes.quiz,
          pathParameters: {'id': session.sessionId},
        );
      }
    });

    final workflowState = ref.watch(quizProvider);

    if (workflowState.stage == QuizWorkflowStage.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preparing Quiz')),
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: ErrorCard(
              message: workflowState.errorMessage ??
                  'We could not prepare your quiz. Please try again.',
              onRetry: _retryWorkflow,
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        key: ValueKey<QuizWorkflowStage>(workflowState.stage),
        liveRegion: true,
        label: workflowState.operationMessage,
        child: LoadingScreen(
          message: workflowState.operationMessage,
        ),
      ),
    );
  }
}
