import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learning_session_models.dart';
import '../providers/learning_flow_providers.dart';
import 'checkpoint_timeline.dart';
import 'exit_confirmation_dialog.dart';
import 'lesson_completion_sheet.dart';
import 'progress_overlay.dart';
import 'resume_session_banner.dart';
import 'study_session_bar.dart';
import 'study_session_summary.dart';

/// Master end-to-end learning flow screen guiding the learner through:
/// Content -> Media -> Smart Notes -> AI Tutor -> Quick Quiz -> Assessment -> Feedback -> Revision -> Summary.
class LearningFlowScreen extends ConsumerWidget {
  final String userId;
  final String courseId;
  final String courseTitle;
  final String lessonId;
  final String lessonTitle;
  final VoidCallback? onReturnToDashboard;

  const LearningFlowScreen({
    super.key,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.lessonId,
    required this.lessonTitle,
    this.onReturnToDashboard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningFlowStateNotifierProvider);
    final notifier = ref.read(learningFlowStateNotifierProvider.notifier);

    // Start session automatically if not active
    if (state.session == null && !state.isSyncing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.startSession(
          userId: userId,
          courseId: courseId,
          courseTitle: courseTitle,
          lessonId: lessonId,
          lessonTitle: lessonTitle,
        );
      });
    }

    final session = state.session;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (session != null)
                  StudySessionBar(
                    session: session,
                    onPauseTap: () => notifier.pauseSession(),
                    onResumeTap: () => notifier.resumeSession(),
                    onExitTap: () => _showExitDialog(context, notifier),
                  ),
                if (state.isInterrupted && session != null)
                  ResumeSessionBanner(
                    session: session,
                    onResume: () => notifier.resumeSession(),
                    onDismiss: () => notifier.abandonSession(),
                  ),
                CheckpointTimeline(
                  currentStep: state.currentStep,
                  onStepTap: (targetStep) {
                    notifier.advanceCheckpoint(
                      targetStep: targetStep,
                      progressPercentage: 0.5,
                    );
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildStepBody(context, state, notifier),
                  ),
                ),
                _buildBottomNavigation(context, state, notifier),
              ],
            ),
            if (state.isSyncing)
              const ProgressOverlay(
                message: 'Synchronizing cross-engine TITAN progress...',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(
    BuildContext context,
    LearningFlowState state,
    LearningFlowStateNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (state.currentStep) {
      case LearningFlowStep.learningContent:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessonTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Course: $courseTitle',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Indian Constitutional Law forms the cornerstone of GS Paper II in the UPSC Civil Services Examination. Key areas include the Preamble, Fundamental Rights (Articles 12-35), Directive Principles of State Policy, and Judicial Review. Understanding the Basic Structure Doctrine established in the Kesavananda Bharati case (1973) is essential for analytical answers.',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        );

      case LearningFlowStep.mediaPlayback:
        return Column(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 64),
                  const SizedBox(height: 8),
                  Text(
                    'Video Playback: Fundamental Rights & Article 21',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case LearningFlowStep.smartNotes:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Smart Notes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Type smart notes or AI key takeaways here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ),
          ],
        );

      case LearningFlowStep.aiTutor:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'AI Tutor Assistant',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'AI Tutor Tip: Article 21 guarantees Right to Life & Personal Liberty. In Puttaswamy (2017), the Supreme Court declared Privacy as an intrinsic part of Article 21.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Explain Article 21'),
                  onPressed: () {},
                ),
                ActionChip(
                  avatar: const Icon(Icons.summarize_outlined, size: 16),
                  label: const Text('Summarize Case Laws'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        );

      case LearningFlowStep.quickQuiz:
      case LearningFlowStep.adaptiveAssessment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Practice Quiz',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q1: Which constitutional amendment inserted Article 21A (Right to Education)?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.radio_button_checked,
                          color: colorScheme.primary),
                      title: const Text(
                          'A) 86th Constitutional Amendment Act, 2002'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.radio_button_unchecked,
                          color: colorScheme.onSurfaceVariant),
                      title: const Text(
                          'B) 44th Constitutional Amendment Act, 1978'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case LearningFlowStep.instantFeedback:
      case LearningFlowStep.revisionPlan:
      case LearningFlowStep.completed:
        if (state.summary != null) {
          return SingleChildScrollView(
            child: StudySessionSummary(
              summary: state.summary!,
              onReturnHome: onReturnToDashboard,
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());

      default:
        return Center(
          child: Text('Step: ${state.currentStep.name}'),
        );
    }
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    LearningFlowState state,
    LearningFlowStateNotifier notifier,
  ) {
    if (state.currentStep == LearningFlowStep.completed) {
      return const SizedBox.shrink();
    }

    final isLastStep = state.currentStep == LearningFlowStep.revisionPlan;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _showExitDialog(context, notifier),
            child: const Text('Exit Flow'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (isLastStep) {
                final summary = await notifier.finishSession();
                if (context.mounted) {
                  _showCompletionSheet(context, summary);
                }
              } else {
                final nextIndex = state.currentStep.index + 1;
                if (nextIndex < LearningFlowStep.values.length) {
                  notifier.advanceCheckpoint(
                    targetStep: LearningFlowStep.values[nextIndex],
                    progressPercentage:
                        nextIndex / (LearningFlowStep.values.length - 1),
                  );
                }
              }
            },
            icon: Icon(
              isLastStep
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
              size: 18,
            ),
            label: Text(isLastStep ? 'Finish Lesson' : 'Next Step'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(
      BuildContext context, LearningFlowStateNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ExitConfirmationDialog(
        onPauseAndExit: () {
          notifier.pauseSession();
          Navigator.of(ctx).pop();
          onReturnToDashboard?.call();
        },
        onAbandon: () {
          notifier.abandonSession();
          Navigator.of(ctx).pop();
          onReturnToDashboard?.call();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showCompletionSheet(BuildContext context, LearningFlowSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LessonCompletionSheet(
        summary: summary,
        onContinue: () {
          Navigator.of(ctx).pop();
        },
        onReturnToDashboard: () {
          Navigator.of(ctx).pop();
          onReturnToDashboard?.call();
        },
      ),
    );
  }
}
