import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localization.dart';
import '../navigation/app_routes.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/error_card.dart';
import '../widgets/responsive_layout.dart';
import '../../states/quiz_workflow_state.dart';

/// Screen allowing selection of a PDF document to generate a quiz.
class ImportPdfScreen extends ConsumerWidget {
  const ImportPdfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowState = ref.watch(quizProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalization.navImportPdf),
      ),
      body: ResponsiveLayout(
        mobile: _buildForm(context, ref, theme, workflowState),
        desktop: Center(
          child: SizedBox(
            width: 600,
            child: _buildForm(context, ref, theme, workflowState),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    QuizWorkflowState workflowState,
  ) {
    final selectedName = workflowState.selectedFileName ?? 'No PDF selected';

    return Padding(
      padding: AppSpacing.paddingLg,
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Import PDF Source',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose a PDF study document to generate a quiz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Semantics(
                key: ValueKey<String>(selectedName),
                label: 'Selected PDF filename',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(selectedName),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: workflowState.isBusy
                  ? null
                  : () => ref.read(quizProvider.notifier).selectPdf(),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import PDF'),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed:
                  workflowState.selectedFilePath == null || workflowState.isBusy
                      ? null
                      : () => context.goNamed(AppRoutes.quizLoading),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Quiz'),
            ),
            if (workflowState.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorCard(
                message: workflowState.errorMessage ??
                    'Unable to select the PDF. Please try again.',
                onRetry: () => ref.read(quizProvider.notifier).selectPdf(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
