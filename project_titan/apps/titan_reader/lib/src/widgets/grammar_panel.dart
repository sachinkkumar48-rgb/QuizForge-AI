import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/grammar_issue.dart';
import '../domain/grammar_text_correction.dart';
import '../domain/word_normalizer.dart';
import '../providers/dictionary_providers.dart';
import '../providers/grammar_providers.dart';
import '../services/grammar_service.dart';
import 'dictionary_panel.dart';

/// Grammar panel: issues for the checked selection with explanations,
/// suggestions, accept/copy/dismiss and dictionary/vocabulary reuse.
///
/// Deterministic source-backed analysis only — nothing displayed here is
/// AI generated, and applying a correction never modifies the PDF
/// (§16–17): corrections are Reader-managed records.
class GrammarPanel extends ConsumerStatefulWidget {
  /// The selection text that is checked.
  final String text;

  /// Source context for corrections and vocabulary saves.
  final String? documentId;
  final String? documentName;
  final int? pageNumber;

  const GrammarPanel({
    super.key,
    required this.text,
    this.documentId,
    this.documentName,
    this.pageNumber,
  });

  @override
  ConsumerState<GrammarPanel> createState() => _GrammarPanelState();
}

class _GrammarPanelState extends ConsumerState<GrammarPanel> {
  /// Issues still visible (accepted/dismissed ones are removed).
  List<GrammarIssue> _issues = const [];
  bool _initialized = false;

  /// Accepted replacements against the original selection offsets; used
  /// to build the corrected text for copying.
  final Map<(int, int), String> _applied = {};

