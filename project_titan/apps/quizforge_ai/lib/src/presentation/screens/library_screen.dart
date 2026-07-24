import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';
import '../providers/library_controller.dart';
import '../states/library_state.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_card.dart';
import '../widgets/library/continue_reading_card.dart';
import '../widgets/library/document_card.dart';
import '../widgets/library/favorites_card.dart';
import '../widgets/library/folder_card.dart';
import '../widgets/library/library_search_bar.dart';
import '../widgets/loading_screen.dart';
import '../widgets/responsive_layout.dart';

/// Digital Library MVP Screen presenting PDF documents, folders, favorites, and search.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryControllerProvider.notifier).loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => context.pushNamed(AppRoutes.importPdf),
            tooltip: 'Import PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(libraryControllerProvider.notifier).loadLibrary(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, theme, state),
        desktop: Center(
          child: SizedBox(
            width: 800,
            child: _buildBody(context, theme, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, LibraryState state) {
    if (state.isLoading && state.documents.isEmpty) {
      return const LoadingScreen(message: 'Loading Digital Library...');
    }

    if (state.isError && state.documents.isEmpty) {
      return Padding(
        padding: AppSpacing.paddingLg,
        child: Center(
          child: ErrorCard(
            message: state.errorMessage ?? 'Unable to load Digital Library.',
            onRetry: () =>
                ref.read(libraryControllerProvider.notifier).loadLibrary(),
          ),
        ),
      );
    }

    final controller = ref.read(libraryControllerProvider.notifier);

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter
          LibrarySearchBar(
            searchQuery: state.searchQuery,
            selectedCategory: state.selectedCategory,
            onSearchChanged: (q) => controller.searchDocuments(q),
            onCategorySelected: (cat) => controller.selectCategory(cat),
            onClearSearch: () => controller.searchDocuments(''),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Continue Reading Section
          if (state.continueReadingDocuments.isNotEmpty) ...[
            ContinueReadingCard(
              document: state.continueReadingDocuments.first,
              onResume: () {
                // Resume reading action handler
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Favorites Section
          if (state.favoriteDocuments.isNotEmpty) ...[
            FavoritesCard(
              favorites: state.favoriteDocuments,
              onDocumentTap: (doc) {
                // Open document
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Folders Section
          if (state.folders.isNotEmpty) ...[
            Text(
              'Folders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.folders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final folder = state.folders[index];
                  return SizedBox(
                    width: 180,
                    child: FolderCard(
                      folder: folder,
                      onTap: () {
                        controller.selectCategory(folder.category);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Documents List Section
          Text(
            'All Documents (${state.documents.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.documents.isEmpty)
            const EmptyState(
              title: 'No Documents Found',
              message: 'Try adjusting your search query or category filter.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.documents.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final doc = state.documents[index];
                return DocumentCard(
                  document: doc,
                  onFavoriteToggle: () => controller.toggleFavorite(doc.id),
                  onTap: () {
                    // Document tap action
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
