import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';

/// Module 4: Link Review for inspecting and approving/rejecting rule-suggested KnowledgeLinks.
class LinkReviewScreen extends StatelessWidget {
  final EditorialStudioController controller;

  const LinkReviewScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final links = controller.pendingLinks;

    if (links.isEmpty) {
      return const Center(
        child: Text('No pending links in editorial review queue!'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link Review Queue (${links.length})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Review rule-suggested Knowledge Graph relations before committing to graph.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: links.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final link = links[index];
                final confidencePercent = (link.confidenceScore * 100).toInt();

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.hub, size: 16),
                              label: Text(link.relationshipType.name.toUpperCase()),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: confidencePercent >= 90 ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: confidencePercent >= 90 ? Colors.green : Colors.amber),
                              ),
                              child: Text(
                                'Confidence: $confidencePercent%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: confidencePercent >= 90 ? Colors.green : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Source -> Target Connection
                        Row(
                          children: [
                            Expanded(
                              child: _NodeBox(
                                title: link.sourceObject.name,
                                id: link.sourceObject.id,
                                type: link.sourceObject.nodeType.name,
                                isSource: true,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(Icons.arrow_forward, size: 28),
                            ),
                            Expanded(
                              child: _NodeBox(
                                title: link.targetObject.name,
                                id: link.targetObject.id,
                                type: link.targetObject.nodeType.name,
                                isSource: false,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text('Deterministic Match Reason: ${link.reason}', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () => controller.approveLink(link.id),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve Link'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              onPressed: () => controller.rejectLink(link.id, reason: 'Rejected by Editor'),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject Link'),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _NodeBox extends StatelessWidget {
  final String title;
  final String id;
  final String type;
  final bool isSource;

  const _NodeBox({
    required this.title,
    required this.id,
    required this.type,
    required this.isSource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isSource ? 'SOURCE NODE' : 'TARGET NODE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('$id • $type', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
