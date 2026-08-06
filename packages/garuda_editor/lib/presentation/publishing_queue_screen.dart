import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';
import '../domain/entities/editorial_status.dart';

/// Module 6: Publishing Queue managing lifecycle states (Draft, In Review, Approved, Published, Archived, Rejected).
class PublishingQueueScreen extends StatefulWidget {
  final EditorialStudioController controller;

  const PublishingQueueScreen({super.key, required this.controller});

  @override
  State<PublishingQueueScreen> createState() => _PublishingQueueScreenState();
}

class _PublishingQueueScreenState extends State<PublishingQueueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<EditorialStatus> _statusTabs = [
    EditorialStatus.reviewPending,
    EditorialStatus.approved,
    EditorialStatus.published,
    EditorialStatus.draft,
    EditorialStatus.rejected,
    EditorialStatus.archived,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((s) => Tab(text: s.displayName)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _statusTabs.map((status) {
              final items = widget.controller.objects.where((o) => o.status == status).toList();

              if (items.isEmpty) {
                return Center(child: Text('No Knowledge Objects in "${status.displayName}" status.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final obj = items[index];

                  return Card(
                    child: ListTile(
                      title: Text(obj.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${obj.id} • ${obj.subject} • Updated: ${obj.updatedAt.toIso8601String().substring(0, 10)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status == EditorialStatus.reviewPending || status == EditorialStatus.draft) ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              onPressed: () => widget.controller.changeObjectStatus(obj.id, EditorialStatus.approved, comment: 'Approved for publishing'),
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (status == EditorialStatus.approved) ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () => widget.controller.changeObjectStatus(obj.id, EditorialStatus.published, comment: 'Published to Knowledge Graph'),
                              child: const Text('Publish Now'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (status != EditorialStatus.rejected) ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              onPressed: () => widget.controller.changeObjectStatus(obj.id, EditorialStatus.rejected, comment: 'Rejected in Publishing Queue'),
                              child: const Text('Reject'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
