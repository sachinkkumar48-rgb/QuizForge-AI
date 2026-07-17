import 'package:flutter/material.dart';
import '../models/quiz_analytics.dart';
import '../models/quiz_model.dart';

class AnalyticsDashboard extends StatelessWidget {
  final QuizAnalytics analytics;

  const AnalyticsDashboard({
    super.key,
    required this.analytics,
  });

  Color _getPerformanceColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return Colors.green;
      case PerformanceLevel.good:
        return Colors.blue;
      case PerformanceLevel.average:
        return Colors.orange;
      case PerformanceLevel.needsImprovement:
        return Colors.red;
    }
  }

  IconData _getPerformanceIcon(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return Icons.workspace_premium;
      case PerformanceLevel.good:
        return Icons.thumb_up;
      case PerformanceLevel.average:
        return Icons.trending_up;
      case PerformanceLevel.needsImprovement:
        return Icons.school;
    }
  }

  String _getPerformanceText(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return "Excellent";
      case PerformanceLevel.good:
        return "Good";
      case PerformanceLevel.average:
        return "Average";
      case PerformanceLevel.needsImprovement:
        return "Needs Improvement";
    }
  }

  Widget _buildPerformanceCard() {
    final color = _getPerformanceColor(analytics.performanceLevel);
    final icon = _getPerformanceIcon(analytics.performanceLevel);
    final text = _getPerformanceText(analytics.performanceLevel);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              icon,
              size: 72,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              "${analytics.score} / ${analytics.totalQuestions}",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorCard() {
    final color = _getPerformanceColor(analytics.performanceLevel);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Accuracy Progress",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: analytics.accuracy / 100,
                    strokeWidth: 10,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${analytics.accuracy.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Accuracy",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Colors.deepPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  "Attempt Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.check_circle,
              title: "Correct Questions",
              value: analytics.score.toString(),
              color: Colors.green,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.cancel,
              title: "Incorrect Questions",
              value: analytics.incorrect.toString(),
              color: Colors.red,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.edit_note,
              title: "Attempted Questions",
              value: analytics.attempted.toString(),
              color: Colors.blue,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.skip_next,
              title: "Skipped Questions",
              value: analytics.skipped.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timer, color: Colors.deepPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  "Time Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.hourglass_top,
              title: "Total Time Spent",
              value: analytics.formattedTimeSpent,
              color: Colors.blueGrey,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.speed,
              title: "Average Time / Question",
              value: analytics.formattedAverageTimePerQuestion,
              color: Colors.teal,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.hourglass_bottom,
              title: "Remaining Time",
              value: analytics.formattedRemainingTime,
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.grid_on, color: Colors.deepPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  "Question Status",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.circle_outlined,
              title: "Not Visited",
              value: (analytics.statusCounts[QuestionStatus.notVisited] ?? 0)
                  .toString(),
              color: Colors.grey,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.remove_red_eye_outlined,
              title: "Visited (Unanswered)",
              value: (analytics.statusCounts[QuestionStatus.visited] ?? 0)
                  .toString(),
              color: Colors.amber.shade700,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.check_circle_outline,
              title: "Answered",
              value: (analytics.statusCounts[QuestionStatus.answered] ?? 0)
                  .toString(),
              color: Colors.green,
            ),
            const Divider(height: 16),
            _buildSummaryItem(
              icon: Icons.bookmark_outline,
              title: "Marked for Review",
              value:
                  (analytics.statusCounts[QuestionStatus.markedForReview] ?? 0)
                      .toString(),
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        if (isLargeScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildPerformanceCard(),
                    const SizedBox(height: 16),
                    _buildIndicatorCard(),
                    const SizedBox(height: 16),
                    _buildTimeCard(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildAttemptCard(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildPerformanceCard(),
            const SizedBox(height: 16),
            _buildIndicatorCard(),
            const SizedBox(height: 16),
            _buildAttemptCard(),
            const SizedBox(height: 16),
            _buildTimeCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
          ],
        );
      },
    );
  }
}
