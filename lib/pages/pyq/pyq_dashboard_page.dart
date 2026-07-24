import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_analytics_model.dart';
import 'pyq_analytics_page.dart';
import 'pyq_attempt_page.dart';
import 'pyq_bookmarks_page.dart';
import 'pyq_incorrect_page.dart';
import 'pyq_mock_test_setup_page.dart';
import 'pyq_search_page.dart';
import 'pyq_smart_revision_page.dart';
import 'pyq_subject_topic_page.dart';
import 'pyq_year_selection_page.dart';

class PyqDashboardPage extends StatefulWidget {
  const PyqDashboardPage({super.key});

  @override
  State<PyqDashboardPage> createState() => _PyqDashboardPageState();
}

class _PyqDashboardPageState extends State<PyqDashboardPage> {
  final PyqController pyqController = PyqController();
  PyqAnalyticsModel? analytics;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await pyqController.init();
    final stats = await pyqController.getAnalytics();
    if (mounted) {
      setState(() {
        analytics = stats;
        isLoading = false;
      });
    }
  }

  Widget _buildHeaderCard(BuildContext context) {
    final totalQ = analytics?.totalQuestions ?? 0;
    final attemptedQ = analytics?.totalAttempted ?? 0;
    final accuracy = analytics?.overallAccuracyPercent ?? 0.0;
    final bookmarked = analytics?.totalBookmarked ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 24,
                child: Icon(Icons.history_edu, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "UPSC PYQ Hub",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Official CSE Prelims 2011–2025",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMetric("Total PYQs", "$totalQ"),
              _buildStatMetric("Attempted", "$attemptedQ"),
              _buildStatMetric("Accuracy", "${accuracy.toStringAsFixed(1)}%"),
              _buildStatMetric("Saved", "$bookmarked"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      color: color.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UPSC Previous Year Questions"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PyqSearchPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context),
                    const SizedBox(height: 24),

                    const Text(
                      "Practice Modules",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.calendar_today,
                      title: "Year-wise PYQs",
                      subtitle: "2025, 2024, 2023 ... down to 2011 papers",
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqYearSelectionPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.category,
                      title: "Subject-wise & Topics",
                      subtitle:
                          "Polity, History, Economy, Environment, Geography & S&T",
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqSubjectTopicPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.bookmark_added,
                      title: "Bookmarked Questions",
                      subtitle: "Important questions saved for quick revision",
                      color: Colors.amber.shade800,
                      badgeText: "${analytics?.totalBookmarked ?? 0}",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqBookmarksPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.assignment_late,
                      title: "Incorrect Questions",
                      subtitle: "Mistake Bank to fix your weak areas",
                      color: Colors.red.shade700,
                      badgeText: "${analytics?.totalIncorrectBank ?? 0}",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqIncorrectPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.tune,
                      title: "Smart Revision",
                      subtitle:
                          "Custom revision of mistakes, bookmarks & weak topics",
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqSmartRevisionPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.quiz,
                      title: "Mock Tests",
                      subtitle:
                          "25, 50, or 100 question timed tests across subjects",
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqMockTestSetupPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      context: context,
                      icon: Icons.bar_chart,
                      title: "Analytics & Progress",
                      subtitle: "Subject, Topic & Year-wise performance trends",
                      color: Colors.green.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PyqAnalyticsPage(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 20),

                    // Quick Practice All Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final questions =
                              await pyqController.getAllQuestions();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PyqAttemptPage(
                                questions: questions,
                                title: "All UPSC PYQs Practice",
                              ),
                            ),
                          ).then((_) => _loadDashboardData());
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Start Full PYQ Practice"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