  Future<void> _apply(int index, GrammarSuggestion suggestion) async {
    final issue = _issues[index];
    final service = ref.read(grammarServiceProvider);
    await service.applyCorrections(
      text: widget.text,
      replacements: {
        (issue.startOffset, issue.endOffset): suggestion.replacement,
      },
      appliedRuleIds: [issue.ruleId],
      at: DateTime.now(),
      documentId: widget.documentId,
      pageNumber: widget.pageNumber,
    );
    ref.invalidate(grammarCorrectionsProvider);
    if (!mounted) return;
    setState(() {
      _applied[(issue.startOffset, issue.endOffset)] = suggestion.replacement;
      _issues = List.of(_issues)..removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Correction saved. The PDF itself was not modified.'),
      ),
    );
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _dismiss(int index) {
    setState(() {
      _issues = List.of(_issues)..removeAt(index);
    });
  }

  /// Opens the Phase 3 dictionary for the flagged word (single words
  /// only — phrases cannot be looked up).
  void _openDictionary(GrammarIssue issue) {
    final word = WordNormalizer.singleWordFrom(issue.originalText);
    if (word == null) return;
    showDictionaryPanel(
      context,
      word: word,
      documentId: widget.documentId,
      documentName: widget.documentName,
      pageNumber: widget.pageNumber,
      selectedText: issue.originalText,
    );
  }

  Future<void> _saveToVocabulary(GrammarIssue issue) async {
    final word = WordNormalizer.singleWordFrom(issue.originalText);
    if (word == null) return;
    final service = ref.read(vocabularyServiceProvider);
    await service.ensureLoaded();
    final alreadySaved = service.wordForNormalized(word) != null;
    await service.saveWord(
      rawWord: word,
      at: DateTime.now(),
      sourceDocumentId: widget.documentId,
      sourceDocumentName: widget.documentName,
      sourcePage: widget.pageNumber,
      selectedText: issue.originalText,
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

  String get _correctedText =>
      GrammarTextCorrection.apply(widget.text, _applied);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final check = ref.watch(grammarCheckProvider(widget.text));

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
                  const Icon(Icons.spellcheck_outlined),
                  const SizedBox(width: 8),
                  Text('Grammar', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected text · deterministic local engine',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: check.when(
                loading: () => const Center(
                  child: Text('Checking grammar…', key: Key('grammar-loading')),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Grammar check failed: $error',
                        key: const Key('grammar-error')),
                  ),
                ),
                data: (outcome) {
                  if (!_initialized) {
                    _initialized = true;
                    _issues = List.of(outcome.result.issues);
                  }
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _buildSummary(theme, outcome),
                      if (outcome.remote.failureReason != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'Online check unavailable: '
                            '${outcome.remote.failureReason}',
                            key: const Key('grammar-remote-failure'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      if (_issues.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No issues found.',
                              key: Key('grammar-no-issues')),
                        )
                      else
                        for (var i = 0; i < _issues.length; i++)
                          _buildIssueCard(theme, i, _issues[i]),
                      if (_applied.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: FilledButton.icon(
                            key: const Key('grammar-copy-corrected-button'),
                            onPressed: () => _copy(
                              _correctedText,
                              'Corrected text copied.',
                            ),
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Copy corrected text'),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          'Applying a suggestion stores a Reader-managed '
                          'correction; the original PDF is never modified.',
                          key: Key('grammar-pdf-note'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummary(
    ThemeData theme,
    ({
      GrammarCheckResult result,
      GrammarRemoteOutcome remote,
    }) outcome,
  ) {
    final total = outcome.result.issues.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0
                ? 'No issues found'
                : '$total issue${total == 1 ? '' : 's'} found',
            key: const Key('grammar-issue-count'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            widget.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(ThemeData theme, int index, GrammarIssue issue) {
    final scheme = theme.colorScheme;
    final severity = _severityInfo(issue.severity);
    final isSingleWord =
        WordNormalizer.singleWordFrom(issue.originalText) != null;
    return Card(
      key: ValueKey('grammar-issue-card-$index'),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    severity.label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: severity.color),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_typeLabel(issue.type),
                    style: theme.textTheme.labelMedium),
                const Spacer(),
                if (issue.source == GrammarIssueSource.remote)
                  const Icon(Icons.cloud_outlined, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(issue.message, style: theme.textTheme.bodyMedium),
            if (issue.explanation != null) ...[
              const SizedBox(height: 4),
              Text(issue.explanation!, style: theme.textTheme.bodySmall),
            ],
            if (issue.originalText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Original: "${issue.originalText}"',
                  key: ValueKey('grammar-issue-original-$index'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(decoration: TextDecoration.underline)),
            ],
            if (issue.suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No automatic correction available.',
                    style: theme.textTheme.bodySmall),
              )
            else
              for (var s = 0; s < issue.suggestions.length; s++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Suggestion: '
                          '"${issue.suggestions[s].replacement}"',
                          key: ValueKey('grammar-issue-suggestion-$index-$s'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        key: ValueKey('grammar-apply-$index-$s'),
                        tooltip: 'Apply',
                        icon: const Icon(Icons.check),
                        onPressed: () => _apply(index, issue.suggestions[s]),
                      ),
                      IconButton(
                        key: ValueKey('grammar-copy-suggestion-$index-$s'),
                        tooltip: 'Copy suggestion',
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () => _copy(
                          issue.suggestions[s].replacement,
                          'Suggestion copied.',
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton(
                  key: ValueKey('grammar-dismiss-$index'),
                  onPressed: () => _dismiss(index),
                  child: const Text('Dismiss'),
                ),
                if (issue.type == GrammarIssueType.spelling &&
                    isSingleWord) ...[
                  TextButton(
                    key: ValueKey('grammar-dictionary-$index'),
                    onPressed: () => _openDictionary(issue),
                    child: const Text('Dictionary'),
                  ),
                  TextButton(
                    key: ValueKey('grammar-vocabulary-$index'),
                    onPressed: () => _saveToVocabulary(issue),
                    child: const Text('Save word'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(GrammarIssueType type) {
    switch (type) {
      case GrammarIssueType.spelling:
        return 'Spelling';
      case GrammarIssueType.grammar:
        return 'Grammar';
      case GrammarIssueType.punctuation:
        return 'Punctuation';
      case GrammarIssueType.typographical:
        return 'Typographical';
      case GrammarIssueType.style:
        return 'Style';
    }
  }

  static ({String label, Color color}) _severityInfo(
      GrammarIssueSeverity severity) {
    switch (severity) {
      case GrammarIssueSeverity.error:
        return (label: 'Error', color: const Color(0xFFC62828));
      case GrammarIssueSeverity.warning:
        return (label: 'Warning', color: const Color(0xFFEF6C00));
      case GrammarIssueSeverity.suggestion:
        return (label: 'Suggestion', color: const Color(0xFF1565C0));
    }
  }
}

/// Convenience presenter used by the reader screen.
void showGrammarPanel(
  BuildContext context, {
  required String text,
  String? documentId,
  String? documentName,
  int? pageNumber,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => GrammarPanel(
      text: text,
      documentId: documentId,
      documentName: documentName,
      pageNumber: pageNumber,
    ),
  );
}
