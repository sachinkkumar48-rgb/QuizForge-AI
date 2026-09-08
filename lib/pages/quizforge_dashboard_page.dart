import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';
import '../core/di/service_locator_init.dart';
import '../widgets/dashboard/dashboard_header_widget.dart';
import '../widgets/dashboard/plugin_module_grid_widget.dart';
import '../widgets/dashboard/quick_action_card_widget.dart';
import '../widgets/dashboard/recent_activity_card_widget.dart';
import '../widgets/dashboard/stat_summary_card_widget.dart';
import 'adaptive_practice_page.dart';
import 'ai_mentor_panel_page.dart';
import 'analytics_dashboard_page.dart';
import 'assessment_management_page.dart';
import 'cohort_management_page.dart';
import 'content_learning_path_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'learning_plan_page.dart';
import 'library_page.dart';
import 'module_explorer_page.dart';
import 'settings_page.dart';

/// The central QuizForge AI Learner Dashboard & Control Center Screen (P41).
///
/// Driven entirely by authoritative application state:
/// - Continue Learning (session recovery opportunity or start learning)
/// - Current Learning Progress (authoritative attempts, accuracy, mastery)
/// - Next Best Learning Action (pedagogical recommendation)
/// - Exam & Subject Content Navigation
/// - Learning Activity History
class QuizForgeDashboardPage extends StatefulWidget {
  final DashboardController? controller;

  const QuizForgeDashboardPage({
    super.key,
    this.controller,
  });

  @override
  State<QuizForgeDashboardPage> createState() => _QuizForgeDashboardPageState();
}

