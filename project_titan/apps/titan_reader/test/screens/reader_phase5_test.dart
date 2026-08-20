import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/document_library_repository.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/data/reading_position_repository.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/providers/ai_reading_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/reader_screen.dart';
import 'package:titan_reader/src/services/ai_reading_service.dart';
import 'package:titan_reader/src/services/library_service.dart';
import 'package:titan_reader/src/services/reading_history_service.dart';
import 'package:titan_storage/titan_storage.dart';

import '../support/fake_pdf_engine.dart';

const List<int> pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];
const String fakePdfPath = '/titan/reader/fixtures/sample.pdf';

void main() {
  late InMemoryStorageService storage;
  late FakePdfEngine engine;
  late MockAIReadingProvider mockProvider;

  setUp(() async {
    storage = InMemoryStorageService();
    await storage.initialize();
    engine = FakePdfEngine();
    mockProvider = MockAIReadingProvider();
  });

  LibraryService service() => LibraryService(
        library: StorageDocumentLibraryRepository(storage),
        positions: StorageReadingPositionRepository(storage),
        history: ReadingHistoryService(storage),
      );

  Widget buildSubject(String documentId) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        pdfEngineProvider.overrideWithValue(engine),
        aiReadingServiceProvider.overrideWith((ref) {
          final configRepo = ref.watch(aiConfigRepositoryProvider);
          final cacheRepo = ref.watch(aiCacheRepositoryProvider);
          final convRepo = ref.watch(aiConversationRepositoryProvider);
          final flashcardRepo = ref.watch(aiFlashcardRepositoryProvider);
          return AIReadingService(
            configRepo: configRepo,
            cacheRepo: cacheRepo,
            conversationRepo: convRepo,
            flashcardRepo: flashcardRepo,
            providers: {
              AIProviderType.localOllama: mockProvider,
              AIProviderType.mock: mockProvider,
            },
            initialConfig: const AIConfig(providerType: AIProviderType.mock),
          );
        }),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: documentId,
          fileExists: (path) => true,
        ),
      ),
    );
  }

  testWidgets('ReaderScreen renders AI Assistant button in AppBar',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    expect(find.byKey(const Key('ai-assistant-button')), findsOneWidget);
  });

  testWidgets('Tapping AI Assistant button opens AI Assistant bottom sheet',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    await tester.tap(find.byKey(const Key('ai-assistant-button')));
    await tester.pumpAndSettle();

    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.byKey(const Key('ai-panel-model-badge')), findsOneWidget);
  });

  testWidgets(
      'Selection actions includes Explain, Simplify, Ask AI, and Summarize',
      (tester) async {
    final libraryService = service();
    final document = await libraryService.importFile(
      filePath: fakePdfPath,
      fileName: 'sample.pdf',
      sizeBytes: 1024,
      at: DateTime.utc(2026, 8, 1),
      headerBytes: pdfHeader,
    );

    await tester.pumpWidget(buildSubject(document.id));
    await tester.pump();

    final handle = engine.lastHandle!;
    final actionIds =
        handle.lastSettings!.selectionActions.map((a) => a.id).toList();

    expect(actionIds, contains('explain'));
    expect(actionIds, contains('simplify'));
    expect(actionIds, contains('ask-ai'));
    expect(actionIds, contains('summarize'));
  });
}
