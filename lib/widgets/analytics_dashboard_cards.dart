import 'package:flutter/material.dart';
import '../models/analytics_engine_models.dart';

/// Individual dashboard cards specified in requirements.
class AnalyticsDashboardCards extends StatelessWidget {
  final LearningInsightsModel insights;

  const AnalyticsDashboardCards({
    super.key,
    required this.insights,
  });

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(35),
                  radius: 20,
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weakSub = insights.weakSubjects.isNotEmpty
        ? insights.weakSubjects.first
        : 'None (Good Job!)';
    final strongSub = insights.strongSubjects.isNotEmpty
        ? insights.strongSubjects.first
        : 'Needs Practice';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            // 1. Overall Accuracy
            _buildCard(
              context: context,
              icon: Icons.pie_chart,
              title: 'Overall Accuracy',
              value: '${insights.overallAccuracy.toStringAsFixed(1)}%',
              subtitle: 'Average across all attempts',
              color: insights.overallAccuracy >= 60
                  ? Colors.green
                  : Colors.deepOrange,
            ),

            // 2. Today's Progress
            _buildCard(
              context: context,
              icon: Icons.today,
              title: "Today's Progress",
              value: '${insights.dailyQuestionsSolved}',
              subtitle: 'Questions solved today',
              color: Colors.blue,
            ),

            // 3. Current Streak
            _buildCard(
              context: context,
              icon: Icons.local_fire_department,
              title: 'Current Streak',
              value: '${insights.currentStreak} d',
              subtitle: 'Max: ${insights.longestStreak} days',
              color: Colors.orange,
            ),

            // 4. Questions Solved
            _buildCard(
              context: context,
              icon: Icons.check_circle,
              title: 'Questions Solved',
              value: '${insights.monthlyQuestionsSolved}',
              subtitle:
                  'This month (${insights.weeklyQuestionsSolved} this week)',
              color: Colors.teal,
            ),

            // 5. Pending Revision
            _buildCard(
              context: context,
              icon: Icons.replay,
              title: 'Pending Revision',
              value: '${insights.incorrectQuestionCount}',
              subtitle: '${insights.bookmarkCount} bookmarked',
              color: Colors.purple,
            ),

            // 6. Weak Subject
            _buildCard(
              context: context,
              icon: Icons.warning_amber,
              title: 'Weak Subject',
              value: weakSub,
              subtitle: '${insights.weakSubjects.length} subjects < 50%',
              color: Colors.red,
            ),

            // 7. Strong Subject
            _buildCard(
              context: context,
              icon: Icons.star,
              title: 'Strong Subject',
              value: strongSub,
              subtitle: '${insights.strongSubjects.length} subjects >= 70%',
              color: Colors.amber.shade800,
            ),
          ],
        );
      },
    );
  }
}
