import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localization.dart';
import '../navigation/app_routes.dart';
import '../providers/application_provider.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/responsive_layout.dart';
import '../../states/application_state.dart';
import '../../states/quiz_workflow_state.dart';

/// Main home dashboard screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(applicationStateProvider);
    final workflowState = ref.watch(quizProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalization.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalization.navSettings,
            onPressed: () => context.pushNamed(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: AppLocalization.navAbout,
            onPressed: () => context.pushNamed(AppRoutes.about),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, appState, workflowState, theme),
        desktop: Center(
          child: SizedBox(
            width: 800,
            child: _buildBody(context, appState, workflowState, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ApplicationState appState,
    QuizWorkflowState workflowState,
    ThemeData theme,
  ) {
    final session = workflowState.session ?? appState.currentSession;
    final selectedName = workflowState.selectedFileName ?? 'No PDF selected';

    return Padding(
      padding: AppSpacing.paddingMd,
      child: ListView(
        children: [
          Semantics(
            label: 'PDF import workflow',
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalization.emptyQuizTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocalization.emptyQuizSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () => context.pushNamed(AppRoutes.importPdf),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Import PDF'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      label: 'Selected PDF filename',
                      child: Text(
                        'Selected PDF: $selectedName',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: session == null
                          ? null
                          : () => context.pushNamed(
                                AppRoutes.quiz,
                                pathParameters: {'id': session.sessionId},
                              ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Quiz'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (session != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: Icon(Icons.quiz,
                    color: theme.colorScheme.primary, size: 40),
                title: const Text('Active Quiz Session'),
                subtitle: Text('Session ID: ${session.sessionId}'),
                trailing: ElevatedButton(
                  onPressed: () => context.pushNamed(
                    AppRoutes.quiz,
                    pathParameters: {'id': session.sessionId},
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
