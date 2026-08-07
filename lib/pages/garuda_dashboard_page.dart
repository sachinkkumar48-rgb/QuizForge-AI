import 'package:flutter/material.dart';
import 'package:quizforge_upsc/controllers/garuda_dashboard_viewmodel.dart';
import 'package:quizforge_upsc/widgets/garuda_dashboard_widgets.dart';

/// GARUDA AI Production-Ready Learner Dashboard Page
class GarudaDashboardPage extends StatefulWidget {
  final DashboardViewModel? viewModel;
  final String userId;

  const GarudaDashboardPage({
    super.key,
    this.viewModel,
    this.userId = 'user_garuda_01',
  });

  @override
  State<GarudaDashboardPage> createState() => _GarudaDashboardPageState();
}

class _GarudaDashboardPageState extends State<GarudaDashboardPage> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? DashboardViewModel();
    _viewModel.loadDashboardData(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GARUDA AI Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Dashboard',
                onPressed: () => _viewModel.loadDashboardData(widget.userId),
              ),
            ],
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading GARUDA AI Dashboard...'),
          ],
        ),
      );
    }

    if (_viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _viewModel.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _viewModel.loadDashboardData(widget.userId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width > 1000) {
          // Desktop Layout (3 Columns)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      NextBestActionCard(nba: _viewModel.nextBestAction),
                      const SizedBox(height: 16),
                      TodayStudyPlanCard(plan: _viewModel.studyPlan),
                      const SizedBox(height: 16),
                      RecentConversationsCard(conversations: _viewModel.recentConversations),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      TodayRevisionQueueCard(queue: _viewModel.revisionQueue),
                      const SizedBox(height: 16),
                      LearningProgressCard(profile: _viewModel.learningProfile),
                      const SizedBox(height: 16),
                      PdfLibraryCard(pdfs: _viewModel.pdfLibrary),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      StudyStreakCard(
                        streakDays: _viewModel.learningProfile?.studyStreakDays ?? 0,
                      ),
                      const SizedBox(height: 16),
                      QuickActionsCard(
                        onActionSelected: _viewModel.onQuickActionSelected,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (width > 600) {
          // Tablet Layout (2 Columns)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      NextBestActionCard(nba: _viewModel.nextBestAction),
                      const SizedBox(height: 16),
                      TodayStudyPlanCard(plan: _viewModel.studyPlan),
                      const SizedBox(height: 16),
                      RecentConversationsCard(conversations: _viewModel.recentConversations),
                      const SizedBox(height: 16),
                      QuickActionsCard(
                        onActionSelected: _viewModel.onQuickActionSelected,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      StudyStreakCard(
                        streakDays: _viewModel.learningProfile?.studyStreakDays ?? 0,
                      ),
                      const SizedBox(height: 16),
                      TodayRevisionQueueCard(queue: _viewModel.revisionQueue),
                      const SizedBox(height: 16),
                      LearningProgressCard(profile: _viewModel.learningProfile),
                      const SizedBox(height: 16),
                      PdfLibraryCard(pdfs: _viewModel.pdfLibrary),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout (Single Column)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                StudyStreakCard(
                  streakDays: _viewModel.learningProfile?.studyStreakDays ?? 0,
                ),
                const SizedBox(height: 16),
                NextBestActionCard(nba: _viewModel.nextBestAction),
                const SizedBox(height: 16),
                TodayStudyPlanCard(plan: _viewModel.studyPlan),
                const SizedBox(height: 16),
                TodayRevisionQueueCard(queue: _viewModel.revisionQueue),
                const SizedBox(height: 16),
                LearningProgressCard(profile: _viewModel.learningProfile),
                const SizedBox(height: 16),
                QuickActionsCard(
                  onActionSelected: _viewModel.onQuickActionSelected,
                ),
                const SizedBox(height: 16),
                RecentConversationsCard(conversations: _viewModel.recentConversations),
                const SizedBox(height: 16),
                PdfLibraryCard(pdfs: _viewModel.pdfLibrary),
              ],
            ),
          );
        }
      },
    );
  }
}