class _QuizForgeDashboardPageState extends State<QuizForgeDashboardPage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? locate<DashboardController>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              "QuizForge AI",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('dashboard_analytics_button'),
            icon: const Icon(Icons.analytics_outlined),
            tooltip: "Learning Analytics",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AnalyticsDashboardPage()),
              );
            },
          ),
          IconButton(
            key: const Key('dashboard_cohorts_button'),
            icon: const Icon(Icons.school_outlined),
            tooltip: "Cohorts & Assignments",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CohortManagementPage(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('dashboard_assessments_button'),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: "Assessments & Examinations",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AssessmentManagementPage(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('dashboard_cloud_sync_button'),
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: "Cloud Synchronization",
            onPressed: () async {
              try {
                final syncService = locate<LearnerStateSyncService>();
                final result = await syncService.sync(
                  learnerId: 'default_learner',
                  examId: 'upsc_prelims_gs1',
                  deviceId: 'device_primary',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Offline: Progress saved locally in outbox.'),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.alt_route),
            tooltip: "Learning Plan",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningPlanPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Metrics",
            onPressed: () => _controller.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<DashboardState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          if (state.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading Learner Control Center...",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          if (state.isError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Unable to Load Dashboard",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? "An unexpected error occurred.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _controller.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          final learnerState = _controller.learnerState;

          return RefreshIndicator(
            onRefresh: () => _controller.refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1100;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 36 : 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Widget
                      DashboardHeaderWidget(
                        state: state,
                        onSettingsPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Section A: Continue Learning Card (Recovery / Continuation)
                      _buildContinueLearningCard(
                        context,
                        learnerState.continueLearning,
                      ),
                      const SizedBox(height: 20),

                      // Section B: Next Best Learning Action Card
                      if (learnerState.nextAction.isAvailable &&
                          learnerState.nextAction.actionType !=
                              AdaptiveActionType.none &&
                          learnerState.nextAction.actionType !=
                              AdaptiveActionType.continueSession) ...[
                        _buildNextBestActionCard(
                          context,
                          learnerState.nextAction,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section P43: Personalized Learning Priorities
                      if (_controller.priorityQueue != null &&
                          _controller.priorityQueue!.isNotEmpty) ...[
                        _buildPersonalizedPrioritiesCard(
                          context,
                          _controller.priorityQueue!,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section B: Current Learning Progress Summary
                      _buildLearningProgressCard(
                        context,
                        learnerState.progressSummary,
                        state.stats,
                      ),
                      const SizedBox(height: 24),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Main Column: Navigation & Plugins
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Quick Actions",
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildQuickActionGrid(),
                                  const SizedBox(height: 24),
                                  PluginModuleGridWidget(
                                    modules: state.activeModules,
                                    onExploreTap: () =>
                                        _navigateTo(const ModuleExplorerPage()),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Right Side Column: History & Activities
                            Expanded(
                              flex: 2,
                              child: RecentActivityCardWidget(
                                activities: state.recentActivities,
                                activeSessionSourceName:
                                    state.activeSessionSourceName,
                                onResumeSessionTap: _handleResumeSession,
                                onActivityTap: _handleActivityTap,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        Text(
                          "Quick Actions",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildQuickActionGrid(),
                        const SizedBox(height: 24),
                        RecentActivityCardWidget(
                          activities: state.recentActivities,
                          activeSessionSourceName:
                              state.activeSessionSourceName,
                          onResumeSessionTap: _handleResumeSession,
                          onActivityTap: _handleActivityTap,
                        ),
                        const SizedBox(height: 24),
                        PluginModuleGridWidget(
                          modules: state.activeModules,
                          onExploreTap: () =>
                              _navigateTo(const ModuleExplorerPage()),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Section A: Continue Learning Card (Active Session Continuation or Start Learning).
  Widget _buildContinueLearningCard(
    BuildContext context,
    ContinueLearningCardState continueCard,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (continueCard.hasRecoverableSession) {
      final topic = continueCard.topic ?? "UPSC Practice";
      final cursor = continueCard.questionIndex + 1;
      final total = continueCard.totalQuestions ?? 5;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amber, width: 2),
        ),
        color: Colors.amber.shade50.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "IN-PROGRESS ADAPTIVE SESSION",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topic,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _handleResumeSession,
                    icon: const Icon(Icons.play_circle_fill, size: 20),
                    label: const Text(
                      "Continue",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade900,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question $cursor of $total in progress",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${(continueCard.progressPercentage * 100).toInt()}% completed",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: continueCard.progressPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.amber.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No recoverable session -> Meaningful Start Learning action
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.school, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Start Adaptive Practice",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Launch targeted UPSC Prelims questions adapted to your active knowledge frontier.",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _navigateTo(const AdaptivePracticePage()),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text("Start"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section C: Next Best Learning Action Card (Pedagogical Recommendation).
  Widget _buildNextBestActionCard(
    BuildContext context,
    NextBestActionState nextAction,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color accentColor = switch (nextAction.actionType) {
      AdaptiveActionType.startRemedialLesson => Colors.red.shade700,
      AdaptiveActionType.reviewWeakTopic => Colors.orange.shade700,
      AdaptiveActionType.takeDiagnostic => Colors.deepPurple,
      _ => colorScheme.primary,
    };

    final IconData actionIcon = switch (nextAction.actionType) {
      AdaptiveActionType.startRemedialLesson => Icons.healing,
      AdaptiveActionType.reviewWeakTopic => Icons.repeat,
      AdaptiveActionType.takeDiagnostic => Icons.assignment_turned_in,
      AdaptiveActionType.practicePyqs => Icons.history_edu,
      _ => Icons.lightbulb,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accentColor.withValues(alpha: 0.35)),
      ),
      color: accentColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Icon(actionIcon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "NEXT BEST ACTION",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextAction.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextAction.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _navigateTo(const LearningPlanPage()),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.alt_route, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          "View Full Learning Plan",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => _handleNextActionTap(nextAction),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
              ),
              child: const Text(
                "Action",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section B: Current Learning Progress Summary Card.
  Widget _buildLearningProgressCard(
    BuildContext context,
    LearnerProgressSummaryState summary,
    DashboardStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Current Learning Progress",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(summary.learningStatus)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                summary.learningStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(summary.learningStatus),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatSummaryCardWidget(stats: stats),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Proficient':
        return Colors.green.shade700;
      case 'Needs Remediation':
        return Colors.red.shade700;
      case 'Active Practice':
        return Colors.deepPurple;
      default:
        return Colors.blue.shade700;
    }
  }

  Widget? _quickActionGrid;

  Widget _buildQuickActionGrid() {
    return _quickActionGrid ??= QuickActionCardWidget(
      onGenerateQuizTap: () => _navigateTo(const HomePage()),
      onPyqTap: () => _navigateTo(const ContentLearningPathPage()),
      onAiCoachTap: () => _navigateTo(const AIMentorPanelPage()),
      onPdfLibraryTap: () => _navigateTo(const LibraryPage()),
      onHistoryTap: () => _navigateTo(const HistoryPage()),
      onPluginHubTap: () => _navigateTo(const ModuleExplorerPage()),
    );
  }

  void _handleActivityTap(RecentActivity activity) {
    if (activity.categoryTag == 'Adaptive Mastery' ||
        activity.id == 'adaptive_rec_target' ||
        activity.categoryTag == 'Next Best Action') {
      String targetTopic = 'Fundamental Rights';
      if (activity.title.startsWith('Adaptive Target: ')) {
        targetTopic =
            activity.title.replaceFirst('Adaptive Target: ', '').trim();
      }
      _navigateTo(
        AdaptivePracticePage(
          targetTopic: targetTopic,
        ),
      );
    } else if (activity.categoryTag == 'In Progress') {
      _handleResumeSession();
    }
  }

  void _handleNextActionTap(NextBestActionState nextAction) {
    switch (nextAction.actionType) {
      case AdaptiveActionType.continueSession:
        _handleResumeSession();
        break;
      case AdaptiveActionType.startRemedialLesson:
      case AdaptiveActionType.reviewWeakTopic:
      case AdaptiveActionType.continuePractice:
        _navigateTo(
          AdaptivePracticePage(
            targetTopic: nextAction.targetTopic,
          ),
        );
        break;
      case AdaptiveActionType.takeDiagnostic:
        _navigateTo(
          const AdaptivePracticePage(
            targetTopic: 'Indian Polity & Constitution',
          ),
        );
        break;
      case AdaptiveActionType.practicePyqs:
        _navigateTo(const ContentLearningPathPage());
        break;
      case AdaptiveActionType.none:
        break;
    }
  }

  void _handleResumeSession() {
    final continueCard = _controller.learnerState.continueLearning;
    _navigateTo(
      AdaptivePracticePage(
        isResumeMode: true,
        resumeSessionId: continueCard.sessionId,
        targetTopic: continueCard.topic,
      ),
    );
  }

  Widget _buildPersonalizedPrioritiesCard(
    BuildContext context,
    PersonalizedPriorityQueue queue,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPriority = queue.currentPriority;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.deepPurple.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      color: Colors.deepPurple.shade50.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.psychology, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOUR LEARNING PRIORITIES",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${queue.items.length} Objectives Prioritized",
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _navigateTo(const LearningPlanPage()),
                  icon: const Icon(Icons.alt_route, size: 16),
                  label: const Text(
                    "Plan",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (topPriority != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${topPriority.subjectName} • ${topPriority.topicName}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStageBadge(topPriority.stage),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topPriority.objectiveTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topPriority.reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.query_builder,
                            size: 15, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "Attempts: ${topPriority.evidenceCount}",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.track_changes,
                            size: 15, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "Accuracy: ${(topPriority.accuracy * 100).toInt()}%",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('priority_queue_action_button'),
                        onPressed: () => _handlePriorityAction(topPriority),
                        icon:
                            Icon(_getActionIcon(topPriority.action), size: 18),
                        label: Text(
                          _getActionLabel(topPriority.action),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (queue.items.length > 1) ...[
              const SizedBox(height: 14),
              Text(
                "Upcoming Priorities",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...queue.items.skip(1).take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text(
                            "#${item.priorityRank}",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.objectiveTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.topicName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStageBadge(item.stage),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageBadge(ProgressionStage stage) {
    final (color, label) = switch (stage) {
      ProgressionStage.remediationRequired => (Colors.red, 'Remediation'),
      ProgressionStage.regressed => (Colors.orange, 'Regressed'),
      ProgressionStage.improving => (Colors.teal, 'Improving'),
      ProgressionStage.learning => (Colors.blue, 'Learning'),
      ProgressionStage.mastered => (Colors.green, 'Mastered'),
      ProgressionStage.insufficientEvidence => (
          Colors.indigo,
          'Evidence Needed'
        ),
      ProgressionStage.notStarted => (Colors.grey, 'Not Started'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.shade800,
        ),
      ),
    );
  }

  IconData _getActionIcon(PriorityActionType action) {
    return switch (action) {
      PriorityActionType.continueSession => Icons.play_arrow,
      PriorityActionType.takeDiagnostic => Icons.assignment_turned_in,
      PriorityActionType.startRemedialLesson => Icons.healing,
      PriorityActionType.practicePyqs => Icons.history_edu,
      PriorityActionType.reviewRevision => Icons.replay,
      _ => Icons.school,
    };
  }

  String _getActionLabel(PriorityActionType action) {
    return switch (action) {
      PriorityActionType.continueSession => 'Resume Practice Drill',
      PriorityActionType.takeDiagnostic => 'Take Diagnostic Assessment',
      PriorityActionType.startRemedialLesson => 'Start Remedial Micro-Lesson',
      PriorityActionType.practicePyqs => 'Practice PYQ Questions',
      PriorityActionType.reviewRevision => 'Review Spaced Revision',
      _ => 'Start Practice Drill',
    };
  }

  void _handlePriorityAction(PersonalizedLearningPriorityItem item) {
    switch (item.action) {
      case PriorityActionType.continueSession:
        if (item.sessionId != null) {
          _navigateTo(
            AdaptivePracticePage(
              isResumeMode: true,
              resumeSessionId: item.sessionId,
              targetTopic: item.topicName,
            ),
          );
        } else {
          _handleResumeSession();
        }
        break;
      case PriorityActionType.takeDiagnostic:
        _navigateTo(
          AdaptivePracticePage(
            targetTopic: item.topicName,
          ),
        );
        break;
      case PriorityActionType.startRemedialLesson:
        _navigateTo(
          LearningPlanPage(
            examId: item.examId,
          ),
        );
        break;
      case PriorityActionType.practicePyqs:
        _navigateTo(const ContentLearningPathPage());
        break;
      case PriorityActionType.practice:
      case PriorityActionType.reviewRevision:
      default:
        _navigateTo(
          AdaptivePracticePage(
            targetTopic: item.topicName,
          ),
        );
        break;
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      if (mounted) {
        _controller.refresh();
      }
    });
  }
}
