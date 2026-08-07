import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizforge_upsc/controllers/flashcards_viewmodel.dart';
import 'package:quizforge_upsc/widgets/flashcards_widgets.dart';

/// GARUDA AI Flashcards & Smart Notes Production Learner-Facing Page
class FlashcardsPage extends StatefulWidget {
  final FlashcardsViewModel viewModel;

  const FlashcardsPage({
    super.key,
    required this.viewModel,
  });

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.viewModel.loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        widget.viewModel.nextCard();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        widget.viewModel.previousCard();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        widget.viewModel.flipCard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = widget.viewModel;

    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GARUDA Flashcards & Smart Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    vm.pdfDocumentId != null ? 'PDF Grounded Workspace' : 'GARUDA Tutor Workspace',
                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.style_rounded), text: 'AI Flashcards'),
                  Tab(icon: Icon(Icons.note_alt_rounded), text: 'Smart Notes'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reload Data',
                  onPressed: vm.loadData,
                ),
              ],
            ),
            body: vm.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating AI Flashcards & Smart Notes...'),
                      ],
                    ),
                  )
                : vm.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                            const SizedBox(height: 12),
                            Text(vm.errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: vm.loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: AI Flashcards
                          Column(
                            children: [
                              FlashcardsFilterBarWidget(viewModel: vm),
                              if (vm.flashcards.isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.style_outlined, size: 48, color: colorScheme.outline),
                                        const SizedBox(height: 12),
                                        const Text('No flashcards found matching filters.'),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Progress Indicator Bar
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Card ${vm.currentIndex + 1} of ${vm.flashcards.length}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              'SM-2 Interval: ${vm.currentCard?.intervalDays ?? 1}d',
                                              style: theme.textTheme.labelMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: (vm.currentIndex + 1) / vm.flashcards.length,
                                        backgroundColor: colorScheme.surfaceContainerHighest,
                                      ),
                                      const SizedBox(height: 12),
                                      // Flashcard View Area
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: vm.currentCard != null
                                              ? FlashcardCardWidget(
                                                  card: vm.currentCard!,
                                                  isFlipped: vm.isFlipped,
                                                  onFlip: vm.flipCard,
                                                  onToggleBookmark: vm.toggleBookmark,
                                                  onToggleFavorite: vm.toggleFavorite,
                                                  onMarkKnown: (known) => vm.markCardKnown(known: known),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ),
                                      // Card Navigation Controls
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: vm.previousCard,
                                              icon: const Icon(Icons.arrow_back_rounded),
                                              label: const Text('Previous'),
                                            ),
                                            IconButton.filled(
                                              onPressed: vm.flipCard,
                                              icon: const Icon(Icons.flip_rounded),
                                              tooltip: 'Flip Card (Spacebar)',
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: vm.nextCard,
                                              icon: const Icon(Icons.arrow_forward_rounded),
                                              label: const Text('Next'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          // Tab 2: Smart Notes View
                          vm.smartNote != null
                              ? SmartNotesViewWidget(note: vm.smartNote!)
                              : const Center(child: Text('No Smart Notes available.')),
                        ],
                      ),
          ),
        );
      },
    );
  }
}
