import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizforge_upsc/controllers/flashcards_viewmodel.dart';

/// Interactive 3D Flippable Flashcard Widget
class FlashcardCardWidget extends StatefulWidget {
  final FlashcardDto card;
  final bool isFlipped;
  final VoidCallback onFlip;
  final VoidCallback onToggleBookmark;
  final VoidCallback onToggleFavorite;
  final ValueChanged<bool> onMarkKnown;

  const FlashcardCardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onFlip,
    required this.onToggleBookmark,
    required this.onToggleFavorite,
    required this.onMarkKnown,
  });

  @override
  State<FlashcardCardWidget> createState() => _FlashcardCardWidgetState();
}

class _FlashcardCardWidgetState extends State<FlashcardCardWidget> {
  bool _showHint = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final card = widget.card;

    return GestureDetector(
      onTap: widget.onFlip,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0, end: widget.isFlipped ? 180 : 0),
        builder: (context, val, child) {
          final isBack = val >= 90;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(val * pi / 180),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBackCard(context, theme, colorScheme, card),
                  )
                : _buildFrontCard(context, theme, colorScheme, card),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    FlashcardDto card,
  ) {
    return Semantics(
      label: 'Flashcard Front: ${card.question}. Tap to flip card.',
      button: true,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
        ),
        color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge & Icons
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(card.difficulty, colorScheme),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.difficulty.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.topic,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      card.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: card.isBookmarked ? colorScheme.primary : colorScheme.outline,
                    ),
                    onPressed: widget.onToggleBookmark,
                    tooltip: 'Bookmark Flashcard',
                  ),
                  IconButton(
                    icon: Icon(
                      card.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: card.isFavorite ? Colors.redAccent : colorScheme.outline,
                    ),
                    onPressed: widget.onToggleFavorite,
                    tooltip: 'Favorite Flashcard',
                  ),
                ],
              ),
              const Divider(height: 24),
              // Source Citation
              if (card.isPdfGrounded)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 14, color: colorScheme.onSecondaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'PDF: ${card.pdfDocumentName} (Page ${card.pageNumber})',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Generated from Tutor Session',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onTertiaryContainer),
                      ),
                    ],
                  ),
                ),
              // Question Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      card.question,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Hint Toggle
              if (_showHint)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 18, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          card.hint,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    icon: Icon(_showHint ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded, size: 18),
                    label: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
                  ),
                  Text(
                    'Tap card to reveal answer 🔄',
                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    FlashcardDto card,
  ) {
    return Semantics(
      label: 'Flashcard Back Answer: ${card.answer}.',
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.primary, width: 2),
        ),
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ANSWER EXPLANATION',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.flip_to_back_rounded),
                    onPressed: widget.onFlip,
                    tooltip: 'Flip back to Question',
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    card.answer,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ),
              if (card.citation != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Citation: ${card.citation}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Adaptive Revision Quality Actions (SM-2)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onMarkKnown(false),
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      label: const Text('Mark Unknown'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onMarkKnown(true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Mark Known'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
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

  Color _getDifficultyColor(String difficulty, ColorScheme colorScheme) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade600;
      case 'hard':
        return Colors.red.shade600;
      default:
        return Colors.orange.shade700;
    }
  }
}

/// Search, Filter, and Controls Bar Widget
class FlashcardsFilterBarWidget extends StatelessWidget {
  final FlashcardsViewModel viewModel;

  const FlashcardsFilterBarWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: viewModel.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search flashcards...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.shuffle_rounded),
                tooltip: 'Shuffle Flashcards',
                onPressed: viewModel.shuffleCards,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Difficulty: ', style: TextStyle(fontWeight: FontWeight.bold)),
                ...['All', 'Easy', 'Medium', 'Hard'].map((diff) {
                  final selected = viewModel.selectedDifficulty == diff;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(diff),
                      selected: selected,
                      onSelected: (_) => viewModel.setDifficultyFilter(diff),
                    ),
                  );
                }),
                const VerticalDivider(width: 16),
                FilterChip(
                  label: const Text('Bookmarked'),
                  selected: viewModel.filterBookmarkedOnly,
                  onSelected: (_) => viewModel.toggleBookmarkFilter(),
                  avatar: Icon(
                    viewModel.filterBookmarkedOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Favorites'),
                  selected: viewModel.filterFavoritesOnly,
                  onSelected: (_) => viewModel.toggleFavoriteFilter(),
                  avatar: Icon(
                    viewModel.filterFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 16,
                    color: viewModel.filterFavoritesOnly ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart Notes Comprehensive Render Widget
class SmartNotesViewWidget extends StatelessWidget {
  final SmartNoteDto note;

  const SmartNotesViewWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Export/Copy Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topic: ${note.topic}',
                      style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy Smart Notes',
                onPressed: () {
                  final text = '${note.title}\n\n${note.aiSummary}\n\nKey Points:\n${note.keyPoints.join('\n')}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Smart Notes copied to clipboard')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Export Notes',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting Smart Notes as PDF/Markdown...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // PDF Citation Banner or Tutor Source Banner
          if (note.isPdfGrounded)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Source Document: ${note.pdfDocumentName} (Page ${note.pageNumber}) — ${note.citation}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generated from Tutor Session: ${note.tutorSessionTopic ?? note.topic}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // AI Summary Card
          _buildSectionHeader(theme, 'AI Executive Summary', Icons.summarize_rounded),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text(
                note.aiSummary,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Key Points
          _buildSectionHeader(theme, 'Key Takeaways & Points', Icons.check_circle_outline_rounded),
          ...note.keyPoints.map((point) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right_rounded, color: colorScheme.primary),
                    Expanded(child: Text(point, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          // Definitions Grid
          if (note.definitions.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Key Definitions', Icons.menu_book_rounded),
            ...note.definitions.entries.map((def) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: colorScheme.surfaceContainerHigh,
                  child: ListTile(
                    title: Text(def.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(def.value),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          // Timeline Events
          if (note.timeline.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Historical Timeline', Icons.timeline_rounded),
            ...note.timeline.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['year'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['event'] ?? '')),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
          // Table Data
          if (note.tableData.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Comparative Reference Table', Icons.table_chart_rounded),
            Table(
              border: TableBorder.all(color: colorScheme.outlineVariant),
              children: note.tableData.asMap().entries.map((entry) {
                final isHeader = entry.key == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isHeader ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                  ),
                  children: entry.value
                      .map((cell) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              cell,
                              style: TextStyle(
                                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ))
                      .toList(),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // Quotes Callout
          if (note.importantQuotes.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Important Judicial & Expert Quotes', Icons.format_quote_rounded),
            ...note.importantQuotes.map((q) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: colorScheme.primary, width: 4)),
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    q,
                    style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          // Revision Quick Notes
          _buildSectionHeader(theme, 'Revision Notes (SM-2 Queue Compatible)', Icons.rate_review_rounded),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(note.revisionNotes, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
