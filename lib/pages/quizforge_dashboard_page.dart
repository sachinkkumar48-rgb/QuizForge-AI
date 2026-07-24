import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';
import '../core/di/service_locator_init.dart';
import '../widgets/dashboard/dashboard_header_widget.dart';
import '../widgets/dashboard/plugin_module_grid_widget.dart';
import '../widgets/dashboard/quick_action_card_widget.dart';
import '../widgets/dashboard/recent_activity_card_widget.dart';
import '../widgets/dashboard/stat_summary_card_widget.dart';
import 'ai_mentor_panel_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'module_explorer_page.dart';
import 'pyq/pyq_dashboard_page.dart';
import 'settings_page.dart';

/// The central QuizForge AI Dashboard Screen featuring Material 3 UI,
/// responsive layout breakpoints, and reactive state binding via [DashboardController].
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
              child: CircularProgressIndicator(),
            );
          }

          if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? "An unexpected error occurred.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.refresh(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

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

                      // Metric Summary Cards
                      StatSummaryCardWidget(stats: state.stats),
                      const SizedBox(height: 24),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Main Column
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

                            // Right Side Column
                            Expanded(
                              flex: 2,
                              child: RecentActivityCardWidget(
                                activities: state.recentActivities,
                                activeSessionSourceName:
                                    state.activeSessionSourceName,
                                onResumeSessionTap: () =>
                                    _navigateTo(const HomePage()),
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
                          onResumeSessionTap: () =>
                              _navigateTo(const HomePage()),
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

  Widget _buildQuickActionGrid() {
    return QuickActionCardWidget(
      onGenerateQuizTap: () => _navigateTo(const HomePage()),
      onPyqTap: () => _navigateTo(const PyqDashboardPage()),
      onAiCoachTap: () => _navigateTo(const AIMentorPanelPage()),
      onPdfLibraryTap: () => _navigateTo(const LibraryPage()),
      onHistoryTap: () => _navigateTo(const HistoryPage()),
      onPluginHubTap: () => _navigateTo(const ModuleExplorerPage()),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
