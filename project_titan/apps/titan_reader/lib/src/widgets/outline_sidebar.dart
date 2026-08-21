import 'package:flutter/material.dart';

import '../domain/entities/reader_bookmark.dart';
import '../pdf/pdf_engine_contracts.dart';

/// Collapsible left-docked Table of Contents / Outline navigation panel.
///
/// Loads the native PDF outline hierarchy from [handle], rendering a multi-level
/// interactive tree with expansion/collapse toggling, title search filtering,
/// active section highlighting, and destination navigation.
class OutlineSidebar extends StatefulWidget {
  final PdfViewerHandle handle;
  final int currentPage;
  final void Function(ReaderOutlineEntry entry)? onEntrySelected;
  final VoidCallback? onClose;
  final double width;

  const OutlineSidebar({
    super.key,
    required this.handle,
    required this.currentPage,
    this.onEntrySelected,
    this.onClose,
    this.width = 260,
  });

  @override
  State<OutlineSidebar> createState() => _OutlineSidebarState();
}

class _OutlineSidebarState extends State<OutlineSidebar> {
  List<ReaderOutlineEntry> _outline = const [];
  bool _isLoading = true;
  String _filterQuery = '';
  final Set<String> _collapsedPaths = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOutline();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOutline() async {
    setState(() => _isLoading = true);
    final outline = await widget.handle.loadOutline();
    if (!mounted) return;
    setState(() {
      _outline = outline;
      _isLoading = false;
    });
  }

  void _toggleExpanded(String path) {
    setState(() {
      if (_collapsedPaths.contains(path)) {
        _collapsedPaths.remove(path);
      } else {
        _collapsedPaths.add(path);
      }
    });
  }

  void _expandAll() {
    setState(() {
      _collapsedPaths.clear();
    });
  }

  void _collapseAll() {
    setState(() {
      void collectPaths(List<ReaderOutlineEntry> entries) {
        for (final entry in entries) {
          if (entry.children.isNotEmpty) {
            _collapsedPaths.add(entry.path);
            collectPaths(entry.children);
          }
        }
      }

      collectPaths(_outline);
    });
  }

  bool _matchesFilter(ReaderOutlineEntry entry) {
    if (_filterQuery.isEmpty) return true;
    if (entry.title.toLowerCase().contains(_filterQuery.toLowerCase())) {
      return true;
    }
    return entry.children.any(_matchesFilter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.toc_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Table of Contents',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_outline.isNotEmpty) ...[
                  IconButton(
                    key: const Key('outline-expand-all-button'),
                    icon: const Icon(Icons.unfold_more, size: 18),
                    tooltip: 'Expand all',
                    visualDensity: VisualDensity.compact,
                    onPressed: _expandAll,
                  ),
                  IconButton(
                    key: const Key('outline-collapse-all-button'),
                    icon: const Icon(Icons.unfold_less, size: 18),
                    tooltip: 'Collapse all',
                    visualDensity: VisualDensity.compact,
                    onPressed: _collapseAll,
                  ),
                ],
                if (widget.onClose != null)
                  IconButton(
                    key: const Key('close-outline-sidebar-button'),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Close outline',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // Search Filter (shown when outline is populated)
          if (!_isLoading && _outline.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                key: const Key('outline-search-field'),
                controller: _searchController,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Filter sections…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _filterQuery.isNotEmpty
                      ? IconButton(
                          key: const Key('clear-outline-search-button'),
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filterQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _filterQuery = value.trim()),
              ),
            ),

          // Content body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator.adaptive(),
                  )
                : _outline.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 36,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'This document has no table of contents.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildOutlineList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineList(BuildContext context) {
    final filtered = _outline.where(_matchesFilter).toList();

    if (filtered.isEmpty && _filterQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No matching sections found.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView(
      key: const Key('outline-tree-list-view'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        for (final entry in filtered)
          ..._buildNodeAndChildren(context, entry, 0),
      ],
    );
  }

  List<Widget> _buildNodeAndChildren(
    BuildContext context,
    ReaderOutlineEntry entry,
    int depth,
  ) {
    final theme = Theme.of(context);
    final hasChildren = entry.children.isNotEmpty;
    final isCollapsed = _collapsedPaths.contains(entry.path);
    final isCurrent =
        entry.pageNumber != null && entry.pageNumber == widget.currentPage;

    final widgets = <Widget>[];

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: Semantics(
          container: true,
          label:
              '${entry.title}${entry.pageNumber != null ? ", Page ${entry.pageNumber}" : ""}',
          button: true,
          selected: isCurrent,
          child: InkWell(
            key: Key('outline-node-${entry.path}'),
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              widget.handle.goToOutlineEntry(entry.path);
              widget.onEntrySelected?.call(entry);
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 8.0 + depth * 16.0,
                right: 8.0,
                top: 6.0,
                bottom: 6.0,
              ),
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isCurrent
                    ? Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        width: 1.0,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Expand/collapse toggle or bullet
                  if (hasChildren)
                    GestureDetector(
                      key: Key('toggle-expand-${entry.path}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleExpanded(entry.path),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(
                          isCollapsed
                              ? Icons.chevron_right_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, right: 10.0),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),

                  // Section Title
                  Expanded(
                    child: Text(
                      entry.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : (depth == 0
                                ? FontWeight.w600
                                : FontWeight.normal),
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Destination Page Badge
                  if (entry.pageNumber != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.pageNumber}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCurrent
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Recursively render children when expanded
    if (hasChildren && !isCollapsed) {
      for (final child in entry.children.where(_matchesFilter)) {
        widgets.addAll(_buildNodeAndChildren(context, child, depth + 1));
      }
    }

    return widgets;
  }
}
