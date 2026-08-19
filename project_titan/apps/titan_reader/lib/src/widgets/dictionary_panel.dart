import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dictionary_errors.dart';
import '../domain/entities/dictionary_entry.dart';
import '../domain/word_normalizer.dart';
import '../providers/dictionary_providers.dart';

/// Dictionary panel: word lookup with definitions, pronunciation, parts of
/// speech, examples, synonyms and antonyms, plus save-to-vocabulary.
///
/// With no initial word the panel shows search and recent lookups.
/// Source-backed data only — nothing displayed here is AI generated.
class DictionaryPanel extends ConsumerStatefulWidget {
  /// Word looked up when the panel opens; null opens the search view.
  final String? initialWord;

  /// Source context recorded when saving a word from a selection.
  final String? documentId;
  final String? documentName;
  final int? pageNumber;
  final String? selectedText;

  const DictionaryPanel({
    super.key,
    this.initialWord,
    this.documentId,
    this.documentName,
    this.pageNumber,
    this.selectedText,
  });

  @override
  ConsumerState<DictionaryPanel> createState() => _DictionaryPanelState();
}

class _DictionaryPanelState extends ConsumerState<DictionaryPanel> {
  /// Lookup navigation stack; back pops to the previous word.
  final List<String> _stack = [];
  final TextEditingController _queryController = TextEditingController();
  List<String> _suggestions = const [];

  String? get _current => _stack.isEmpty ? null : _stack.last;

