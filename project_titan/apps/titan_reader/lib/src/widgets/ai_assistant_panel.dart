library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_reading_provider.dart';
import '../domain/ai_reading_errors.dart';
import '../domain/entities/ai_reading_models.dart';
import '../domain/entities/ai_reading_task.dart';
import '../domain/entities/reader_note.dart';
import '../domain/word_normalizer.dart';
import '../providers/ai_reading_providers.dart';
import '../providers/dictionary_providers.dart';
import '../providers/reader_providers.dart';
import 'ai_settings_dialog.dart';
import 'dictionary_panel.dart';

/// Modal bottom sheet providing intelligent AI Reading Assistance.
class AIAssistantPanel extends ConsumerStatefulWidget {
  final String text;
  final AIReadingTask initialTask;
  final String? documentId;
  final String? documentName;
  final int? pageNumber;
  final void Function(int pageNumber)? onNavigateToPage;

  const AIAssistantPanel({
    super.key,
    required this.text,
    this.initialTask = AIReadingTask.explain,
    this.documentId,
    this.documentName,
    this.pageNumber,
    this.onNavigateToPage,
  });

  @override
  ConsumerState<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends ConsumerState<AIAssistantPanel> {
  late AIReadingTask _currentTask;
  late TextEditingController _questionController;
  late ScrollController _scrollController;

  AIContextScope _contextScope = AIContextScope.selection;
  final AISimplifyLevel _simplifyLevel = AISimplifyLevel.simple;
  final AISummaryLength _summaryLength = AISummaryLength.medium;

  String _accumulatedResponse = '';
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _errorMessage;
  List<SourceReference> _sources = const [];
  List<AIFlashcard> _flashcards = const [];
  List<String> _keyTerms = const [];

  AICancellationToken? _cancelToken;
  StreamSubscription<String>? _streamSub;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.initialTask;
    _questionController = TextEditingController();
    _scrollController = ScrollController();
    _runTask();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _streamSub?.cancel();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runTask({bool forceRefresh = false}) async {
    _cancelToken?.cancel();
    _streamSub?.cancel();

    setState(() {
      _isLoading = true;
      _isStreaming = false;
      _accumulatedResponse = '';
      _errorMessage = null;
      _sources = const [];
      _flashcards = const [];
      _keyTerms = const [];
      _cancelToken = AICancellationToken();
    });

    final service = ref.read(aiReadingServiceProvider);
    final request = AIReadingRequest(
      task: _currentTask,
      text: widget.text,
      contextScope: _contextScope,
      documentId: widget.documentId,
      documentName: widget.documentName,
      pageNumber: widget.pageNumber,
      summaryLength: _summaryLength,
      simplifyLevel: _simplifyLevel,
      userQuestion: _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : null,
    );

    try {
      if (forceRefresh) {
        // Direct non-cached generation
        final res = await service.processTask(
          request,
          cancelToken: _cancelToken,
          useCache: false,
        );
        if (!mounted) return;
        setState(() {
          _accumulatedResponse = res.text;
          _sources = res.sources;
          _flashcards = res.flashcards;
          _keyTerms = res.extractedKeyTerms;
          _isLoading = false;
        });
      } else {
        // Streaming task execution
        setState(() {
          _isLoading = false;
          _isStreaming = true;
        });

        final stream = service.streamTask(
          request,
          cancelToken: _cancelToken,
        );

        final buffer = StringBuffer();
        _streamSub = stream.listen(
          (chunk) {
            if (!mounted) return;
            buffer.write(chunk);
            setState(() {
              _accumulatedResponse = buffer.toString();
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _isStreaming = false;
              _isLoading = false;
              _errorMessage = error.toString();
            });
          },
          onDone: () async {
            if (!mounted) return;
            // Parse structured items after stream concludes
            final full = buffer.toString();
            final res = await service.processTask(request, useCache: true);
            setState(() {
              _isStreaming = false;
              _isLoading = false;
              _sources = res.sources;
              _flashcards = res.flashcards;
              _keyTerms = res.extractedKeyTerms;
              if (_accumulatedResponse.isEmpty) {
                _accumulatedResponse = res.text.isNotEmpty ? res.text : full;
              }
            });
          },
          cancelOnError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _errorMessage = e is AIReadingException ? e.message : e.toString();
      });
    }
  }

  void _cancel() {
    _cancelToken?.cancel();
    _streamSub?.cancel();
    setState(() {
      _isLoading = false;
      _isStreaming = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI response generation cancelled.')),
    );
  }

  Future<void> _copy(String content, String feedback) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(feedback)),
    );
  }

  Future<void> _saveToNotes() async {
    if (widget.documentId == null || _accumulatedResponse.isEmpty) return;
    final noteService = ref.read(noteServiceProvider);
    final now = DateTime.now();
    await noteService.addNote(
      ReaderNote(
        id: noteService.nextId(),
        documentId: widget.documentId!,
        pageNumber: widget.pageNumber ?? 1,
        title: 'AI ${_currentTask.name.toUpperCase()} Summary',
        content: _accumulatedResponse,
        selectedText: widget.text.isNotEmpty ? widget.text : null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved AI response to Reader Notes.')),
    );
  }

  Future<void> _saveWordToVocabulary(String rawWord) async {
    final word = WordNormalizer.singleWordFrom(rawWord);
    if (word == null) return;
    final service = ref.read(vocabularyServiceProvider);
    await service.ensureLoaded();
    await service.saveWord(
      rawWord: word,
      at: DateTime.now(),
      sourceDocumentId: widget.documentId,
      sourceDocumentName: widget.documentName,
      sourcePage: widget.pageNumber,
      selectedText: widget.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "$word" to My Vocabulary.')),
    );
  }

  void _openDictionaryForWord(String rawWord) {
    final word = WordNormalizer.singleWordFrom(rawWord);
    if (word == null) return;
    showDictionaryPanel(
      context,
      word: word,
      documentId: widget.documentId,
      documentName: widget.documentName,
      pageNumber: widget.pageNumber,
      selectedText: widget.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final config = ref.watch(aiConfigStateProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, sheetScrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('AI Assistant', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: config.localFirst
                          ? scheme.primaryContainer
                          : scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      config.activeModelId,
                      key: const Key('ai-panel-model-badge'),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('ai-panel-settings-button'),
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    tooltip: 'AI Settings',
                    onPressed: () => showAISettingsDialog(context),
                  ),
                ],
              ),
            ),

            // Task Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _taskChip('Explain', AIReadingTask.explain),
                  const SizedBox(width: 8),
                  _taskChip('Simplify', AIReadingTask.simplify),
                  const SizedBox(width: 8),
                  _taskChip('Summarize', AIReadingTask.summarize),
                  const SizedBox(width: 8),
                  _taskChip('Ask AI (Q&A)', AIReadingTask.askQuestion),
                  const SizedBox(width: 8),
                  _taskChip('Key Points', AIReadingTask.keyPoints),
                  const SizedBox(width: 8),
                  _taskChip('Flashcards', AIReadingTask.generateFlashcards),
                ],
              ),
            ),

            // Sub-options row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('Context: ', style: theme.textTheme.labelSmall),
                  DropdownButton<AIContextScope>(
                    key: const Key('ai-context-scope-dropdown'),
                    value: _contextScope,
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: AIContextScope.selection,
                        child: Text('Selected Text'),
                      ),
                      DropdownMenuItem(
                        value: AIContextScope.page,
                        child: Text('Current Page'),
                      ),
                      DropdownMenuItem(
                        value: AIContextScope.document,
                        child: Text('Entire Document (RAG)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _contextScope = val);
                        _runTask();
                      }
                    },
                  ),
                  const Spacer(),
                  if (_isStreaming || _isLoading)
                    TextButton.icon(
                      key: const Key('ai-cancel-button'),
                      onPressed: _cancel,
                      icon: const Icon(Icons.stop, size: 16, color: Colors.red),
                      label: const Text('Stop',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),

            // Q&A Question input (if in askQuestion mode)
            if (_currentTask == AIReadingTask.askQuestion)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('ai-question-input'),
                        controller: _questionController,
                        decoration: const InputDecoration(
                          hintText: 'Ask a question about this document…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _runTask(forceRefresh: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('ai-question-submit-button'),
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () => _runTask(forceRefresh: true),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Main Response View
            Expanded(
              child: ListView(
                controller: sheetScrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            key: Key('ai-loading-indicator')),
                      ),
                    )
                  else if (_errorMessage != null)
                    Card(
                      color: scheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _errorMessage!,
                          key: const Key('ai-error-message'),
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    )
                  else ...[
                    // Text response display
                    SelectableText(
                      _accumulatedResponse.isNotEmpty
                          ? _accumulatedResponse
                          : 'No response available.',
                      key: const Key('ai-response-text'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),

                    // Key terms chips
                    if (_keyTerms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Identified Key Terms:',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _keyTerms.map((term) {
                          return PopupMenuButton<String>(
                            tooltip: 'Options for $term',
                            onSelected: (action) {
                              if (action == 'dict') {
                                _openDictionaryForWord(term);
                              } else if (action == 'save') {
                                _saveWordToVocabulary(term);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'dict',
                                child: ListTile(
                                  leading:
                                      Icon(Icons.menu_book_outlined, size: 20),
                                  title: Text('Lookup in Dictionary'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'save',
                                child: ListTile(
                                  leading: Icon(Icons.bookmark_add_outlined,
                                      size: 20),
                                  title: Text('Save to Vocabulary'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                            child: Chip(
                              avatar: const Icon(Icons.menu_book_outlined,
                                  size: 16),
                              label: Text(term),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Source references (RAG citations)
                    if (_sources.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Sources & Citations:',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (final src in _sources)
                        Card(
                          key: ValueKey('ai-source-ref-${src.pageNumber}'),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.bookmark_outline),
                            title: Text('Page ${src.pageNumber}'),
                            subtitle: Text(
                              src.excerpt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: widget.onNavigateToPage != null
                                ? TextButton(
                                    onPressed: () {
                                      widget.onNavigateToPage!(src.pageNumber);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Jump'),
                                  )
                                : null,
                          ),
                        ),
                    ],

                    // Study Flashcards display
                    if (_flashcards.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Generated Flashcards (${_flashcards.length}):',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (final fc in _flashcards)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Q: ${fc.front}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('A: ${fc.back}'),
                              ],
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),

                    // Actions row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          key: const Key('ai-copy-button'),
                          onPressed: _accumulatedResponse.isNotEmpty
                              ? () => _copy(
                                  _accumulatedResponse, 'AI response copied.')
                              : null,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('ai-save-note-button'),
                          onPressed: _accumulatedResponse.isNotEmpty
                              ? _saveToNotes
                              : null,
                          icon: const Icon(Icons.note_add_outlined, size: 18),
                          label: const Text('Save Note'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('ai-regenerate-button'),
                          onPressed: !_isLoading && !_isStreaming
                              ? () => _runTask(forceRefresh: true)
                              : null,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Regenerate'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _taskChip(String label, AIReadingTask task) {
    final isSelected = _currentTask == task;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _currentTask != task) {
          setState(() => _currentTask = task);
          _runTask();
        }
      },
    );
  }
}

/// Convenience presenter for the AI Assistant panel.
void showAIAssistantPanel(
  BuildContext context, {
  required String text,
  AIReadingTask initialTask = AIReadingTask.explain,
  String? documentId,
  String? documentName,
  int? pageNumber,
  void Function(int pageNumber)? onNavigateToPage,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AIAssistantPanel(
      text: text,
      initialTask: initialTask,
      documentId: documentId,
      documentName: documentName,
      pageNumber: pageNumber,
      onNavigateToPage: onNavigateToPage,
    ),
  );
}
