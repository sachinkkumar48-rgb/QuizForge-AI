import 'package:flutter/material.dart';
import '../models/note_tag.dart';

/// Material 3 Note Tag Chip widget.
class NoteTagChip extends StatelessWidget {
  final NoteTag tag;
  final VoidCallback? onTap;

  const NoteTagChip({
    super.key,
    required this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RawChip(
      label: Text(
        '#${tag.label}',
        style:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