  @override
  void initState() {
    super.initState();
    final word = WordNormalizer.normalizeWord(widget.initialWord ?? '');
    if (word != null) _stack.add(word);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// Pushes [word] on top of the stack (used by synonym/antonym taps so
  /// the back button returns to the previous word).
  void _pushLookup(String rawWord) {
    final word = WordNormalizer.normalizeWord(rawWord);
    if (word == null) return;
    setState(() => _stack.add(word));
  }

  /// Replaces the current lookup (used by the search field).
  void _replaceLookup(String rawWord) {
    final word = WordNormalizer.normalizeWord(rawWord);
    if (word == null) return;
    setState(() {
      if (_stack.isEmpty) {
        _stack.add(word);
      } else {
        _stack.last = word;
      }
    });
  }

  Future<void> _updateSuggestions(String query) async {
    final suggestions =
        await ref.read(dictionaryServiceProvider).suggestions(query);
    if (!mounted) return;
    setState(() => _suggestions = suggestions);
  }

  Future<void> _saveWord() async {
    final word = _current;
    if (word == null) return;
    final service = ref.read(vocabularyServiceProvider);
    await service.ensureLoaded();
    final alreadySaved = service.wordForNormalized(word) != null;
    String? dictionarySourceId;
    final result = ref.read(dictionaryLookupProvider(word)).valueOrNull;
    if (result is DictionaryLookupFound) {
      dictionarySourceId = result.entry.source.id;
    }
    await service.saveWord(
      rawWord: word,
      at: DateTime.now(),
      dictionarySourceId: dictionarySourceId,
      sourceDocumentId: widget.documentId,
      sourceDocumentName: widget.documentName,
      sourcePage: widget.pageNumber,
      selectedText: widget.selectedText,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(alreadySaved
            ? '"$word" is already in My Vocabulary.'
            : 'Saved "$word" to My Vocabulary.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _current;

    // Keep the recent-lookup list fresh after every completed lookup.
    if (current != null) {
      ref.listen(dictionaryLookupProvider(current), (previous, next) {
        if (next.hasValue) ref.invalidate(recentLookupsProvider);
      });
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  if (_stack.length > 1)
                    IconButton(
                      key: const Key('dictionary-back-button'),
                      tooltip: 'Previous word',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _stack.removeLast()),
                    ),
                  const Icon(Icons.menu_book_outlined),
                  const SizedBox(width: 8),
                  Text('Dictionary', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('dictionary-search-field'),
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: 'Look up a word',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _queryController.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('dictionary-search-clear'),
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _queryController.clear();
                            setState(() => _suggestions = const []);
                          },
                        ),
                ),
                onChanged: _updateSuggestions,
                onSubmitted: (value) {
                  _replaceLookup(value);
                  _queryController.clear();
                  setState(() => _suggestions = const []);
                },
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (_suggestions.isNotEmpty)
                    for (final suggestion in _suggestions)
                      ListTile(
                        key: ValueKey('dictionary-suggestion-$suggestion'),
                        dense: true,
                        leading: const Icon(Icons.history),
                        title: Text(suggestion),
                        onTap: () {
                          _replaceLookup(suggestion);
                          _queryController.clear();
                          setState(() => _suggestions = const []);
                        },
                      ),
                  if (current == null)
                    _buildSearchHome()
                  else
                    _buildResult(current),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// View shown when no word is active: recent lookups.
  Widget _buildSearchHome() {
    final recent = ref.watch(recentLookupsProvider);
    final theme = Theme.of(context);
    return recent.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Loading recent lookups…'),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Failed to load recent lookups: $error'),
      ),
      data: (lookups) {
        if (lookups.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select a word in the document and choose Dictionary, or '
              'type a word above.',
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Recent lookups',
                        style: theme.textTheme.titleSmall),
                  ),
                  IconButton(
                    key: const Key('dictionary-clear-history-button'),
                    tooltip: 'Clear history',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () async {
                      await ref
                          .read(dictionaryServiceProvider)
                          .clearRecentLookups();
                      ref.invalidate(recentLookupsProvider);
                    },
                  ),
                ],
              ),
            ),
            for (final lookup in lookups)
              ListTile(
                key: ValueKey('dictionary-recent-${lookup.word}'),
                leading: const Icon(Icons.schedule),
                title: Text(lookup.word),
                onTap: () => _pushLookup(lookup.word),
              ),
          ],
        );
      },
    );
  }

  Widget _buildResult(String word) {
    final lookup = ref.watch(dictionaryLookupProvider(word));
    return lookup.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KeyedSubtree(
                key: Key('dictionary-loading'),
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 12),
              Text('Looking up "$word"…'),
            ],
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Dictionary lookup failed: $error'),
      ),
      data: (result) => switch (result) {
        DictionaryLookupFound(:final entry) => _buildEntry(entry),
        DictionaryLookupNotFound(:final offline) =>
          _buildNotFound(word, offline: offline),
        DictionaryLookupFailure(:final error) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error.message, key: const Key('dictionary-error')),
          ),
      },
    );
  }

  Widget _buildEntry(DictionaryEntry entry) {
    final theme = Theme.of(context);
    var definitionIndex = 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.word,
                  key: const Key('dictionary-word-header'),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                key: const Key('dictionary-save-word-button'),
                onPressed: _saveWord,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save Word'),
              ),
            ],
          ),
          if (entry.phonetic != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.phonetic!,
                key: const Key('dictionary-phonetic'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          if (entry.wordOrigin != null) ...[
            const SizedBox(height: 12),
            Text('Origin', style: theme.textTheme.titleSmall),
            Text(entry.wordOrigin!),
          ],
          for (var i = 0; i < entry.senses.length; i++) ...[
            const SizedBox(height: 16),
            Text(
              entry.senses[i].partOfSpeech,
              key: ValueKey('dictionary-pos-$i'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            for (final definition in entry.senses[i].definitions)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${++definitionIndex}. $definition',
                  key: ValueKey('dictionary-definition-$definitionIndex'),
                ),
              ),
            if (entry.senses[i].examples.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Examples', style: theme.textTheme.titleSmall),
              for (final example in entry.senses[i].examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '"$example"',
                    key: ValueKey('dictionary-example-$definitionIndex-'
                        '${entry.senses[i].examples.indexOf(example)}'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            if (entry.senses[i].synonyms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Synonyms', style: theme.textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final synonym in entry.senses[i].synonyms)
                    ActionChip(
                      key: ValueKey('dictionary-synonym-$synonym'),
                      label: Text(synonym),
                      onPressed: () => _pushLookup(synonym),
                    ),
                ],
              ),
            ],
            if (entry.senses[i].antonyms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Antonyms', style: theme.textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final antonym in entry.senses[i].antonyms)
                    ActionChip(
                      key: ValueKey('dictionary-antonym-$antonym'),
                      label: Text(antonym),
                      onPressed: () => _pushLookup(antonym),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            entry.source.attribution,
            key: const Key('dictionary-attribution'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(String word, {required bool offline}) {
    final theme = Theme.of(context);
    if (!offline) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No entry found for "$word".',
            key: const Key('dictionary-not-found'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Not available offline',
            key: const Key('dictionary-offline-unavailable'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '"$word" is not in the bundled dictionary. Dictionary lookup '
            'works fully offline for bundled words; online lookup is '
            'optional and off by default.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('dictionary-online-toggle'),
            title: const Text('Online lookup'),
            subtitle: const Text(
                'Sends only the word itself to a free dictionary service.'),
            value: ref.watch(remoteLookupEnabledProvider),
            onChanged: (value) {
              ref.read(remoteLookupEnabledProvider.notifier).state = value;
              ref.invalidate(dictionaryLookupProvider(word));
            },
          ),
        ],
      ),
    );
  }
}

/// Convenience presenter used by the reader screen and other entry points.
void showDictionaryPanel(
  BuildContext context, {
  String? word,
  String? documentId,
  String? documentName,
  int? pageNumber,
  String? selectedText,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DictionaryPanel(
      initialWord: word,
      documentId: documentId,
      documentName: documentName,
      pageNumber: pageNumber,
      selectedText: selectedText,
    ),
  );
}
