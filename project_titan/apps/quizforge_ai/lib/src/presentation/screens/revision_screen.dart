import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_revision/titan_revision.dart';

import '../providers/revision_controller.dart';
import '../states/revision_state.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_card.dart';
import '../widgets/loading_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/revision/adaptive_schedule_card.dart';
import '../widgets/revision/revision_filter_bar.dart';
import '../widgets/revision/revision_queue_card.dart';
import '../widgets/revision/spaced_repetition_card.dart';
import '../widgets/revision/topic_mastery_card.dart';

/// Adaptive Revision Engine Screen presenting SM-2 spaced repetition queues,
/// recall ratings, adaptive schedules, and topic mastery.
class RevisionScreen extends ConsumerStatefulWidget {
  const RevisionScreen({super.key});

  @override
  ConsumerState<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends ConsumerState<RevisionScreen> {
  RevisionItem? _activeRecallItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(revisionControllerProvider.notifier).loadRevisionQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(revisionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Revision Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(revisionControllerProvider.notifier)
                .loadRevisionQueue(),
            tooltip: 'Refresh Queue',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, state),
        desktop: Center(
          child: SizedBox(
            width: 800,
            child: _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RevisionState state) {
    final theme = Theme.of(context);
    final controller = ref.read(revisionControllerProvider.notifier);

    if (state.isLoading && state.queue == null) {
      return const LoadingScreen(
          message: 'Generating adaptive revision queue...');
    }

    if (state.isError && state.queue == null) {
      return Padding(
        padding: AppSpacing.paddingLg,
        child: Center(
          child: ErrorCard(
            message: state.errorMessage ?? 'Unable to load revision queue.',
            onRetry: () => controller.loadRevisionQueue(),
          ),
        ),
      );
    }

    final queue = state.queue;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          RevisionFilterBar(
            selectedCategory: state.selectedCategory,
            filterOption: state.filterOption,
            onCategorySelected: (cat) => controller.selectCategory(cat),
            onFilterOptionSelected: (opt) => controller.selectFilterOption(opt),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Active Recall Session Rating Overlay Card
          if (_activeRecallItem != null) ...[
            SpacedRepetitionCard(
              item: _activeRecallItem!,
              onRateRecall: (rating) async {
                final itemId = _activeRecallItem!.id;
                setState(() => _activeRecallItem = null);
                await controller.recordRecallAttempt(itemId, rating);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Adaptive Schedule Card
          if (queue != null) ...[
            AdaptiveScheduleCard(queue: queue),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Topic Mastery Card
          TopicMasteryCard(topicMastery: state.topicMastery),
          const SizedBox(height: AppSpacing.lg),

          // Revision Queue List
          Text(
            'Active Recall Queue (${queue?.items.length ?? 0})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (queue == null || queue.items.isEmpty)
            const EmptyState(
              title: 'Revision Queue Clear',
              message: 'No due concept items found for selected filter.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: queue.items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = queue.items[index];
                return RevisionQueueCard(
                  item: item,
                  onStartRecall: () {
                    setState(() => _activeRecallItem = item);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
