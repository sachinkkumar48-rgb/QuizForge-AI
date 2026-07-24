import 'package:flutter/material.dart';

/// Quick Action Cards widget providing one-tap navigation to key app features.
class QuickActionCardWidget extends StatelessWidget {
  final VoidCallback onGenerateQuizTap;
  final VoidCallback onPyqTap;
  final VoidCallback onAiCoachTap;
  final VoidCallback onPdfLibraryTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onPluginHubTap;

  const QuickActionCardWidget({
    super.key,
    required this.onGenerateQuizTap,
    required this.onPyqTap,
    required this.onAiCoachTap,
    required this.onPdfLibraryTap,
    required this.onHistoryTap,
    required this.onPluginHubTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final isTablet = constraints.maxWidth > 600 && !isDesktop;
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: isDesktop ? 2.4 : (isTablet ? 2.2 : 2.5),
          children: [
            _buildActionCard(
              context: context,
              title: "Generate AI Quiz",
              subtitle: "Import PDF & create custom questions",
              icon: Icons.auto_awesome,
              color: Colors.deepPurple,
              onTap: onGenerateQuizTap,
            ),
            _buildActionCard(
              context: context,
              title: "UPSC PYQ Vault",
              subtitle: "Official Previous Year Questions",
              icon: Icons.history_edu,
              color: Colors.indigo,
              onTap: onPyqTap,
            ),
            _buildActionCard(
              context: context,
              title: "AI Learning Coach",
              subtitle: "Interactive tutoring & weakness analysis",
              icon: Icons.psychology,
              color: Colors.teal,
              onTap: onAiCoachTap,
            ),
            _buildActionCard(
              context: context,
              title: "PDF Library",
              subtitle: "Manage imported documents & notes",
              icon: Icons.folder_special,
              color: Colors.green,
              onTap: onPdfLibraryTap,
            ),
            _buildActionCard(
              context: context,
              title: "Attempt History",
              subtitle: "Review past test results & stats",
              icon: Icons.history,
              color: Colors.blue,
              onTap: onHistoryTap,
            ),
            _buildActionCard(
              context: context,
              title: "Plugin Hub",
              subtitle: "Explore active exam modules",
              icon: Icons.extension,
              color: Colors.amber.shade900,
              onTap: onPluginHubTap,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      color: color.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
