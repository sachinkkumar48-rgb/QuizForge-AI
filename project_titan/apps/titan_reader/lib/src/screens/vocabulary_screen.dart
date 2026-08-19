import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/vocabulary_word.dart';
import '../navigation/reader_routes.dart';
import '../providers/dictionary_providers.dart';
import '../services/vocabulary_service.dart';
import '../widgets/dictionary_panel.dart';
import '../widgets/vocabulary_word_editor_dialog.dart';

/// My Vocabulary: the user's saved words with search, status filters,
/// sorting, personal notes and navigation back to the source document.
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  VocabularyMasteryStatus? _statusFilter;
  VocabularySortMode _sortMode = VocabularySortMode.recent;

  @override
  void initState() {
    super.initState();
    ref.read(vocabularyServiceProvider).ensureLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VocabularyWord> _visibleWords(List<VocabularyWord> all) {
    final service = ref.read(vocabularyServiceProvider);
    var words = _query.isEmpty ? all : service.search(_query);
    if (_statusFilter != null) {
      words = words.where((w) => w.status == _statusFilter).toList();
    }
    final sorted = List.of(words);
    switch (_sortMode) {
      case VocabularySortMode.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case VocabularySortMode.alphabetical:
        sorted.sort((a, b) => a.normalizedWord.compareTo(b.normalizedWord));
      case VocabularySortMode.status:
        sorted.sort((a, b) {
          final byStatus = a.status.index.compareTo(b.status.index);
          if (byStatus != 0) return byStatus;
          return a.normalizedWord.compareTo(b.normalizedWord);
        });
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allWords = ref.watch(vocabularyWordsProvider).valueOrNull ?? const [];
    final words = _visibleWords(allWords);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vocabulary'),
        actions: [
          PopupMenuButton<VocabularySortMode>(
            key: const Key('vocabulary-sort-button'),
            tooltip: 'Sort',
            initialValue: _sortMode,
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: VocabularySortMode.recent,
                child: Text('Recently saved'),
              ),
              PopupMenuItem(
                value: VocabularySortMode.alphabetical,
                child: Text('Alphabetical'),
              ),
              PopupMenuItem(
                value: VocabularySortMode.status,
                child: Text('Status'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              key: const Key('vocabulary-search-field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search word, note or document',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('vocabulary-search-clear'),
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  key: const Key('vocabulary-filter-all'),
                  label: 'All',
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                for (final status in VocabularyMasteryStatus.values)
                  _FilterChip(
                    key: ValueKey('vocabulary-filter-${status.name}'),
                    label: status.label,
                    selected: _statusFilter == status,
                    onSelected: () => setState(() => _statusFilter = status),
                  ),
              ],
            ),
          ),
          Expanded(
            child: words.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        allWords.isEmpty
                            ? 'No saved words yet. Select a word in the '
                                'reader and choose "Save Word".'
                            : 'No words match the current search or filter.',
                        key: const Key('vocabulary-empty'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: words.length,
                    itemBuilder: (context, index) => _buildTile(words[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(VocabularyWord word) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      if (word.personalMeaning.isNotEmpty) word.personalMeaning,
      if (word.sourceDocumentName != null)
        'Source: ${word.sourceDocumentName}'
            '${word.sourcePage != null ? ' · page ${word.sourcePage}' : ''}',
    ];
    return ListTile(
      key: ValueKey('vocabulary-word-${word.id}'),
      leading: ChoiceChip(
        key: ValueKey('vocabulary-status-${word.id}'),
        label: Text(word.status.label),
        selected: true,
        onSelected: (_) => _changeStatus(word),
      ),
      title: Text(word.word),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle.join('\n'), style: theme.textTheme.bodySmall),
      isThreeLine: subtitle.length > 1,
      onTap: () => _openDictionary(word),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (word.hasNavigableSource)
            IconButton(
              key: ValueKey('vocabulary-open-source-${word.id}'),
              tooltip: 'Open source page',
              icon: const Icon(Icons.description_outlined),
              onPressed: () => _openSource(word),
            ),
          IconButton(
            key: ValueKey('vocabulary-edit-${word.id}'),
            tooltip: 'Edit meaning and note',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editWord(word),
          ),
          IconButton(
            key: ValueKey('vocabulary-delete-${word.id}'),
            tooltip: 'Delete word',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteWord(word),
          ),
        ],
      ),
    );
  }

  void _openDictionary(VocabularyWord word) {
    showDictionaryPanel(
      context,
      word: word.word,
      documentId: word.sourceDocumentId,
      documentName: word.sourceDocumentName,
      pageNumber: word.sourcePage,
      selectedText: word.selectedText,
    );
  }

  void _openSource(VocabularyWord word) {
    final documentId = word.sourceDocumentId;
    final page = word.sourcePage;
    if (documentId == null || page == null) return;
    context.go(ReaderRoutes.readerFor(documentId, page: page));
  }

  Future<void> _changeStatus(VocabularyWord word) async {
    final next = await showDialog<VocabularyMasteryStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Status for "${word.word}"'),
        children: [
          for (final status in VocabularyMasteryStatus.values)
            SimpleDialogOption(
              key: ValueKey('vocabulary-status-option-${status.name}'),
              onPressed: () => Navigator.of(context).pop(status),
              child: Text(status.label),
            ),
        ],
      ),
    );
    if (next == null) return;
    await ref.read(vocabularyServiceProvider).changeStatus(
          wordId: word.id,
          status: next,
          at: DateTime.now(),
        );
  }

  Future<void> _editWord(VocabularyWord word) async {
    final result = await showVocabularyWordEditor(
      context,
      word: word.word,
      initialMeaning: word.personalMeaning,
      initialNote: word.personalNote,
    );
    if (result == null) return;
    await ref.read(vocabularyServiceProvider).updateWord(
          wordId: word.id,
          at: DateTime.now(),
          personalMeaning: result.personalMeaning,
          personalNote: result.personalNote,
        );
  }

  Future<void> _deleteWord(VocabularyWord word) async {
    final removed =
        await ref.read(vocabularyServiceProvider).removeWord(wordId: word.id);
    if (!mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "${removed.word}" from vocabulary.')),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
