import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';

/// Module 1: Editorial Studio Dashboard displaying key metrics and status overview.
class DashboardScreen extends StatelessWidget {
  final EditorialStudioController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.metrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GARUDA Editorial Overview',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Internal Workspace • Role: ${controller.currentRole.label}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => controller.selectTab(2), // Jump to KO Manager
                icon: const Icon(Icons.add),
                label: const Text('Create Knowledge Object'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Key Metrics Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    title: 'Pending Evidence',
                    value: m.pendingEvidenceCount.toString(),
                    icon: Icons.inbox,
                    color: Colors.amber,
                    onTap: () => controller.selectTab(1),
                  ),
                  _MetricCard(
                    title: 'Pending Links',
                    value: m.pendingLinksCount.toString(),
                    icon: Icons.alt_route,
                    color: Colors.lightBlue,
                    onTap: () => controller.selectTab(3),
                  ),
                  _MetricCard(
                    title: 'Pending Publications',
                    value: m.pendingPublicationsCount.toString(),
                    icon: Icons.publish,
                    color: Colors.orange,
                    onTap: () => controller.selectTab(5),
                  ),
                  _MetricCard(
                    title: 'Published Today',
                    value: m.publishedTodayCount.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: () => controller.selectTab(5),
                  ),
                  _MetricCard(
                    title: 'Draft Objects',
                    value: m.draftObjectsCount.toString(),
                    icon: Icons.edit_document,
                    color: Colors.purple,
                    onTap: () => controller.selectTab(2),
                  ),
                  _MetricCard(
                    title: 'Recently Updated',
                    value: m.recentlyUpdatedCount.toString(),
                    icon: Icons.update,
                    color: Colors.teal,
                    onTap: () => controller.selectTab(2),
                  ),
                  _MetricCard(
                    title: 'Rejected Objects',
                    value: m.rejectedObjectsCount.toString(),
                    icon: Icons.cancel,
                    color: Colors.redAccent,
                    onTap: () => controller.selectTab(5),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          Text(
            'Recent Audit Log Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.auditLogs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = controller.auditLogs[index];
                return ListTile(
                  leading: const Icon(Icons.history_toggle_off),
                  title: Text('[${log.action}] ${log.objectId}'),
                  subtitle: Text('Editor: ${log.editor} • ${log.comment}'),
                  trailing: Text(
                    '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
