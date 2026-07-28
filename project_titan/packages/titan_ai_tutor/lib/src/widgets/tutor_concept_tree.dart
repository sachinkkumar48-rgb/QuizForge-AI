import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 visualization for concept trees and prerequisite hierarchies.
class TutorConceptTree extends StatelessWidget {
  final TutorConcept rootConcept;
  final void Function(String conceptId)? onConceptSelected;

  const TutorConceptTree({
    super.key,
    required this.rootConcept,
    this.onConceptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Concept Hierarchy: ${rootConcept.title}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            Text(
              'Prerequisites',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: rootConcept.prerequisiteConceptIds
                  .map((id) => ActionChip(
                        avatar: const Icon(Icons.subdirectory_arrow_right,
                            size: 16),
                        label: Text(id),
                        onPressed: () => onConceptSelected?.call(id),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Related Topics',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: rootConcept.relatedTopicIds
                  .map((id) => ActionChip(
                        avatar: const Icon(Icons.link, size: 16),
                        label: Text(id),
                        onPressed: () => onConceptSelected?.call(id),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
