import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';
import '../domain/entities/editorial_status.dart';
import '../domain/entities/knowledge_object.dart';

/// Module 3: Knowledge Object Manager for creating, editing, previewing, and managing KOs.
class KnowledgeObjectManagerScreen extends StatefulWidget {
  final EditorialStudioController controller;

  const KnowledgeObjectManagerScreen({super.key, required this.controller});

  @override
  State<KnowledgeObjectManagerScreen> createState() => _KnowledgeObjectManagerScreenState();
}

class _KnowledgeObjectManagerScreenState extends State<KnowledgeObjectManagerScreen> {
  bool _isCreatingNew = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _topicController;
  late TextEditingController _subtopicController;
  late TextEditingController _conceptController;
  late TextEditingController _summaryController;
  late TextEditingController _contentController;
  late TextEditingController _referencesController;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.controller.selectedObject);
  }

  void _initControllers(KnowledgeObject? obj) {
    _idController = TextEditingController(text: obj?.id ?? 'KO-NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    _titleController = TextEditingController(text: obj?.title ?? '');
    _subjectController = TextEditingController(text: obj?.subject ?? 'Polity');
    _topicController = TextEditingController(text: obj?.topic ?? 'Governance');
    _subtopicController = TextEditingController(text: obj?.subtopic ?? '');
    _conceptController = TextEditingController(text: obj?.concept ?? '');
    _summaryController = TextEditingController(text: obj?.summary ?? '');
    _contentController = TextEditingController(text: obj?.content ?? '');
    _referencesController = TextEditingController(text: obj?.references.join(', ') ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    _subtopicController.dispose();
    _conceptController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _referencesController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final refs = _referencesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (_isCreatingNew) {
      final newObj = KnowledgeObject(
        id: _idController.text.trim(),
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
        subtopic: _subtopicController.text.trim(),
        concept: _conceptController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        references: refs,
        status: EditorialStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final res = await widget.controller.createKnowledgeObject(newObj);
      if (res.isValid) {
        setState(() {
          _isCreatingNew = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Knowledge Object created successfully!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.errors.first.message}')));
        }
      }
    } else if (widget.controller.selectedObject != null) {
      final updated = widget.controller.selectedObject!.copyWith(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
        subtopic: _subtopicController.text.trim(),
        concept: _conceptController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        references: refs,
        updatedAt: DateTime.now(),
      );

      final res = await widget.controller.updateKnowledgeObject(updated, 'Updated content and references in Editorial Manager');
      if (res.isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Knowledge Object updated!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final objects = widget.controller.objects;
    final selected = widget.controller.selectedObject;

    return Row(
      children: [
        // Left Column: List of Objects
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor))),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Knowledge Objects (${objects.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        tooltip: 'Create New Object',
                        onPressed: () {
                          setState(() {
                            _isCreatingNew = true;
                            _initControllers(null);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      final obj = objects[index];
                      final isSel = !_isCreatingNew && selected?.id == obj.id;

                      return ListTile(
                        selected: isSel,
                        title: Text(obj.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${obj.id} • ${obj.subject} • v${obj.currentVersion}'),
                        trailing: Chip(
                          label: Text(obj.status.displayName, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () {
                          setState(() {
                            _isCreatingNew = false;
                            widget.controller.selectKnowledgeObject(obj);
                            _initControllers(obj);
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

        // Right Column: Editor Form & Toolbar
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isCreatingNew ? 'Create New Knowledge Object' : 'Editing: ${selected?.id ?? ""}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            if (!_isCreatingNew && selected != null) ...[
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Duplicate Object',
                                onPressed: () {
                                  widget.controller.duplicateObject(selected.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: 'Delete Object',
                                onPressed: () {
                                  widget.controller.deleteObject(selected.id);
                                },
                              ),
                            ],
                            ElevatedButton.icon(
                              onPressed: _saveForm,
                              icon: const Icon(Icons.save),
                              label: Text(_isCreatingNew ? 'Create Draft' : 'Save Changes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _idController,
                            enabled: _isCreatingNew,
                            decoration: const InputDecoration(labelText: 'Object ID', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.isEmpty) ? 'ID required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.isEmpty) ? 'Subject required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.length < 3) ? 'Title must be >= 3 characters' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _topicController,
                            decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _subtopicController,
                            decoration: const InputDecoration(labelText: 'Subtopic', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _summaryController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Executive Summary', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Summary required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Content Body (Markdown Supported)', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Content body required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _referencesController,
                      decoration: const InputDecoration(labelText: 'Attached References (comma separated)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
