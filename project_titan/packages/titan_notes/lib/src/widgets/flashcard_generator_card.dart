import 'package:flutter/material.dart';

/// Material 3 Flashcard Generator Card component.
class FlashcardGeneratorCard extends StatelessWidget {
  final List<Map<String, String>> flashcards;
  final VoidCallback onGenerate;

  const FlashcardGeneratorCard({
    super.key,
    required this.flashcards,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Flashcards (${flashcards.length})',
                    style: theme.textTheme.titleMedium),
                ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (flashcards.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Q: ${flashcards.first['front']}',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text('A: ${flashcards.first['back']}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
