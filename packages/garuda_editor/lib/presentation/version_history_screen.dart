import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';
import '../domain/entities/knowledge_object_version.dart';

/// Module 5: Version History for comparing object snapshots and restoring past versions.
class VersionHistoryScreen extends StatefulWidget {
  final EditorialStudioController controller;

  const VersionHistoryScreen({super.key, required this.controller});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  KnowledgeObjectVersion? _selectedVersion;

  @override
  Widget build(BuildContext context) {
    final selectedObj = widget.controller.selectedObject;
    final versions = widget.controller.selectedObjectVersions;

    if (selectedObj == null) {
      return const Center(child: Text('Select a Knowledge Object to view Version History.'));
    }

    _selectedVersion ??= versions.isNotEmpty ? versions.last : null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version History: ${selectedObj.id}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current Active Version: v${selectedObj.currentVersion} • Total Snapshots: ${versions.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Row(
              children: [
                // Left Column: Version Timeline List
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor))),
                    child: ListView.separated(
                      itemCount: versions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final v = versions[index];
                        final isSel = _selectedVersion?.versionNumber == v.versionNumber;

                        return ListTile(
                          selected: isSel,
                          leading: CircleAvatar(child: Text('v${v.versionNumber}')),
                          title: Text(v.changeSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Editor: ${v.editor} • ${v.timestamp.toIso8601String().substring(0, 16)}'),
                          onTap: () {
                            setState(() {
                              _selectedVersion = v;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Right Column: Diff & Snapshot Preview
                Expanded(
                  flex: 6,
                  child: _selectedVersion == null
                      ? const Center(child: Text('Select a version snapshot'))
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Snapshot: Version ${_selectedVersion!.versionNumber}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.restore),
                                    label: const Text('Restore This Version'),
                                    onPressed: () {
                                      widget.controller.restoreVersion(selectedObj.id, _selectedVersion!.versionNumber);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Restored object to Version ${_selectedVersion!.versionNumber}')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Change Summary: ${_selectedVersion!.changeSummary}'),
                              Text('Editor Attribution: ${_selectedVersion!.editor}'),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              Text('Snapshot Payload Data', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _selectedVersion!.snapshot.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
