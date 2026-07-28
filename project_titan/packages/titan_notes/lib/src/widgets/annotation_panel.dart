import 'package:flutter/material.dart';
import '../models/annotation.dart';

/// Material 3 Annotation Panel component.
class AnnotationPanel extends StatelessWidget {
  final List<Annotation> annotations;
  final ValueChanged<Annotation> onAnnotationTap;

  const AnnotationPanel({
    super.key,
    required this.annotations,
    required this.onAnnotationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (annotations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No annotations available.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return ListView.builder(
      itemCount: annotations.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final ann = annotations[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: Text(ann.text, style: theme.textTheme.bodyMedium),
            subtitle: Text(
              'Author: ${ann.author} ${ann.pageNumber != null ? '• Page ${ann.pageNumber}' : ''}',
              style: theme.textTheme.labelSmall,
            ),
            onTap: () => onAnnotationTap(ann),
          ),
        );
      },
    );
  }
}
