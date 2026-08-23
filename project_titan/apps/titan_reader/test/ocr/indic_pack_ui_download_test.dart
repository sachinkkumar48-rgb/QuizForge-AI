import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/domain/entities/ocr/indic_language_pack.dart';
import 'package:titan_reader/src/domain/entities/ocr/indic_pack_download_state.dart';
import 'package:titan_reader/src/ocr/indic/indic_ocr_session_manager.dart';
import 'package:titan_reader/src/providers/indic_ocr_providers.dart';
import 'package:titan_reader/src/services/indic_language_pack_downloader.dart';
import 'package:titan_reader/src/services/indic_language_pack_manager.dart';
import 'package:titan_reader/src/widgets/indic_ocr_settings_dialog.dart';

void main() {
  group('Phase 7B: Indic OCR Language Pack UI & Download Management Tests', () {
    late Directory tempRootDir;
    late IndicLanguagePackManager packManager;
    late IndicOcrSessionManager sessionManager;
    late DefaultIndicLanguagePackDownloader downloader;

    setUp(() async {
      tempRootDir =
          await Directory.systemTemp.createTemp('titan_pack_ui_test_');
      packManager = IndicLanguagePackManager(platform: 'windows');
      sessionManager = IndicOcrSessionManager(
        packManager: packManager,
        maxActiveSessions: 2,
      );
      downloader = DefaultIndicLanguagePackDownloader(
        packManager: packManager,
        sessionManager: sessionManager,
      );
    });

    tearDown(() async {
      if (await tempRootDir.exists()) {
        await tempRootDir.delete(recursive: true);
      }
    });

    test(
        '1. Pack catalog contains all 10 planned Indic languages with Hindi first',
        () {
      const catalog = IndicLanguagePackSource.defaultCatalog;
      expect(catalog.length, 10);
      expect(catalog.first.languageCode, 'hi');
      expect(catalog.first.languageName, 'Hindi');
      expect(catalog.first.scriptName, 'Devanagari');
      expect(catalog.first.isComingSoon, isFalse);

      final languageCodes = catalog.map((c) => c.languageCode).toList();
      expect(
          languageCodes,
          containsAll(
              ['hi', 'bn', 'ta', 'te', 'kn', 'ml', 'gu', 'pa', 'or', 'ur']));
    });

    test(
        '2. Hindi pack metadata exposes correct version and Apache-2.0 license',
        () {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      expect(hindiSource.packId, 'titan-ocr-indic-hindi');
      expect(hindiSource.version, '1.0.0');
      expect(hindiSource.licenseType, 'Apache-2.0');
      expect(hindiSource.licenseUrl, isNotNull);
      expect(hindiSource.downloadSizeBytes, greaterThan(1000000));
    });

    test('3. Initial download state is notInstalled', () {
      final state = IndicPackDownloadState.notInstalled('hi');
      expect(state.status, IndicPackDownloadStatus.notInstalled);
      expect(state.isReady, isFalse);
      expect(state.isInProgress, isFalse);
      expect(state.progressRatio, 0.0);
    });

    test(
        '4. Successful download, SHA-256 verification, and atomic installation',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      final states = <IndicPackDownloadState>[];

      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
      )) {
        states.add(state);
      }

      // Verify sequence of lifecycle states
      expect(states.any((s) => s.status == IndicPackDownloadStatus.checking),
          isTrue);
      expect(states.any((s) => s.status == IndicPackDownloadStatus.downloading),
          isTrue);
      expect(states.any((s) => s.status == IndicPackDownloadStatus.verifying),
          isTrue);
      expect(states.any((s) => s.status == IndicPackDownloadStatus.installing),
          isTrue);
      expect(states.last.status, IndicPackDownloadStatus.ready);
      expect(states.last.isReady, isTrue);

      // Verify pack is registered in packManager as ready
      final registeredPack = packManager.getPackByLanguage('hi');
      expect(registeredPack, isNotNull);
      expect(registeredPack!.status, IndicLanguagePackStatus.ready);

      // Verify destination folder exists and temp folder is removed
      final finalPackDir =
          Directory(p.join(tempRootDir.path, hindiSource.packId));
      expect(await finalPackDir.exists(), isTrue);

      final tempDirs = tempRootDir
          .listSync()
          .where((f) => p.basename(f.path).startsWith('.tmp_'));
      expect(tempDirs, isEmpty);
    });

    test(
        '5. Cancellation stops download, cleans temp directory, and emits cancelled state',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      bool cancelFlag = false;
      final states = <IndicPackDownloadState>[];

      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
        isCancelled: () {
          if (cancelFlag) return true;
          cancelFlag = true;
          return true;
        },
      )) {
        states.add(state);
      }

      expect(states.last.status, IndicPackDownloadStatus.cancelled);

      // Verify no temporary files remain
      final remaining = tempRootDir.listSync();
      expect(remaining, isEmpty);

      // Verify pack not registered as ready
      final registered = packManager.getPackByLanguage('hi');
      expect(registered?.isReady ?? false, isFalse);
    });

    test(
        '6. SHA-256 checksum mismatch rejects corrupted download and cleans temp files',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      final states = <IndicPackDownloadState>[];

      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
        customPayloadFetcher: (source) async {
          // Deliver corrupt model bytes with invalid hash
          final modelBytes = utf8.encode('CORRUPT_MODEL_PAYLOAD');
          final dictBytes = utf8.encode('a\nb\nc\n');

          final manifestMap = {
            'manifestVersion': '1.0.0',
            'packId': source.packId,
            'displayName': source.displayName,
            'languageCode': source.languageCode,
            'languageName': source.languageName,
            'scriptCode': source.scriptCode,
            'scriptName': source.scriptName,
            'engineVersion': '1.0.0',
            'modelVersion': source.version,
            'modelFormat': 'onnx',
            'quantization': 'int8',
            'modelFileName': 'model.onnx',
            'modelSizeBytes': modelBytes.length,
            'modelSha256':
                'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
            'dictFileName': 'dict.txt',
            'dictSizeBytes': dictBytes.length,
            'dictSha256': Sha256Checksum.hashBytes(dictBytes),
            'licenseType': 'Apache-2.0',
            'minimumAppVersion': '0.1.0',
            'supportedPlatforms': [
              'windows',
              'macos',
              'linux',
              'android',
              'ios'
            ],
          };

          return {
            'manifest.json': utf8.encode(jsonEncode(manifestMap)),
            'model.onnx': modelBytes,
            'dict.txt': dictBytes,
          };
        },
      )) {
        states.add(state);
      }

      expect(states.last.status, IndicPackDownloadStatus.corrupted);
      expect(states.last.errorMessage, contains('checksum'));

      // Verify temp folder was deleted
      final tempDirs = tempRootDir
          .listSync()
          .where((f) => p.basename(f.path).startsWith('.tmp_'));
      expect(tempDirs, isEmpty);
    });

    test(
        '7. Insufficient storage emits insufficientStorage state before download begins',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      final states = <IndicPackDownloadState>[];

      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
        availableStorageBytes: 1024, // only 1 KB available
      )) {
        states.add(state);
      }

      expect(states.last.status, IndicPackDownloadStatus.insufficientStorage);
      expect(states.last.errorMessage, contains('Insufficient storage'));
    });

    test('8. Deletion removes pack files and disposes active session',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;

      // 1. Install pack
      await for (final _ in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
      )) {}

      // 2. Initialize active session
      final session = await sessionManager.getOrCreateSession('hi');
      expect(sessionManager.activeSessionCount, 1);
      expect(session.pack.languageCode, 'hi');

      // 3. Delete pack
      await downloader.deletePack(
        languageCode: 'hi',
        destinationPacksDirectory: tempRootDir.path,
      );

      // Session must be disposed and removed
      expect(sessionManager.activeSessionCount, 0);

      // Pack directory must not exist on disk
      final packDir = Directory(p.join(tempRootDir.path, hindiSource.packId));
      expect(await packDir.exists(), isFalse);

      // Pack status in manager should be notInstalled
      final pack = packManager.getPackByLanguage('hi');
      expect(pack?.isReady ?? false, isFalse);
    });

    test('9. Retry starts from clean temporary state', () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;

      // First attempt: fail via cancellation
      await for (final _ in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
        isCancelled: () => true,
      )) {}

      // Second attempt (retry): succeeds cleanly
      final retryStates = <IndicPackDownloadState>[];
      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
      )) {
        retryStates.add(state);
      }

      expect(retryStates.last.status, IndicPackDownloadStatus.ready);
      expect(packManager.getPackByLanguage('hi')?.isReady, isTrue);
    });

    testWidgets(
        '10. IndicOcrSettingsDialog renders header, storage, and catalog items',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          indicPacksDirectoryProvider.overrideWithValue(tempRootDir.path),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: IndicOcrSettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Subtitle
      expect(find.text('Indic OCR Languages'), findsOneWidget);
      expect(find.textContaining('Manage on-device neural language models'),
          findsOneWidget);

      // Verify Storage summary
      expect(find.textContaining('Installed Packs:'), findsOneWidget);
      expect(find.textContaining('Storage:'), findsOneWidget);

      // Verify Hindi Pack row
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('Devanagari'), findsOneWidget);
      expect(find.text('Apache-2.0'), findsWidgets);
      expect(find.text('Download'), findsWidgets);

      // Verify Coming Soon packs
      expect(find.text('Bengali'), findsWidgets);
      expect(find.text('Coming Soon'), findsWidgets);
    });

    test(
        '11. Security: Path traversal in payload filename is rejected during installation',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      final states = <IndicPackDownloadState>[];

      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
        customPayloadFetcher: (source) async {
          return {
            '../../../etc/passwd': utf8.encode('malicious'),
          };
        },
      )) {
        states.add(state);
      }

      expect(states.last.status, IndicPackDownloadStatus.failed);
      expect(states.last.errorMessage, contains('traversal'));
    });

    test(
        '12. Security: Dangerous executable extension is rejected during installation',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      final states = <IndicPackDownloadState>[];

      await for (final state in downloader.downloadAndInstall(
        source: hindiSource,
        destinationPacksDirectory: tempRootDir.path,
        customPayloadFetcher: (source) async {
          return {
            'payload.exe': utf8.encode('executable_bytes'),
          };
        },
      )) {
        states.add(state);
      }

      expect(states.last.status, IndicPackDownloadStatus.failed);
      expect(states.last.errorMessage?.toLowerCase(), contains('prohibited'));
    });

    test('13. IndicPackDownloadNotifier manages state transitions and deletion',
        () async {
      final hindiSource = IndicLanguagePackSource.defaultCatalog.first;
      final notifier = IndicPackDownloadNotifier(
        languageCode: 'hi',
        downloader: downloader,
        destinationDirectory: tempRootDir.path,
        packManager: packManager,
      );

      expect(notifier.state.status, IndicPackDownloadStatus.notInstalled);

      // Start download
      notifier.startDownload(hindiSource);

      // Await until download completes or transitions to ready
      var maxLoops = 60;
      while (!notifier.state.isReady && maxLoops > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        maxLoops--;
      }

      expect(notifier.state.isReady, isTrue);

      // Delete pack
      await notifier.deletePack(hindiSource);
      expect(notifier.state.status, IndicPackDownloadStatus.notInstalled);

      notifier.dispose();
    });

    testWidgets('14. IndicOcrSettingsDialog reacts to download state changes',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          indicPacksDirectoryProvider.overrideWithValue(tempRootDir.path),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: IndicOcrSettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Download on Hindi pack
      final downloadBtn = find.widgetWithText(FilledButton, 'Download');
      expect(downloadBtn, findsWidgets);

      await tester.runAsync(() async {
        await tester.tap(downloadBtn.first);
        // Wait for async stream and file I/O to complete
        var maxLoops = 60;
        final notifier =
            container.read(indicPackDownloadStateProvider('hi').notifier);
        while (!notifier.state.isReady && maxLoops > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          maxLoops--;
        }
      });

      await tester.pumpAndSettle();

      expect(find.text('Installed'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
