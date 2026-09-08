import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';

/// Interactive Faculty & Admin Content Management Portal (TITAN-KO-045.0 P45).
///
/// Enables educators and administrators to author, validate, version, preview,
/// and publish curriculum-mapped questions and remedial lessons for learners.
class FacultyContentManagementPage extends StatefulWidget {
  final FacultyContentService? contentService;
  final CurriculumService? curriculumService;

  const FacultyContentManagementPage({
    super.key,
    this.contentService,
    this.curriculumService,
  });

  @override
  State<FacultyContentManagementPage> createState() =>
      _FacultyContentManagementPageState();
}

class _FacultyContentManagementPageState
    extends State<FacultyContentManagementPage> {
  late final FacultyContentService _service;
  late final CurriculumService _curriculumService;

  bool _isLoading = true;
  String _selectedExam = 'upsc_prelims_gs1';
  String _selectedSubject = 'indian_polity';
  String _selectedTopic = 'Fundamental Rights';
  final String _selectedObjective = 'lo_article_21_foundations';

  List<ManagedContentItem> _contentItems = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadContent();
  }

  void _initServices() {
    _curriculumService = widget.curriculumService ??
        CurriculumService(
          framework: CurriculumSeedData.buildUpscConstitutionalLawFramework(),
        );

    _service = widget.contentService ??
        FacultyContentService(
          contentRepository: InMemoryFacultyContentRepository(),
          curriculumService: _curriculumService,
          remedialRepository: InMemoryRemedialLessonRepository(),
        );
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.contentRepository.getAll(
        examId: _selectedExam,
        subjectId: _selectedSubject,
        topicId: _selectedTopic,
      );

      setState(() {
        _contentItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Faculty Content Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadContent,
          ),
          IconButton(
            key: const Key('create_content_header_button'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Content',
            onPressed: () => _openEditorDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCurriculumFilterBar(theme, colorScheme),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contentItems.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contentItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildContentCard(
                            _contentItems[index],
                            theme,
                            colorScheme,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_content_fab'),
        onPressed: () => _openEditorDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Content'),
      ),
    );
  }

  Widget _buildCurriculumFilterBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                'Curriculum Taxonomy Filter',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDropdown(
                key: const Key('exam_filter_dropdown'),
                label: 'Exam',
                value: _selectedExam,
                items: const [
                  DropdownMenuItem(
                    value: 'upsc_prelims_gs1',
                    child: Text('UPSC Prelims GS1'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedExam = val);
                    _loadContent();
                  }
                },
              ),
              _buildDropdown(
                key: const Key('subject_filter_dropdown'),
                label: 'Subject',
                value: _selectedSubject,
                items: const [
                  DropdownMenuItem(
                    value: 'indian_polity',
                    child: Text('Indian Polity'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSubject = val);
                    _loadContent();
                  }
                },
              ),
              _buildDropdown(
                key: const Key('topic_filter_dropdown'),
                label: 'Topic',
                value: _selectedTopic,
                items: const [
                  DropdownMenuItem(
                    value: 'Fundamental Rights',
                    child: Text('Fundamental Rights'),
                  ),
                  DropdownMenuItem(
                    value: 'Preamble & Basic Structure',
                    child: Text('Preamble & Basic Structure'),
                  ),
                  DropdownMenuItem(
                    value: 'Directive Principles',
                    child: Text('Directive Principles'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTopic = val);
                    _loadContent();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required Key key,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        key: key,
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 56, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            const Text(
              'No Content Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'No questions or lessons found for $_selectedTopic.\nTap "+ Create Content" to author new material.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('empty_state_create_button'),
              onPressed: () => _openEditorDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Content'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(
    ManagedContentItem item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isPublished = item.status == ContentLifecycleStatus.published;
    final isValidationFailed =
        item.status == ContentLifecycleStatus.validationFailed;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPublished
              ? Colors.green.withValues(alpha: 0.4)
              : (isValidationFailed
                  ? Colors.red.withValues(alpha: 0.4)
                  : Colors.grey.shade300),
          width: isPublished ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeBadge(item.contentType),
                const SizedBox(width: 8),
                _buildVersionBadge(item.version),
                const Spacer(),
                _buildStatusChip(item.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              item.contentType == ManagedContentType.question
                  ? item.prompt
                  : (item.summary.isNotEmpty ? item.summary : item.description),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.track_changes, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Objective: ${item.objectiveId}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 14),
                Icon(Icons.person_outline,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  item.authorName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (item.validationErrors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Validation Issues:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    ...item.validationErrors.map((err) => Text(
                          '• $err',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red.shade800),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: Key('preview_button_${item.id}'),
                  onPressed: () => _handlePreview(item),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: Key('edit_button_${item.id}'),
                  onPressed: () => _openEditorDialog(editingItem: item),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                if (isPublished)
                  OutlinedButton.icon(
                    key: Key('unpublish_button_${item.id}'),
                    onPressed: () => _handleUnpublish(item),
                    icon: const Icon(Icons.unpublished, size: 16),
                    label: const Text('Unpublish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                    ),
                  )
                else
                  FilledButton.icon(
                    key: Key('publish_button_${item.id}'),
                    onPressed: () => _handlePublish(item),
                    icon: const Icon(Icons.publish, size: 16),
                    label: const Text('Publish'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ManagedContentType type) {
    final (label, color) = switch (type) {
      ManagedContentType.question => ('QUESTION', Colors.indigo),
      ManagedContentType.remedialLesson => ('REMEDIAL LESSON', Colors.teal),
      ManagedContentType.learningMaterial => ('LEARNING MATERIAL', Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVersionBadge(int version) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'v$version',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ContentLifecycleStatus status) {
    final (label, color) = switch (status) {
      ContentLifecycleStatus.published => ('PUBLISHED', Colors.green),
      ContentLifecycleStatus.draft => ('DRAFT', Colors.orange),
      ContentLifecycleStatus.validationFailed => (
          'VALIDATION FAILED',
          Colors.red
        ),
      ContentLifecycleStatus.readyToPublish => ('READY', Colors.blue),
      ContentLifecycleStatus.unpublished => ('UNPUBLISHED', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handlePublish(ManagedContentItem item) async {
    try {
      await _service.publishContent(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully published "${item.title}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadContent();
    }
  }

  Future<void> _handleUnpublish(ManagedContentItem item) async {
    try {
      await _service.unpublishContent(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unpublished "${item.title}"'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      await _loadContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unpublish: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePreview(ManagedContentItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.preview, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Preview: ${item.title}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.contentType == ManagedContentType.question) ...[
                  Text(
                    item.prompt,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...item.options.asMap().entries.map((e) {
                    final letter = String.fromCharCode(65 + e.key);
                    final isCorrect = item.correctAnswer.trim().toLowerCase() ==
                            letter.toLowerCase() ||
                        item.correctAnswer.trim().toLowerCase() ==
                            e.value.trim().toLowerCase();
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$letter. ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(e.value)),
                          if (isCorrect)
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                        ],
                      ),
                    );
                  }),
                  if (item.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Explanation: ${item.explanation}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    'Summary:\n${item.summary}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Explanation:\n${item.lessonExplanation}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Provenance: ${item.provenance}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openEditorDialog({ManagedContentItem? editingItem}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _FacultyContentEditorDialog(
        service: _service,
        curriculumService: _curriculumService,
        initialExam: _selectedExam,
        initialSubject: _selectedSubject,
        initialTopic: _selectedTopic,
        initialObjective: _selectedObjective,
        existingItem: editingItem,
        onSaved: () {
          Navigator.pop(dialogCtx);
          _loadContent();
        },
      ),
    );
  }
}

class _FacultyContentEditorDialog extends StatefulWidget {
  final FacultyContentService service;
  final CurriculumService curriculumService;
  final String initialExam;
  final String initialSubject;
  final String initialTopic;
  final String initialObjective;
  final ManagedContentItem? existingItem;
  final VoidCallback onSaved;

  const _FacultyContentEditorDialog({
    required this.service,
    required this.curriculumService,
    required this.initialExam,
    required this.initialSubject,
    required this.initialTopic,
    required this.initialObjective,
    this.existingItem,
    required this.onSaved,
  });

  @override
  State<_FacultyContentEditorDialog> createState() =>
      _FacultyContentEditorDialogState();
}

class _FacultyContentEditorDialogState
    extends State<_FacultyContentEditorDialog> {
  late ManagedContentType _contentType;
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _promptController;
  late final TextEditingController _optAController;
  late final TextEditingController _optBController;
  late final TextEditingController _optCController;
  late final TextEditingController _optDController;
  late final TextEditingController _correctAnswerController;
  late final TextEditingController _explanationController;
  late final TextEditingController _provenanceController;
  late final TextEditingController _summaryController;
  late final TextEditingController _lessonExplanationController;

  String? _validationError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _contentType = item?.contentType ?? ManagedContentType.question;
    _idController = TextEditingController(
      text: item?.id ?? 'mc_content_${DateTime.now().millisecondsSinceEpoch}',
    );
    _titleController = TextEditingController(text: item?.title ?? '');
    _promptController = TextEditingController(text: item?.prompt ?? '');
    _optAController = TextEditingController(
        text: item != null && item.options.isNotEmpty ? item.options[0] : '');
    _optBController = TextEditingController(
        text: item != null && item.options.length > 1 ? item.options[1] : '');
    _optCController = TextEditingController(
        text: item != null && item.options.length > 2 ? item.options[2] : '');
    _optDController = TextEditingController(
        text: item != null && item.options.length > 3 ? item.options[3] : '');
    _correctAnswerController =
        TextEditingController(text: item?.correctAnswer ?? 'A');
    _explanationController =
        TextEditingController(text: item?.explanation ?? '');
    _provenanceController = TextEditingController(
      text: item?.provenance ?? 'TITAN Constitutional Law Faculty Board 2026',
    );
    _summaryController = TextEditingController(text: item?.summary ?? '');
    _lessonExplanationController =
        TextEditingController(text: item?.lessonExplanation ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _promptController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    _correctAnswerController.dispose();
    _explanationController.dispose();
    _provenanceController.dispose();
    _summaryController.dispose();
    _lessonExplanationController.dispose();
    super.dispose();
  }

  ManagedContentItem _buildCurrentItem() {
    final options = <String>[];
    if (_optAController.text.trim().isNotEmpty) {
      options.add(_optAController.text.trim());
    }
    if (_optBController.text.trim().isNotEmpty) {
      options.add(_optBController.text.trim());
    }
    if (_optCController.text.trim().isNotEmpty) {
      options.add(_optCController.text.trim());
    }
    if (_optDController.text.trim().isNotEmpty) {
      options.add(_optDController.text.trim());
    }

    final now = DateTime.now().toUtc();
    final existing = widget.existingItem;

    return ManagedContentItem(
      id: _idController.text.trim(),
      title: _titleController.text.trim(),
      examId: widget.initialExam,
      subjectId: widget.initialSubject,
      topicId: widget.initialTopic,
      objectiveId: widget.initialObjective,
      contentType: _contentType,
      authorId: 'faculty_admin',
      authorName: 'Faculty Administrator',
      provenance: _provenanceController.text.trim(),
      status: existing?.status ?? ContentLifecycleStatus.draft,
      version: existing?.version ?? 1,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      prompt: _promptController.text.trim(),
      options: options,
      correctAnswer: _correctAnswerController.text.trim(),
      explanation: _explanationController.text.trim(),
      summary: _summaryController.text.trim(),
      lessonExplanation: _lessonExplanationController.text.trim(),
    );
  }

  void _validate() {
    final item = _buildCurrentItem();
    final result = widget.service.validateContent(item);
    setState(() {
      if (!result.isValid) {
        _validationError = result.errors.join('\n');
      } else {
        _validationError = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isValid
              ? 'Validation passed! Ready to publish.'
              : 'Validation failed.',
        ),
        backgroundColor: result.isValid ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    try {
      final item = _buildCurrentItem();
      if (widget.existingItem != null) {
        await widget.service.updateDraft(item);
      } else {
        await widget.service.contentRepository.save(item);
      }
      widget.onSaved();
    } catch (e) {
      setState(() {
        _validationError = 'Failed to save: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _publish() async {
    setState(() => _isSaving = true);
    try {
      final item = _buildCurrentItem();
      if (widget.existingItem != null) {
        await widget.service.updateDraft(item);
      } else {
        await widget.service.contentRepository.save(item);
      }
      await widget.service.publishContent(item.id);
      widget.onSaved();
    } catch (e) {
      setState(() {
        _validationError = 'Publish failed: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingItem != null ? 'Edit Content' : 'Create New Content',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_validationError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _validationError!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                  ),
                ),
              DropdownButtonFormField<ManagedContentType>(
                initialValue: _contentType,
                decoration: const InputDecoration(
                  labelText: 'Content Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ManagedContentType.question,
                    child: Text('Practice Question'),
                  ),
                  DropdownMenuItem(
                    value: ManagedContentType.remedialLesson,
                    child: Text('Remedial Micro-Lesson'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _contentType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('editor_title_input'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_contentType == ManagedContentType.question) ...[
                TextField(
                  key: const Key('editor_prompt_input'),
                  controller: _promptController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question Prompt *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('editor_opt_a_input'),
                        controller: _optAController,
                        decoration: const InputDecoration(
                          labelText: 'Option A *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('editor_opt_b_input'),
                        controller: _optBController,
                        decoration: const InputDecoration(
                          labelText: 'Option B *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('editor_opt_c_input'),
                        controller: _optCController,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('editor_opt_d_input'),
                        controller: _optDController,
                        decoration: const InputDecoration(
                          labelText: 'Option D',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('editor_correct_ans_input'),
                  controller: _correctAnswerController,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer (Letter A/B/C/D or Text) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('editor_explanation_input'),
                  controller: _explanationController,
                  decoration: const InputDecoration(
                    labelText: 'Pedagogical Explanation',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                TextField(
                  key: const Key('editor_summary_input'),
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Conceptual Summary *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('editor_lesson_explanation_input'),
                  controller: _lessonExplanationController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Explanation *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('editor_provenance_input'),
                controller: _provenanceController,
                decoration: const InputDecoration(
                  labelText: 'Source Citation / Provenance *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('editor_validate_button'),
          onPressed: _validate,
          child: const Text('Validate'),
        ),
        OutlinedButton(
          key: const Key('editor_save_draft_button'),
          onPressed: _isSaving ? null : _saveDraft,
          child: const Text('Save Draft'),
        ),
        FilledButton(
          key: const Key('editor_publish_button'),
          onPressed: _isSaving ? null : _publish,
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: const Text('Publish'),
        ),
      ],
    );
  }
}
