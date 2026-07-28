import 'package:flutter/material.dart';
import '../models/highlight.dart';

/// Material 3 Highlight Panel component.
class HighlightPanel extends StatelessWidget {
  final List<Highlight> highlights;
  final ValueChanged<Highlight> onHighlightTap;

  const HighlightPanel({
    super.key,
    required this.highlights,
    required this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (highlights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No text highlights yet.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return ListView.builder(
      itemCount: highlights.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final hl = highlights[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading:
                const Icon(Icons.border_color_rounded, color: Colors.amber),
            title: Text('"${hl.highlightedText}"',
                style: theme.textTheme.bodyMedium),
            subtitle: hl.note != null
                ? Text(hl.note!, style: theme.textTheme.labelSmall)
                : null,
            onTap: () => onHighlightTap(hl),
          ),
        );
      },
    );
  }
}
