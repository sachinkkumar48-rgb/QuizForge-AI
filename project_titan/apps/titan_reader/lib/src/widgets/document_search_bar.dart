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

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(kSearchDebounce, () {
      widget.handle.startSearch(query);
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
                                  _onQueryChanged('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: _onQueryChanged,
                    ),
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
                padding: const EdgeInsets.only(left: 16, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(status, style: theme.textTheme.bodySmall),
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
    if (handle.isSearchInProgress) return 'Searching…';
    if (matches.isEmpty) return 'No matches for "$query"';
    final active = currentIndex != null ? currentIndex + 1 : 0;
    return '$active of ${matches.length} matches';
  }
}

/// Scrollable list of all matches found so far; tapping a row jumps to the
/// match's page and makes it the active highlight.
class _ResultsList extends StatelessWidget {
  final PdfViewerHandle handle;
  final List<PdfSearchMatch> matches;

  const _ResultsList({required this.handle, required this.matches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = handle.currentSearchMatchIndex;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          final isActive = index == currentIndex;
          return ListTile(
            dense: true,
            selected: isActive,
            leading: Text(
              'p.${match.pageNumber}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              match.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              // Jump to the match page; the engine marks the match active.
              handle.goToPage(match.pageNumber);
            },
          );
        },
      ),
    );
  }
}
