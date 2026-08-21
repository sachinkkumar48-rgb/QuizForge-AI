import 'dart:async';

import 'package:flutter/material.dart';

import '../pdf/pdf_engine_contracts.dart';

/// Debounce interval applied to search queries before hitting the engine.
const Duration kSearchDebounce = Duration(milliseconds: 350);

/// Text search panel for the reader screen.
///
/// Talks only to the engine-agnostic [PdfViewerHandle] contract, so the
/// search UI never depends on a concrete PDF SDK. Query input is debounced
/// ([kSearchDebounce]) to keep large documents responsive.
class DocumentSearchBar extends StatefulWidget {
  final PdfViewerHandle handle;
  final VoidCallback onClose;

  const DocumentSearchBar({
    super.key,
    required this.handle,
    required this.onClose,
  });

  @override
  State<DocumentSearchBar> createState() => DocumentSearchBarState();
}

/// Exposed for tests.
class DocumentSearchBarState extends State<DocumentSearchBar> {
  final TextEditingController controller = TextEditingController();
  Timer? _debounce;
  bool _resultsExpanded = false;
  bool _caseSensitive = false;
  bool _wholeWord = false;

  @override
  void initState() {
    super.initState();
    widget.handle.addSearchChangedListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.handle.removeSearchChangedListener(_onSearchChanged);
    // Leaving the panel always clears the active match highlighting.
    widget.handle.clearSearch();
    controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _onQueryChanged(String query, {bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      if (query.trim().isEmpty) {
        widget.handle.clearSearch();
      } else {
        widget.handle.startSearch(
          query,
          caseSensitive: _caseSensitive,
          wholeWord: _wholeWord,
        );
      }
      return;
    }
    _debounce = Timer(kSearchDebounce, () {
      if (query.trim().isEmpty) {
        widget.handle.clearSearch();
      } else {
        widget.handle.startSearch(
          query,
          caseSensitive: _caseSensitive,
          wholeWord: _wholeWord,
        );
      }
    });
  }

  void _toggleCaseSensitive() {
    setState(() {
      _caseSensitive = !_caseSensitive;
      _onQueryChanged(controller.text, immediate: true);
    });
  }

  void _toggleWholeWord() {
    setState(() {
      _wholeWord = !_wholeWord;
      _onQueryChanged(controller.text, immediate: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final handle = widget.handle;
    final theme = Theme.of(context);
    final matches = handle.searchMatches;
    final currentIndex = handle.currentSearchMatchIndex;
    final status = _statusText(matches, currentIndex, handle);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search in document',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear query',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controller.clear();
                                  widget.handle.clearSearch();
                                  _onQueryChanged('', immediate: true);
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (text) {
                        setState(() {});
                        _onQueryChanged(text);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Case Sensitive Toggle
                  IconButton(
                    key: const Key('search-case-sensitive-toggle'),
                    tooltip: _caseSensitive
                        ? 'Case sensitive (on)'
                        : 'Match case (off)',
                    icon: Icon(
                      Icons.format_size,
                      size: 20,
                      color: _caseSensitive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                    ),
                    style: _caseSensitive
                        ? IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                          )
                        : null,
                    onPressed: _toggleCaseSensitive,
                  ),

                  // Whole Word Toggle
                  IconButton(
                    key: const Key('search-whole-word-toggle'),
                    tooltip: _wholeWord
                        ? 'Whole word (on)'
                        : 'Match whole word (off)',
                    icon: Icon(
                      Icons.space_bar,
                      size: 20,
                      color: _wholeWord
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                    ),
                    style: _wholeWord
                        ? IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                          )
                        : null,
                    onPressed: _toggleWholeWord,
                  ),

                  IconButton(
                    tooltip: 'Previous match',
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: matches.isEmpty
                        ? null
                        : () => handle.goToPreviousSearchMatch(),
                  ),
                  IconButton(
                    tooltip: 'Next match',
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: matches.isEmpty
                        ? null
                        : () => handle.goToNextSearchMatch(),
                  ),
                  IconButton(
                    tooltip: 'Show results list',
                    icon: Icon(_resultsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                    onPressed: matches.isEmpty ? null : _toggleResultsList,
                  ),
                  IconButton(
                    tooltip: 'Close search',
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 6, right: 16),
                child: Row(
                  children: [
                    if (handle.isSearchInProgress) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: matches.isEmpty && controller.text.isNotEmpty
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_resultsExpanded && matches.isNotEmpty)
              _ResultsList(handle: handle, matches: matches),
          ],
        ),
      ),
    );
  }

  void _toggleResultsList() {
    setState(() => _resultsExpanded = !_resultsExpanded);
  }

  String? _statusText(
      List<PdfSearchMatch> matches, int? currentIndex, PdfViewerHandle handle) {
    final query = controller.text.trim();
    if (query.isEmpty && matches.isEmpty) return null;
    if (handle.isSearchInProgress) return 'Searching document…';
    if (matches.isEmpty) return 'No matches for "$query"';
    final active = currentIndex != null ? currentIndex + 1 : 0;
    return '$active of ${matches.length} matches';
  }
}

/// Scrollable list of all matches found so far; tapping a row jumps to the
/// match's page and activates that match.
class _ResultsList extends StatelessWidget {
  final PdfViewerHandle handle;
  final List<PdfSearchMatch> matches;

  const _ResultsList({required this.handle, required this.matches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = handle.currentSearchMatchIndex;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Material(
        color: theme.colorScheme.surface,
        shape: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: matches.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
          itemBuilder: (context, index) {
            final match = matches[index];
            final isActive = index == currentIndex;
            return ListTile(
              dense: true,
              selected: isActive,
              selectedTileColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'p. ${match.pageNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                match.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                handle.goToSearchMatch(index);
              },
            );
          },
        ),
      ),
    );
  }
}
