import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_analytics_model.dart';
import '../../widgets/analytics/analytics_dashboard_components.dart';

class PyqAnalyticsPage extends StatefulWidget {
  const PyqAnalyticsPage({super.key});

  @override
  State<PyqAnalyticsPage> createState() => _PyqAnalyticsPageState();
}

class _PyqAnalyticsPageState extends State<PyqAnalyticsPage> {
  final PyqController pyqController = PyqController();
  PyqAnalyticsModel? analytics;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final data = await pyqController.getAnalytics();
    if (mounted) {
      setState(() {
        analytics = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = analytics;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Performance Analytics Engine"),
        centerTitle: true,
      ),
      body: isLoading || a == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Daily & Weekly Streaks Header
                    StreakHeaderCard(streakMetrics: a.streakMetrics),
                    const SizedBox(height: 20),

                    // 2. 4-KPI Overview Grid (Accuracy, Speed, Consistency, Retention)
                    KpiOverviewGrid(analytics: a),
                    const SizedBox(height: 20),

                    // 3. Strengths & Weaknesses Spectrum
                    StrengthsWeaknessesCard(
                      weakSubjects: a.weakSubjects,
                      strongSubjects: a.strongSubjects,
                    ),
                    const SizedBox(height: 20),

                    // 4. Detailed Trend Analysis Tabs (Subject, Topic, Year, Difficulty)
                    TrendAnalysisTabs(analytics: a),
                    const SizedBox(height: 20),

                    // 5. Revision & Monthly Progress Tracker
                    RevisionMonthlyTracker(
                      revisionMetrics: a.revisionMetrics,
                      monthlyMetrics: a.monthlyMetrics,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
