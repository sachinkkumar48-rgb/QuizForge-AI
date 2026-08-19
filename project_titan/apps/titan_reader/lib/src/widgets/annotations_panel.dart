import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/reader_annotation.dart';
import '../pdf/pdf_engine_contracts.dart';
import '../providers/reader_providers.dart';

/// Panel listing and managing the Reader-managed markup annotations
/// (highlights, underlines, strikethroughs) of the open document.
///
/// Deleting or recoloring here goes through [AnnotationService] (undoable);
/// the reader screen repaints overlays because it listens to the same
/// provider.
class AnnotationsPanel extends ConsumerStatefulWidget {
  final String documentId;

  /// Viewer handle used to jump to an annotation's page.
  final PdfViewerHandle handle;

  /// Invoked after the user navigates, so the presenter can close the panel.
  final void Function(int pageNumber)? onNavigate;

  const AnnotationsPanel({
    super.key,
    required this.documentId,
    required this.handle,
    this.onNavigate,
  });

  @override
  ConsumerState<AnnotationsPanel> createState() => _AnnotationsPanelState();
}

class _AnnotationsPanelState extends ConsumerState<AnnotationsPanel> {
  @override
  Widget build(BuildContext context) {
    final annotations = ref
            .watch(annotationsForDocumentProvider(widget.documentId))
            .valueOrNull ??
        const <ReaderAnnotation>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.highlight_outlined),
                  const SizedBox(width: 8),
                  Text('Annotations',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('${annotations.length}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (annotations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No annotations yet. Select text in the '
                          'document and choose Highlight, Underline or '
                          'Strikethrough.'),
                    ),
                  for (final annotation in annotations)
                    _AnnotationTile(
                      key: ValueKey('annotation-${annotation.id}'),
                      annotation: annotation,
                      onNavigate: () {
                        widget.handle.goToPage(annotation.pageNumber);
                        widget.onNavigate?.call(annotation.pageNumber);
                      },
                      onRecolor: (color) => _recolor(annotation, color),
                      onDelete: () => _delete(annotation),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recolor(
      ReaderAnnotation annotation, ReaderAnnotationColor color) async {
    final service = ref.read(annotationServiceProvider);
    await service.changeColor(
      documentId: widget.documentId,
      annotationId: annotation.id,
      color: color,
      at: DateTime.now(),
    );
  }

  Future<void> _delete(ReaderAnnotation annotation) async {
    final service = ref.read(annotationServiceProvider);
    final removed = await service.removeAnnotation(
      documentId: widget.documentId,
      annotationId: annotation.id,
    );
    if (!mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.type.name[0].toUpperCase()}'
            '${removed.type.name.substring(1)} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => service.undo(),
        ),
      ),
    );
  }
}

class _AnnotationTile extends StatelessWidget {
  final ReaderAnnotation annotation;
  final VoidCallback onNavigate;
  final void Function(ReaderAnnotationColor color) onRecolor;
  final VoidCallback onDelete;

  const _AnnotationTile({
    super.key,
    required this.annotation,
    required this.onNavigate,
    required this.onRecolor,
    required this.onDelete,
  });

  IconData get _icon => switch (annotation.type) {
        ReaderAnnotationType.highlight => Icons.highlight,
        ReaderAnnotationType.underline => Icons.format_underlined,
        ReaderAnnotationType.strikethrough => Icons.strikethrough_s,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(_icon, color: Color(annotation.color.argb)),
      title: Text(
        annotation.selectedText.isEmpty
            ? annotation.type.name
            : annotation.selectedText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('Page ${annotation.pageNumber}',
          style: theme.textTheme.bodySmall),
      onTap: onNavigate,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<ReaderAnnotationColor>(
            key: ValueKey('recolor-annotation-${annotation.id}'),
            tooltip: 'Change color',
            icon: const Icon(Icons.palette_outlined),
            onSelected: onRecolor,
            itemBuilder: (context) => [
              for (final color in ReaderAnnotationColor.values)
                PopupMenuItem<ReaderAnnotationColor>(
                  value: color,
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 16, color: Color(color.argb)),
                      const SizedBox(width: 8),
                      Text(color.name),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            key: ValueKey('delete-annotation-${annotation.id}'),
            tooltip: 'Delete annotation',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Convenience presenter used by the reader screen.
void showAnnotationsPanel(
  BuildContext context, {
  required String documentId,
  required PdfViewerHandle handle,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AnnotationsPanel(
      documentId: documentId,
      handle: handle,
      onNavigate: (_) => Navigator.of(context).pop(),
    ),
  );
}
