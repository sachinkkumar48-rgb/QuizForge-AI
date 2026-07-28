import 'package:flutter/material.dart';

/// Material 3 Rich Text Toolbar component.
class RichTextToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onList;
  final VoidCallback onHighlight;

  const RichTextToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onList,
    required this.onHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.format_bold_rounded),
            onPressed: onBold,
            tooltip: 'Bold',
          ),
          IconButton(
            icon: const Icon(Icons.format_italic_rounded),
            onPressed: onItalic,
            tooltip: 'Italic',
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            onPressed: onList,
            tooltip: 'Bullet List',
          ),
          IconButton(
            icon: const Icon(Icons.highlight_rounded),
            onPressed: onHighlight,
            tooltip: 'Highlight',
          ),
        ],
      ),
    );
  }
}
