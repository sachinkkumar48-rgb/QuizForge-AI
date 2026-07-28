import 'package:flutter/material.dart';
import '../models/content_metadata.dart';

/// Reusable Material 3 metadata card widget showing author, subject, tags, duration, and offline status.
class ContentMetadataCard extends StatelessWidget {
  final ContentMetadata metadata;

  const ContentMetadataCard({
    super.key,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20.0, color: colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(
                  'Content Metadata',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            _buildMetaRow(
                context, 'Author', metadata.author, Icons.person_outline),
            _buildMetaRow(
                context, 'Subject', metadata.subject, Icons.category_outlined),
            _buildMetaRow(
                context, 'Topic', metadata.topic, Icons.topic_outlined),
            _buildMetaRow(context, 'Difficulty', metadata.difficultyLevel,
                Icons.bar_chart_outlined),
            _buildMetaRow(
                context,
                'Duration',
                '${metadata.estimatedDurationMinutes} mins',
                Icons.schedule_outlined),
            if (metadata.fileSizeFormat != null)
              _buildMetaRow(context, 'Size', metadata.fileSizeFormat!,
                  Icons.sd_card_outlined),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: [
                Chip(
                  avatar: Icon(
                    metadata.isOfflineAvailable
                        ? Icons.offline_pin_outlined
                        : Icons.cloud_outlined,
                    size: 14.0,
                  ),
                  label: Text(metadata.isOfflineAvailable
                      ? 'Offline Ready'
                      : 'Online Only'),
                  backgroundColor: colorScheme.surface,
                ),
                ...metadata.tags.map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    backgroundColor: colorScheme.surface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 14.0, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6.0),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
