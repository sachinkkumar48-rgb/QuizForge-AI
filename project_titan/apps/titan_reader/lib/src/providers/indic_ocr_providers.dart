import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr/indic_language_pack.dart';
import '../domain/entities/ocr/indic_pack_download_state.dart';
import '../ocr/indic/bilingual_ocr_router.dart';
import '../ocr/indic/indic_ocr_model_loader.dart';
import '../ocr/indic/indic_ocr_session_manager.dart';
import '../ocr/indic/line_script_classifier.dart';
import '../services/indic_language_pack_downloader.dart';
import '../services/indic_language_pack_manager.dart';

/// Provider for the application [IndicLanguagePackManager] coordinator.
final indicLanguagePackManagerProvider =
    Provider<IndicLanguagePackManager>((ref) {
  final manager = IndicLanguagePackManager();
  // Register the foundation descriptor for Hindi by default
  manager.registerPack(IndicLanguagePack.hindiFoundationDescriptor);
  return manager;
});

/// Provider exposing all discovered Indic language packs.
final allIndicPacksProvider = Provider<List<IndicLanguagePack>>((ref) {
  final manager = ref.watch(indicLanguagePackManagerProvider);
  return manager.allPacks;
});

/// Provider exposing only verified, ready-for-inference Indic language packs.
final readyIndicPacksProvider = Provider<List<IndicLanguagePack>>((ref) {
  final manager = ref.watch(indicLanguagePackManagerProvider);
  return manager.readyPacks;
});

/// Provider returning the current state of the Hindi / Devanagari language pack.
final hindiLanguagePackProvider = Provider<IndicLanguagePack>((ref) {
  final manager = ref.watch(indicLanguagePackManagerProvider);
  return manager.getPackByLanguage('hi') ??
      IndicLanguagePack.hindiFoundationDescriptor;
});

/// Provider for the [LineScriptClassifier] instance.
final lineScriptClassifierProvider = Provider<LineScriptClassifier>((ref) {
  return const UnicodeLineScriptClassifier();
});

/// Provider for the [IndicOcrModelLoader] service.
final indicOcrModelLoaderProvider = Provider<IndicOcrModelLoader>((ref) {
  return const DefaultIndicOcrModelLoader();
});

/// Provider for the [IndicOcrSessionManager] coordinator.
final indicOcrSessionManagerProvider = Provider<IndicOcrSessionManager>((ref) {
  final packManager = ref.watch(indicLanguagePackManagerProvider);
  final modelLoader = ref.watch(indicOcrModelLoaderProvider);
  final sessionManager = IndicOcrSessionManager(
    packManager: packManager,
    modelLoader: modelLoader,
    maxActiveSessions: 2,
  );
  ref.onDispose(() {
    sessionManager.disposeAll();
  });
  return sessionManager;
});

/// Provider for the [BilingualOcrRouter] coordinator.
final bilingualOcrRouterProvider = Provider<BilingualOcrRouter>((ref) {
  final classifier = ref.watch(lineScriptClassifierProvider);
  final sessionManager = ref.watch(indicOcrSessionManagerProvider);
  return BilingualOcrRouter(
    classifier: classifier,
    sessionManager: sessionManager,
  );
});

/// Provider exposing the catalog of available Indic OCR language packs.
final indicPackCatalogProvider = Provider<List<IndicLanguagePackSource>>((ref) {
  return IndicLanguagePackSource.defaultCatalog;
});

/// Provider specifying the base directory where language packs are stored.
final indicPacksDirectoryProvider = Provider<String>((ref) {
  return 'indic_ocr_packs';
});

/// Provider for the [IndicLanguagePackDownloader] service.
final indicLanguagePackDownloaderProvider =
    Provider<IndicLanguagePackDownloader>((ref) {
  final packManager = ref.watch(indicLanguagePackManagerProvider);
  final sessionManager = ref.watch(indicOcrSessionManagerProvider);
  return DefaultIndicLanguagePackDownloader(
    packManager: packManager,
    sessionManager: sessionManager,
  );
});

/// StateNotifier coordinating download lifecycle operations for a specific language pack.
class IndicPackDownloadNotifier extends StateNotifier<IndicPackDownloadState> {
  final String languageCode;
  final IndicLanguagePackDownloader downloader;
  final String destinationDirectory;
  final IndicLanguagePackManager packManager;

  StreamSubscription<IndicPackDownloadState>? _subscription;
  bool _isCancelled = false;

  IndicPackDownloadNotifier({
    required this.languageCode,
    required this.downloader,
    required this.destinationDirectory,
    required this.packManager,
  }) : super(_resolveInitialState(languageCode, packManager));

  static IndicPackDownloadState _resolveInitialState(
      String lang, IndicLanguagePackManager manager) {
    final pack = manager.getPackByLanguage(lang);
    if (pack != null && pack.isReady) {
      return IndicPackDownloadState.ready(
        languageCode: lang,
        installedSizeBytes:
            pack.manifest.modelSizeBytes + pack.manifest.dictSizeBytes,
      );
    }
    return IndicPackDownloadState.notInstalled(lang);
  }

  /// Initiates downloading and installing the given language pack.
  void startDownload(IndicLanguagePackSource source) {
    if (state.isInProgress) return;

    _isCancelled = false;
    _subscription?.cancel();

    _subscription = downloader
        .downloadAndInstall(
      source: source,
      destinationPacksDirectory: destinationDirectory,
      isCancelled: () => _isCancelled,
    )
        .listen(
      (nextState) {
        state = nextState;
      },
      onError: (Object e) {
        state = state.copyWith(
          status: IndicPackDownloadStatus.failed,
          errorMessage: 'Download error: $e',
        );
      },
    );
  }

  /// Cancels an in-progress download operation.
  void cancelDownload() {
    _isCancelled = true;
    _subscription?.cancel();
    state = state.copyWith(
      status: IndicPackDownloadStatus.cancelled,
      operationLabel: 'Download cancelled.',
    );
  }

  /// Deletes an installed language pack.
  Future<void> deletePack(IndicLanguagePackSource source) async {
    await downloader.deletePack(
      languageCode: source.languageCode,
      destinationPacksDirectory: destinationDirectory,
    );
    state = IndicPackDownloadState.notInstalled(source.languageCode);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider family exposing the download state for each language code.
final indicPackDownloadStateProvider = StateNotifierProvider.family<
    IndicPackDownloadNotifier, IndicPackDownloadState, String>((ref, langCode) {
  final downloader = ref.watch(indicLanguagePackDownloaderProvider);
  final destinationDirectory = ref.watch(indicPacksDirectoryProvider);
  final packManager = ref.watch(indicLanguagePackManagerProvider);

  return IndicPackDownloadNotifier(
    languageCode: langCode,
    downloader: downloader,
    destinationDirectory: destinationDirectory,
    packManager: packManager,
  );
});
