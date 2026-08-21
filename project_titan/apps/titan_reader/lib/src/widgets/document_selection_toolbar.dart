import 'package:flutter/material.dart';

import '../domain/entities/ai_reading_task.dart';
import '../domain/entities/reader_annotation.dart';
import '../pdf/pdf_engine_contracts.dart';

/// Floating selection toolbar providing quick actions for selected PDF text.
///
/// Supports 1-tap copy, multi-color highlighting, underlining, strikethrough,
/// notes, in-document search, dictionary lookup, grammar check, and AI tasks.
class DocumentSelectionToolbar extends StatefulWidget {
  /// The active viewer handle providing text selection state.
  final PdfViewerHandle handle;

  /// Invoked when a selection action is triggered.
  final void Function(String actionId, {ReaderAnnotationColor? color}) onAction;

  /// Currently selected default annotation color.
  final ReaderAnnotationColor activeColor;

  /// Callback when user changes the active annotation color.
  final void Function(ReaderAnnotationColor color)? onColorChanged;

  /// Optional close callback to clear selection and dismiss toolbar.
  final VoidCallback? onClose;

  const DocumentSelectionToolbar({
    super.key,
    required this.handle,
    required this.onAction,
    this.activeColor = ReaderAnnotationColor.yellow,
    this.onColorChanged,
    this.onClose,
  });

  @override
  State<DocumentSelectionToolbar> createState() =>
      _DocumentSelectionToolbarState();
}

class _DocumentSelectionToolbarState extends State<DocumentSelectionToolbar> {
  PdfTextSelectionSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    widget.handle.addSelectionChangedListener(_handleSelectionChanged);
    _loadSelection();
  }

  @override
  void didUpdateWidget(covariant DocumentSelectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      oldWidget.handle.removeSelectionChangedListener(_handleSelectionChanged);
      widget.handle.addSelectionChangedListener(_handleSelectionChanged);
      _loadSelection();
    }
  }

  @override
  void dispose() {
    widget.handle.removeSelectionChangedListener(_handleSelectionChanged);
    super.dispose();
  }

  void _handleSelectionChanged() {
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    if (!mounted) return;
    final snapshot = await widget.handle.captureTextSelection();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshotText = _snapshot?.text ?? '';
    final charCount = snapshotText.length;
    final snippet = snapshotText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (snippet.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Tooltip(
                      message: snippet,
                      child: Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$charCount ch',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  height: 20,
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                key: const Key('selection-copy-button'),
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy text',
                onPressed: () => widget.onAction('copy'),
              ),
              // Highlight action with direct color picker popup
              PopupMenuButton<ReaderAnnotationColor>(
                key: const Key('selection-color-button'),
                tooltip: 'Highlight with color',
                initialValue: widget.activeColor,
                onSelected: (color) {
                  widget.onColorChanged?.call(color);
                  widget.onAction('highlight', color: color);
                },
                itemBuilder: (context) => [
                  for (final color in ReaderAnnotationColor.values)
                    PopupMenuItem<ReaderAnnotationColor>(
                      value: color,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 16,
                            color: Color(color.argb),
                          ),
                          const SizedBox(width: 10),
                          Text(color.name[0].toUpperCase() +
                              color.name.substring(1)),
                          if (color == widget.activeColor) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check, size: 14),
                          ],
                        ],
                      ),
                    ),
                ],
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.highlight,
                        size: 18,
                        color: Color(widget.activeColor.argb),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 14),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('selection-underline-button'),
                icon: const Icon(Icons.format_underlined, size: 18),
                tooltip: 'Underline',
                onPressed: () => widget.onAction('underline'),
              ),
              IconButton(
                key: const Key('selection-strikethrough-button'),
                icon: const Icon(Icons.format_strikethrough, size: 18),
                tooltip: 'Strikethrough',
                onPressed: () => widget.onAction('strikethrough'),
              ),
              IconButton(
                key: const Key('selection-note-button'),
                icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                tooltip: 'Add note',
                onPressed: () => widget.onAction('note'),
              ),
              IconButton(
                key: const Key('selection-search-button'),
                icon: const Icon(Icons.search, size: 18),
                tooltip: 'Search in document',
                onPressed: () => widget.onAction('search'),
              ),
              IconButton(
                key: const Key('selection-dictionary-button'),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                tooltip: 'Define word',
                onPressed: () => widget.onAction('dictionary'),
              ),
              IconButton(
                key: const Key('selection-grammar-button'),
                icon: const Icon(Icons.spellcheck, size: 18),
                tooltip: 'Grammar analysis',
                onPressed: () => widget.onAction('grammar'),
              ),
              // AI Actions Popup Menu
              PopupMenuButton<AIReadingTask>(
                key: const Key('selection-ai-button'),
                tooltip: 'AI Assistant',
                onSelected: (task) {
                  switch (task) {
                    case AIReadingTask.explain:
                      widget.onAction('explain');
                    case AIReadingTask.simplify:
                      widget.onAction('simplify');
                    case AIReadingTask.summarize:
                    case AIReadingTask.keyPoints:
                      widget.onAction('summarize');
                    case AIReadingTask.askQuestion:
                    default:
                      widget.onAction('ask-ai');
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: AIReadingTask.explain,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.lightbulb_outline, size: 18),
                      title: Text('Explain'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: AIReadingTask.simplify,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.compress, size: 18),
                      title: Text('Simplify'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: AIReadingTask.summarize,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.short_text, size: 18),
                      title: Text('Summarize'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: AIReadingTask.askQuestion,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.help_outline, size: 18),
                      title: Text('Ask AI'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down, size: 14),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('selection-close-button'),
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear selection',
                onPressed: () {
                  widget.handle.clearTextSelection();
                  widget.onClose?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
