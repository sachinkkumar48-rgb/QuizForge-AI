import 'package:flutter/material.dart';
import '../models/video_bookmark.dart';

/// Material 3 Bookmark Timeline list component.
class BookmarkTimeline extends StatelessWidget {
  final List<VideoBookmark> bookmarks;
  final ValueChanged<VideoBookmark> onBookmarkTap;

  const BookmarkTimeline({
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
          child: Text('No bookmarks added yet.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bm = bookmarks[index];
        return ListTile(
          leading: Icon(Icons.bookmark_rounded, color: colorScheme.primary),
          title: Text('${bm.timestampSeconds}s — ${bm.note}',
              style: theme.textTheme.bodyMedium),
          subtitle: Text(
              'Created: ${bm.createdAt.toLocal().toString().split('.')[0]}',
              style: theme.textTheme.labelSmall),
          onTap: () => onBookmarkTap(bm),
        );
      },
    );
  }
}
