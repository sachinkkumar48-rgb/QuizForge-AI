import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titan_pdf/titan_pdf.dart';

import '../domain/entities/pdf_manipulation_result.dart';
import '../domain/entities/reader_document.dart';
import '../navigation/reader_routes.dart';
import '../providers/reader_providers.dart';
import '../widgets/document_card.dart';
import '../widgets/merge_pdfs_dialog.dart';

/// Document library: lists all imported PDFs, shows the recent shelf and
/// exposes import / favorite / remove actions.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(libraryDocumentsProvider);
    final recent = ref.watch(recentDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TITAN Reader'),
        actions: [
          IconButton(
            key: const Key('vocabulary-button'),
            tooltip: 'My Vocabulary',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.go(ReaderRoutes.vocabulary),
          ),
          IconButton(
            key: const Key('merge-pdfs-button'),
            tooltip: 'Merge PDFs',
            icon: const Icon(Icons.call_merge),
            onPressed: () => _mergePdfs(context, ref),
          ),
          IconButton(
            tooltip: 'Import PDF',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _importPdf(context, ref),
          ),
        ],
      ),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load library: $error'),
          ),
        ),
        data: (all) => all.isEmpty
            ? _EmptyLibrary(onImport: () => _importPdf(context, ref))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(libraryDocumentsProvider);
                  ref.invalidate(recentDocumentsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    _RecentShelf(recent: recent),
                    const SizedBox(height: 8),
                    for (final document in all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DocumentCard(
                          document: document,
                          onOpen: () => _openDocument(context, ref, document),
                          onToggleFavorite: () =>
                              _toggleFavorite(ref, document),
                          onRemove: () =>
                              _confirmRemove(context, ref, document),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importPdf(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Import PDF'),
      ),
    );
  }

  void _openDocument(
      BuildContext context, WidgetRef ref, ReaderDocument document) {
    context.go(ReaderRoutes.readerFor(document.id));
  }

  Future<void> _mergePdfs(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<PdfManipulationResult>(
      context: context,
      builder: (context) => const MergePdfsDialog(),
    );
    if (result != null && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Merged ${result.pageCount} pages. Saved to ${result.primaryOutputPath}')),
      );
      ref.invalidate(libraryDocumentsProvider);
    }
  }

  Future<void> _toggleFavorite(WidgetRef ref, ReaderDocument document) async {
    await ref.read(libraryServiceProvider).toggleFavorite(document.id);
    ref.invalidate(libraryDocumentsProvider);
    ref.invalidate(recentDocumentsProvider);
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, ReaderDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from library'),
        content:
            Text('Remove "${document.title}" from the library? The PDF file '
                'itself is not deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(libraryServiceProvider).removeDocument(document.id);
    ref.invalidate(libraryDocumentsProvider);
    ref.invalidate(recentDocumentsProvider);
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('File picker unavailable: $error')),
      );
      return;
    }
    final file = result?.files.single;
    if (file == null) return;
    final path = file.path;
    final bytes = file.bytes;
    if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
      return;
    }

    try {
      final headerBytes = bytes != null && bytes.length >= 1024
          ? bytes.sublist(0, 1024)
          : (path != null ? await _readHeaderBytes(path) : bytes);

      final document = await ref.read(libraryServiceProvider).importPickedFile(
            sourceFilePath: path,
            fileBytes: bytes,
            fileName: file.name,
            sizeBytes: file.size,
            at: DateTime.now(),
            headerBytes: headerBytes,
          );
      ref.invalidate(libraryDocumentsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Imported "${document.title}"')),
      );
    } on PdfValidationException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import rejected: ${error.message}')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  /// Reads the first bytes of the file so import validation can check the
  /// PDF magic header and encryption markers without loading the whole file.
  static Future<List<int>?> _readHeaderBytes(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = await file.openRead(0, 1024).first;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

/// Horizontal "Continue reading" shelf driven by the reading history.
class _RecentShelf extends ConsumerWidget {
  final AsyncValue<List<ReaderDocument>> recent;

  const _RecentShelf({required this.recent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = recent.valueOrNull ?? const <ReaderDocument>[];
    if (documents.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Recent', style: theme.textTheme.titleSmall),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final document = documents[index];
              return ActionChip(
                avatar: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: theme.colorScheme.primary,
                ),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () =>
                    context.go(ReaderRoutes.readerFor(document.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Empty state shown before the first document is imported.
class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onImport;

  const _EmptyLibrary({required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Import a PDF to start reading. Documents stay on this '
              'device (LOCAL_ONLY).',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add),
              label: const Text('Import PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
