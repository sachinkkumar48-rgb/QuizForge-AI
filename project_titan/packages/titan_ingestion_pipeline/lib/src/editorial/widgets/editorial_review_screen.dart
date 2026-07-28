import 'package:flutter/material.dart';

import '../engine/editorial_workflow_engine.dart';
import '../models/editorial_models.dart';
import 'diff_viewer_widget.dart';
import 'quality_validation_widget.dart';

/// Material 3 Inspection & Review Screen for inline editing, diff view, quality validation, version history, and approval workflow.
class EditorialReviewScreen extends StatefulWidget {
  final EditorialAssetRecord record;
  final EditorialWorkflowEngine engine;
  final String currentUserId;
  final VoidCallback? onWorkflowCompleted;

  const EditorialReviewScreen({
    super.key,
    required this.record,
    required this.engine,
    required this.currentUserId,
    this.onWorkflowCompleted,
  });

  @override
  State<EditorialReviewScreen> createState() => _EditorialReviewScreenState();
}

class _EditorialReviewScreenState extends State<EditorialReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _changeSummaryController;
  late TextEditingController _commentInputController;
  late EditorialAssetRecord _activeRecord;
  bool _isSaving = false;

  // Simple Undo/Redo stack for inline editing
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _activeRecord = widget.record;
    _tabController = TabController(length: 5, vsync: this);
    _titleController =
        TextEditingController(text: _activeRecord.assets.lessonTitle);
    _contentController = TextEditingController(
        text: _activeRecord.assets.summaries.detailedSummary);
    _changeSummaryController =
        TextEditingController(text: 'Edited via Editorial Workspace');
    _commentInputController = TextEditingController();

    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    // Save state snapshot to undo stack if user pauses
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _changeSummaryController.dispose();
    _commentInputController.dispose();
    super.dispose();
  }

  void _applyUndo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_contentController.text);
      final prev = _undoStack.removeLast();
      _contentController.text = prev;
    }
  }

  void _applyRedo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_contentController.text);
      final next = _redoStack.removeLast();
      _contentController.text = next;
    }
  }

  Future<void> _saveEdits() async {
    _undoStack.add(_contentController.text);
    setState(() => _isSaving = true);
    final updated = await widget.engine.updateContent(
      recordId: _activeRecord.id,
      newTitle: _titleController.text.trim(),
      newDetailedSummary: _contentController.text.trim(),
      changeSummary: _changeSummaryController.text.trim(),
      editorId: widget.currentUserId,
    );
    setState(() {
      _activeRecord = updated;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version snapshot saved successfully!')),
      );
    }
  }

  Future<void> _approveAndPublish() async {
    setState(() => _isSaving = true);
    final updated = await widget.engine.approveAndPublish(
      _activeRecord.id,
      widget.currentUserId,
    );
    setState(() {
      _activeRecord = updated;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Asset Approved & Published to Knowledge Graph and Search Engine!')),
      );
      if (widget.onWorkflowCompleted != null) widget.onWorkflowCompleted!();
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Asset'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason / Feedback',
            hintText: 'Explain what needs correction...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      setState(() => _isSaving = true);
      final updated = await widget.engine.rejectAsset(
        _activeRecord.id,
        widget.currentUserId,
        reasonController.text.trim(),
      );
      setState(() {
        _activeRecord = updated;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Asset rejected and sent back for editorial revision.')),
        );
        if (widget.onWorkflowCompleted != null) widget.onWorkflowCompleted!();
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentInputController.text.trim();
    if (text.isEmpty) return;
    final updated = await widget.engine.addComment(
      recordId: _activeRecord.id,
      authorId: widget.currentUserId,
      authorName: 'User ${widget.currentUserId}',
      commentText: text,
    );
    _commentInputController.clear();
    setState(() => _activeRecord = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review: ${_activeRecord.assets.lessonTitle}'),
            Text(
              'ID: ${_activeRecord.id} • Status: ${_activeRecord.status.label}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Inline Edit & Diff'),
            Tab(icon: Icon(Icons.dataset), text: '9 Asset Breakdown'),
            Tab(icon: Icon(Icons.fact_check), text: 'Quality Validation'),
            Tab(icon: Icon(Icons.history), text: 'Version Control'),
            Tab(icon: Icon(Icons.account_tree), text: 'Provenance & Audit'),
          ],
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEditAndDiffTab(theme, colorScheme),
                _buildAssetBreakdownTab(theme, colorScheme),
                _buildQualityValidationTab(),
                _buildVersionControlTab(theme),
                _buildProvenanceAndAuditTab(theme, colorScheme),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Draft Snapshot'),
                onPressed: _saveEdits,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Reject Asset',
                    style: TextStyle(color: Colors.red)),
                onPressed: _reject,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Approve & Publish'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                onPressed: _approveAndPublish,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditAndDiffTab(ThemeData theme, ColorScheme colorScheme) {
    final originalText = _activeRecord.versionHistory.first.snapshotContent;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Lesson Title',
                    border: OutlineInputBorder(),
                  ),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _undoStack.isNotEmpty ? _applyUndo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _redoStack.isNotEmpty ? _applyRedo : null,
                tooltip: 'Redo',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Rich Text / Markdown Editor',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _changeSummaryController,
            decoration: const InputDecoration(
              labelText: 'Change Summary / Revision Note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          DiffViewerWidget(
            originalText: originalText,
            revisedText: _contentController.text,
            originalLabel: 'Original AI Generation (v1.0.0)',
            revisedLabel: 'Current Editorial Revision',
          ),
        ],
      ),
    );
  }

  Widget _buildAssetBreakdownTab(ThemeData theme, ColorScheme colorScheme) {
    final assets = _activeRecord.assets;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('9 Learning Asset Categories',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ExpansionTile(
          leading: const Icon(Icons.menu_book, color: Colors.blue),
          title: const Text('1. Lessons'),
          subtitle: Text(assets.lessonTitle),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(assets.summaries.detailedSummary),
            ),
          ],
        ),
        ExpansionTile(
          leading: const Icon(Icons.short_text, color: Colors.green),
          title: const Text('2. Summaries (30s, 5m, Detailed)'),
          subtitle: Text('30s: ${assets.summaries.summary30s}'),
          children: [
            ListTile(
                title: const Text('30-Second Summary'),
                subtitle: Text(assets.summaries.summary30s)),
            ListTile(
                title: const Text('5-Minute Summary'),
                subtitle: Text(assets.summaries.summary5m)),
            ListTile(
                title: const Text('Detailed Summary'),
                subtitle: Text(assets.summaries.detailedSummary)),
          ],
        ),
        ExpansionTile(
          leading: const Icon(Icons.style, color: Colors.purple),
          title: Text('3. Flashcards (${assets.flashcards.length} Cards)'),
          children: assets.flashcards
              .map((f) => ListTile(
                    title: Text(f.front),
                    subtitle: Text(
                        'Back: ${f.back} • Hint: ${f.hint} • Difficulty: ${f.difficulty}'),
                  ))
              .toList(),
        ),
        ExpansionTile(
          leading: const Icon(Icons.quiz, color: Colors.orange),
          title: Text('4. MCQs & Questions (${assets.questions.length} Items)'),
          children: assets.questions
              .map((q) => ListTile(
                    title: Text(q.stem),
                    subtitle: Text(
                        'Type: ${q.type.name} • Options: ${q.options.join(', ')}'),
                  ))
              .toList(),
        ),
        ExpansionTile(
          leading: const Icon(Icons.note_alt, color: Colors.teal),
          title: const Text('5. Revision Notes'),
          children: [
            ListTile(
                title: const Text('One Page Notes'),
                subtitle: Text(assets.revisionNotes.onePageNotes)),
            ListTile(
                title: const Text('Last Minute Notes'),
                subtitle: Text(assets.revisionNotes.lastMinuteNotes)),
            ListTile(
                title: const Text('Exam Notes'),
                subtitle: Text(assets.revisionNotes.examNotes)),
          ],
        ),
        ExpansionTile(
          leading: const Icon(Icons.alt_route, color: Colors.indigo),
          title: const Text('6. Mind Maps'),
          subtitle: Text('Branches: ${assets.mindMap.branches.join(', ')}'),
          children: assets.mindMap.nodes
              .map((n) => ListTile(
                    title: Text('Level ${n.level}: ${n.label}'),
                    subtitle:
                        Text('ID: ${n.id} • Parent: ${n.parentId ?? "Root"}'),
                  ))
              .toList(),
        ),
        ExpansionTile(
          leading: const Icon(Icons.smart_toy, color: Colors.amber),
          title: const Text('7. AI Tutor Context'),
          children: [
            ListTile(
                title: const Text('Context Prompt'),
                subtitle: Text(assets.tutorContext.contextPrompt)),
            ListTile(
                title: const Text('Misconceptions'),
                subtitle: Text(assets.tutorContext.misconceptions.join(' | '))),
            ListTile(
                title: const Text('Analogies'),
                subtitle: Text(assets.tutorContext.analogies.join(' | '))),
          ],
        ),
        ExpansionTile(
          leading: const Icon(Icons.flag, color: Colors.red),
          title: const Text('8. Learning Objectives & Metadata'),
          children: [
            ListTile(
                title: const Text('Objectives'),
                subtitle: Text(
                    assets.objectivesMetadata.learningObjectives.join(', '))),
            ListTile(
                title: const Text('Prerequisites'),
                subtitle:
                    Text(assets.objectivesMetadata.prerequisites.join(', '))),
            ListTile(
              title: const Text('Bloom Taxonomy Tags'),
              subtitle: Text(assets.objectivesMetadata.bloomTags
                  .map((b) => b.name)
                  .join(', ')),
            ),
          ],
        ),
        ExpansionTile(
          leading: const Icon(Icons.translate, color: Colors.deepOrange),
          title: Text(
              '9. Glossary & Concept Links (${_activeRecord.glossaryItems.length} Terms)'),
          children: _activeRecord.glossaryItems.isEmpty
              ? [const ListTile(title: Text('No custom glossary terms added.'))]
              : _activeRecord.glossaryItems
                  .map((g) => ListTile(
                        title: Text(g.term),
                        subtitle: Text('${g.definition} (Domain: ${g.domain})'),
                      ))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildQualityValidationTab() {
    return QualityValidationWidget(
      checklist: _activeRecord.validationChecklist,
      score: _activeRecord.qualityScore,
      onChecklistChanged: (updatedChecklist) async {
        final updatedRecord = await widget.engine.updateValidationChecklist(
          recordId: _activeRecord.id,
          checklist: updatedChecklist,
          actorId: widget.currentUserId,
        );
        setState(() => _activeRecord = updatedRecord);
      },
    );
  }

  Widget _buildVersionControlTab(ThemeData theme) {
    final versions = _activeRecord.versionHistory;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: versions.length,
      itemBuilder: (context, index) {
        final ver = versions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(child: Text(ver.versionNumber)),
            title:
                Text('Version ${ver.versionNumber}: ${ver.changeLogSummary}'),
            subtitle: Text(
                'Author: ${ver.authorId} • Timestamp: ${ver.timestamp.toLocal().toString().split('.')[0]}'),
            trailing: TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Rollback'),
              onPressed: () async {
                final updated = await widget.engine.rollbackToVersion(
                  _activeRecord.id,
                  ver.versionId,
                  widget.currentUserId,
                );
                setState(() {
                  _activeRecord = updated;
                  _titleController.text = updated.assets.lessonTitle;
                  _contentController.text =
                      updated.assets.summaries.detailedSummary;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Rolled back content to version ${ver.versionNumber}')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProvenanceAndAuditTab(ThemeData theme, ColorScheme colorScheme) {
    final prov = _activeRecord.provenance;
    final audit = _activeRecord.auditLog;
    final comments = _activeRecord.comments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Provenance & Origin Lineage',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                    title: const Text('Knowledge Object ID'),
                    subtitle: Text(prov.knowledgeObjectId)),
                ListTile(
                    title: const Text('Source Document ID'),
                    subtitle: Text(prov.sourceDocumentId)),
                ListTile(
                    title: const Text('AI Generation Model'),
                    subtitle: Text(
                        '${prov.generationModel} (v${prov.generationVersion})')),
                ListTile(
                    title: const Text('Editor ID'),
                    subtitle: Text(prov.editorId)),
                ListTile(
                    title: const Text('Reviewer ID'),
                    subtitle: Text(prov.reviewerId)),
                ListTile(
                  title: const Text('Approval Date'),
                  subtitle: Text(prov.approvalDate?.toIso8601String() ??
                      'Pending Senior Approval'),
                ),
                ListTile(
                    title: const Text('Published Version'),
                    subtitle: Text(prov.publishedVersion)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Internal Comments & Review Notes',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentInputController,
                  decoration: const InputDecoration(
                    hintText: 'Add internal reviewer comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Post'),
                onPressed: _addComment,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...comments.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.comment),
                  title: Text(c.commentText),
                  subtitle: Text(
                      'By ${c.authorName} (${c.authorId}) • ${c.createdAt.toLocal().toString().split('.')[0]}'),
                ),
              )),
          const SizedBox(height: 24),
          Text('Audit Log Trail',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...audit.map((a) => ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: Text('${a.fromStatus.label} ➔ ${a.toStatus.label}'),
                subtitle: Text(
                    'Actor: ${a.actorId} (${a.actorRole.name}) • Note: ${a.notes} • ${a.timestamp.toLocal().toString().split('.')[0]}'),
              )),
        ],
      ),
    );
  }
}
