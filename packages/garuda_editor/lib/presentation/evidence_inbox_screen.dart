import 'package:flutter/material.dart';
import 'package:garuda_evidence/garuda_evidence.dart';
import '../application/editorial_studio_controller.dart';

/// Module 2: Evidence Inbox with Split View for review, metadata inspection, and comments.
class EvidenceInboxScreen extends StatefulWidget {
  final EditorialStudioController controller;

  const EvidenceInboxScreen({super.key, required this.controller});

  @override
  State<EvidenceInboxScreen> createState() => _EvidenceInboxScreenState();
}

class _EvidenceInboxScreenState extends State<EvidenceInboxScreen> {
  EvidenceObject? _selectedEvidence;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.evidenceInbox.isNotEmpty) {
      _selectedEvidence = widget.controller.evidenceInbox.first;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = widget.controller.evidenceInbox;

    if (inbox.isEmpty) {
      return const Center(
        child: Text('Evidence Inbox is empty. All items reviewed!'),
      );
    }

    _selectedEvidence ??= inbox.first;

    return Row(
      children: [
        // Left Column: List of Evidence Objects
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Incoming Evidence Inbox (${inbox.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: inbox.length,
                    itemBuilder: (context, index) {
                      final ev = inbox[index];
                      final isSelected = _selectedEvidence?.id == ev.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        leading: CircleAvatar(
                          child: Text(ev.sourceType.name[0].toUpperCase()),
                        ),
                        title: Text(ev.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${ev.sourceName} • ${ev.category}'),
                        onTap: () {
                          setState(() {
                            _selectedEvidence = ev;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: Split View Evidence Detail Panel
        Expanded(
          flex: 6,
          child: _selectedEvidence == null
              ? const Center(child: Text('Select an evidence item to review'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(_selectedEvidence!.sourceType.name.toUpperCase()),
                              avatar: const Icon(Icons.source, size: 16),
                            ),
                            Text(
                              'Retrieved: ${_selectedEvidence!.retrievedDate.toIso8601String().substring(0, 10)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedEvidence!.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Authority: ${_selectedEvidence!.authority.name} (${_selectedEvidence!.authority.jurisdiction})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Executive Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_selectedEvidence!.summary),
                        const SizedBox(height: 16),
                        Text('Original Source URL', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        SelectableText(
                          _selectedEvidence!.originalUrl,
                          style: const TextStyle(color: Colors.blue, textBaseline: TextBaseline.alphabetic),
                        ),
                        const SizedBox(height: 16),
                        Text('Extracted Keywords & Links', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: _selectedEvidence!.keywords
                              .map((k) => Chip(label: Text(k), backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Editorial Comment / Review Note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () {
                                widget.controller.approveEvidence(_selectedEvidence!.id, comment: _commentController.text);
                                _commentController.clear();
                                setState(() {
                                  _selectedEvidence = null;
                                });
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Approve Evidence'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              onPressed: () {
                                widget.controller.rejectEvidence(_selectedEvidence!.id, reason: _commentController.text);
                                _commentController.clear();
                                setState(() {
                                  _selectedEvidence = null;
                                });
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Reject Evidence'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
