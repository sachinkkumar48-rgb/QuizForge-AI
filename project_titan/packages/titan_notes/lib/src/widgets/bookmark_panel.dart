import 'package:flutter/material.dart';
import '../models/note_bookmark.dart';

/// Material 3 Bookmark Panel component.
class BookmarkPanel extends StatelessWidget {
  final List<NoteBookmark> bookmarks;
  final ValueChanged<NoteBookmark> onBookmarkTap;

  const BookmarkPanel({
    super.key,
    required this.bookmarks,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No note bookmarks.', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bm = bookmarks[index];
        return ListTile(
          leading: Icon(Icons.bookmark_rounded, color: colorScheme.primary),
          title: Text(bm.label, style: theme.textTheme.bodyMedium),
          subtitle: Text('Offset: ${bm.offsetIndex}',
              style: theme.textTheme.labelSmall),
          onTap: () => onBookmarkTap(bm),
        );
      },
    );
  }
}
