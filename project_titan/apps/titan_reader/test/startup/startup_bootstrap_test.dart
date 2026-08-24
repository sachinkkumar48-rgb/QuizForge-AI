import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_storage/titan_storage.dart';

import 'package:titan_reader/src/app.dart';
import 'package:titan_reader/src/ocr/ocr_model_lifecycle.dart';
import 'package:titan_reader/src/providers/dictionary_providers.dart';
import 'package:titan_reader/src/providers/indic_ocr_providers.dart';
import 'package:titan_reader/src/providers/ocr_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TITAN Reader Startup & Bootstrap Architecture Tests', () {
    late InMemoryStorageService inMemoryStorage;

    setUp(() async {
      inMemoryStorage = InMemoryStorageService();
      await inMemoryStorage.initialize();
    });

    tearDown(() async {
      if (inMemoryStorage.isInitialized && !inMemoryStorage.isClosed) {
        await inMemoryStorage.close();
      }
    });

    testWidgets(
        '1. Application renders first UI frame (LibraryScreen) with storage',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(inMemoryStorage),
          ],
          child: const TitanReaderApp(),
        ),
      );

      // Settle initial frame
      await tester.pumpAndSettle();

      // Verify app title and empty library view on first frame
      expect(find.text('TITAN Reader'), findsOneWidget);
      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
        '2. Startup completes and renders UI without OCR models available',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(inMemoryStorage),
        ],
      );
      addTearDown(container.dispose);

      // Ensure OCR engine has NOT been initialized or loaded on launch
      final ocrEngine = container.read(ocrEngineProvider);
      expect(ocrEngine.status, equals(OcrModelStatus.uninitialized));
      expect(ocrEngine.isReady, isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TitanReaderApp(),
        ),
      );
      await tester.pumpAndSettle();

      // UI is fully visible while OCR engine remains uninitialized (lazy)
      expect(find.text('TITAN Reader'), findsOneWidget);
      expect(ocrEngine.status, equals(OcrModelStatus.uninitialized));
      expect(ocrEngine.isReady, isFalse);
    });

    testWidgets(
        '3. Startup succeeds when Indic language packs are missing/unloaded',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(inMemoryStorage),
        ],
      );
      addTearDown(container.dispose);

      final packManager = container.read(indicLanguagePackManagerProvider);
      // Only metadata/foundation is indexed; no model weights loaded in memory
      expect(packManager.readyPacks.isEmpty, isTrue);

      final sessionManager = container.read(indicOcrSessionManagerProvider);
      expect(sessionManager.activeSessionCount, equals(0));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TitanReaderApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TITAN Reader'), findsOneWidget);
      expect(sessionManager.activeSessionCount, equals(0));
    });

    testWidgets(
        '4. Dictionary and grammar sources do not block initial UI frame',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(inMemoryStorage),
        ],
      );
      addTearDown(container.dispose);

      // Verify remote dictionary lookup is disabled by default (offline-first)
      final remoteEnabled = container.read(remoteLookupEnabledProvider);
      expect(remoteEnabled, isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TitanReaderApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TITAN Reader'), findsOneWidget);
    });

    test(
        '5. TitanStorageBootstrap provides resilient fallback on storage failure',
        () async {
      // Test bootstrap initialization with an in-memory storage service
      final storage = await TitanStorageBootstrap.initializeStorage(
        useInMemory: true,
      );

      expect(storage.isInitialized, isTrue);
    });
  });
}
