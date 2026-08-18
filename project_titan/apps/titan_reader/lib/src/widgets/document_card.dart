import 'package:flutter/material.dart';

import '../domain/entities/reader_document.dart';

/// Library list tile presenting a single [ReaderDocument] with quick
/// actions (favorite, remove).
class DocumentCard extends StatelessWidget {
  final ReaderDocument document;
  final VoidCallback onOpen;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onRemove;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onOpen,
    this.onToggleFavorite,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleFavorite != null)
                IconButton(
                  tooltip: document.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  icon: Icon(
                    document.isFavorite
                        ? Icons.star
                        : Icons.star_border_outlined,
                    color: document.isFavorite
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleFavorite,
                ),
              if (onRemove != null)
                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  onSelected: (value) {
                    if (value == 'remove') onRemove!();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove from library'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[_formatSize(document.sizeBytes)];
    final pageCount = document.pageCount;
    if (pageCount != null) {
      parts.add('$pageCount pages');
    }
    final opened = document.lastOpenedAt;
    if (opened != null) {
      parts.add('Opened ${_formatDate(opened)}');
    } else {
      parts.add('Added ${_formatDate(document.addedAt)}');
    }
    return parts.join(' • ');
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
