import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/library_screen.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  late InMemoryStorageService storage;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(home: LibraryScreen()),
    );
  }

  testWidgets('shows the empty state before any import', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('TITAN Reader'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text('Import PDF'), findsWidgets);
  });

  testWidgets('lists imported documents with metadata', (tester) async {
    await seedDocument(storage, title: 'Constitution');
    await seedDocument(storage, title: 'Polity Notes');

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Constitution'), findsOneWidget);
    expect(find.text('Polity Notes'), findsOneWidget);
  });

  testWidgets('shows the Recent shelf for previously opened documents',
      (tester) async {
    await seedDocument(
      storage,
      title: 'Constitution',
      lastOpenedAt: DateTime.utc(2026, 8, 9),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
  });

  testWidgets('favorite toggle persists through the library service',
      (tester) async {
    await seedDocument(storage, title: 'Constitution');

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  });
}

/// Seeds a library document directly through the storage-backed
/// repository so widget tests do not depend on the file picker.
Future<void> seedDocument(
  InMemoryStorageService storage, {
  required String title,
  DateTime? lastOpenedAt,
}) async {
  final service = LibraryService(
    library: StorageDocumentLibraryRepository(storage),
    positions: StorageReadingPositionRepository(storage),
    history: ReadingHistoryService(storage),
  );
  final id = title.toLowerCase().replaceAll(' ', '_');
  final document = await service.importFile(
    filePath: '/tmp/$id.pdf',
    fileName: '$title.pdf',
    sizeBytes: 2048,
    at: DateTime.utc(2026, 8, 1),
  );
  if (lastOpenedAt != null) {
    await service.markOpened(documentId: document.id, at: lastOpenedAt);
  }
}
