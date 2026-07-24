import 'package:flutter/material.dart';

import '../controllers/ai_mentor_controller.dart';
import '../controllers/ai_mentor_state.dart';
import '../core/di/service_locator_init.dart';
import '../widgets/dashboard/mentor/ai_mentor_card.dart';
import '../widgets/dashboard/mentor/recommendation_card.dart';
import '../widgets/dashboard/mentor/study_plan_card.dart';
import '../widgets/dashboard/mentor/weak_topics_card.dart';

/// The central AI Mentor Panel Screen featuring Material 3 UI,
/// responsive layout breakpoints, and reactive state binding via [AIMentorController].
class AIMentorPanelPage extends StatefulWidget {
  final AIMentorController? controller;

  const AIMentorPanelPage({
    super.key,
    this.controller,
  });

  @override
  State<AIMentorPanelPage> createState() => _AIMentorPanelPageState();
}

class _AIMentorPanelPageState extends State<AIMentorPanelPage> {
  late final AIMentorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? locate<AIMentorController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              "AI Mentor Panel",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Mentor Data",
            onPressed: () => _controller.refresh(),
          ),
        ],
      ),
      body: ValueListenableBuilder<AIMentorState>(
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

          final data = state.data;
          if (data == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => _controller.refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1000;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 36 : 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Mentor Card Header
                      AIMentorCard(
                        data: data,
                        onRefreshTap: () => _controller.refresh(),
                        onGeneratePlanTap: () =>
                            _controller.generateCustomStudyPlan(),
                      ),
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
                                  StudyPlanCard(
                                    studyPlan: data.studyPlan,
                                    onToggleCompletion: (id) =>
                                        _controller.toggleTaskCompletion(id),
                                  ),
                                  const SizedBox(height: 24),
                                  RecommendationCard(
                                    recommendations: data.recommendations,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Right Column
                            Expanded(
                              flex: 2,
                              child: WeakTopicsCard(
                                weakTopics: data.weakTopics,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        WeakTopicsCard(
                          weakTopics: data.weakTopics,
                        ),
                        const SizedBox(height: 24),
                        StudyPlanCard(
                          studyPlan: data.studyPlan,
                          onToggleCompletion: (id) =>
                              _controller.toggleTaskCompletion(id),
                        ),
                        const SizedBox(height: 24),
                        RecommendationCard(
                          recommendations: data.recommendations,
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
}
