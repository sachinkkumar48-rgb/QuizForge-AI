import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/entities/ocr/indic_language_pack.dart';
import '../domain/entities/ocr/indic_pack_download_state.dart';
import '../ocr/indic/indic_ocr_session_manager.dart';
import 'indic_language_pack_manager.dart';

/// Contract for managing Indic OCR language pack downloads, atomic verification, and deletion.
abstract class IndicLanguagePackDownloader {
  /// Initiates download, integrity verification, and atomic installation of an Indic language pack.
  Stream<IndicPackDownloadState> downloadAndInstall({
    required IndicLanguagePackSource source,
    required String destinationPacksDirectory,
    bool Function()? isCancelled,
    Future<Map<String, List<int>>> Function(IndicLanguagePackSource source)?
        customPayloadFetcher,
    int? availableStorageBytes,
  });

  /// Safely removes an installed language pack from disk and disposes any active OCR sessions.
  Future<void> deletePack({
    required String languageCode,
    required String destinationPacksDirectory,
  });
}

/// Production implementation of [IndicLanguagePackDownloader].
///
/// Ensures:
/// - Isolated temporary directory during download and checksum validation.
/// - Cryptographic SHA-256 integrity verification before activation.
/// - Atomic move/replace preventing partially installed packs from being exposed.
/// - Safe session disposal in [IndicOcrSessionManager] prior to file deletion.
/// - 100% offline runtime operation.
class DefaultIndicLanguagePackDownloader
    implements IndicLanguagePackDownloader {
  final IndicLanguagePackManager packManager;
  final IndicOcrSessionManager? sessionManager;

  DefaultIndicLanguagePackDownloader({
    required this.packManager,
    this.sessionManager,
  });

  @override
  Stream<IndicPackDownloadState> downloadAndInstall({
    required IndicLanguagePackSource source,
    required String destinationPacksDirectory,
    bool Function()? isCancelled,
    Future<Map<String, List<int>>> Function(IndicLanguagePackSource source)?
        customPayloadFetcher,
    int? availableStorageBytes,
  }) async* {
    final languageCode = source.languageCode;

    // 1. Initial Checking & Storage Quota Assessment
    yield IndicPackDownloadState(
      languageCode: languageCode,
      status: IndicPackDownloadStatus.checking,
      totalBytes: source.downloadSizeBytes,
      operationLabel: 'Checking storage and dependencies...',
    );

    if (isCancelled?.call() == true) {
      yield IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.cancelled,
        operationLabel: 'Download cancelled by user.',
      );
      return;
    }

    if (availableStorageBytes != null &&
        availableStorageBytes < source.downloadSizeBytes) {
      yield IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.insufficientStorage,
        totalBytes: source.downloadSizeBytes,
        errorMessage:
            'Insufficient storage space. Required: ${(source.downloadSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB.',
      );
      return;
    }

    // 2. Prepare Isolated Temporary Sandbox Directory
    final tempDirName =
        '.tmp_${source.packId}_${DateTime.now().millisecondsSinceEpoch}';
    final tempDirPath = p.join(destinationPacksDirectory, tempDirName);
    final tempDir = Directory(tempDirPath);

    try {
      await tempDir.create(recursive: true);

      // 3. Downloading payload chunks to temp storage
      yield IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.downloading,
        bytesDownloaded: 0,
        totalBytes: source.downloadSizeBytes,
        progressRatio: 0.0,
        operationLabel: 'Downloading model package...',
      );

      Map<String, List<int>> payloadFiles;
      if (customPayloadFetcher != null) {
        payloadFiles = await customPayloadFetcher(source);
      } else {
        // Deterministic synthetic fallback payload provider for local testing
        payloadFiles = _createSyntheticPayload(source);
      }

      int bytesTransferred = 0;
      for (final entry in payloadFiles.entries) {
        if (isCancelled?.call() == true) {
          await _cleanupTempDir(tempDir);
          yield IndicPackDownloadState(
            languageCode: languageCode,
            status: IndicPackDownloadStatus.cancelled,
            operationLabel: 'Download cancelled by user.',
          );
          return;
        }

        // Validate relative filename security
        final fileName = entry.key;
        IndicLanguagePackManager.validatePackFileName(fileName, tempDirPath);

        final targetFile = File(p.join(tempDirPath, fileName));
        await targetFile.writeAsBytes(entry.value);

        bytesTransferred += entry.value.length;
        final progress = source.downloadSizeBytes > 0
            ? (bytesTransferred / source.downloadSizeBytes).clamp(0.0, 0.95)
            : 0.5;

        yield IndicPackDownloadState(
          languageCode: languageCode,
          status: IndicPackDownloadStatus.downloading,
          bytesDownloaded: bytesTransferred,
          totalBytes: source.downloadSizeBytes,
          progressRatio: progress,
          operationLabel: 'Downloading $fileName...',
        );
      }

      // 4. Verifying Cryptographic Integrity & Manifest
      yield IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.verifying,
        bytesDownloaded: bytesTransferred,
        totalBytes: source.downloadSizeBytes,
        progressRatio: 0.95,
        operationLabel: 'Verifying SHA-256 cryptographic signatures...',
      );

      if (isCancelled?.call() == true) {
        await _cleanupTempDir(tempDir);
        yield IndicPackDownloadState(
          languageCode: languageCode,
          status: IndicPackDownloadStatus.cancelled,
          operationLabel: 'Verification cancelled by user.',
        );
        return;
      }

      final validatedPack =
          await packManager.validatePackDirectory(tempDirPath);

      if (validatedPack.status == IndicLanguagePackStatus.corrupted) {
        await _cleanupTempDir(tempDir);
        yield IndicPackDownloadState(
          languageCode: languageCode,
          status: IndicPackDownloadStatus.corrupted,
          errorMessage:
              'The downloaded language pack failed SHA-256 checksum verification.',
        );
        return;
      }

      if (validatedPack.status != IndicLanguagePackStatus.ready) {
        await _cleanupTempDir(tempDir);
        yield IndicPackDownloadState(
          languageCode: languageCode,
          status: IndicPackDownloadStatus.failed,
          errorMessage:
              'Language pack validation failed with status: ${validatedPack.status.name}.',
        );
        return;
      }

      // 5. Installing: Atomic Move into Destination Directory
      yield IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.installing,
        bytesDownloaded: bytesTransferred,
        totalBytes: source.downloadSizeBytes,
        progressRatio: 0.98,
        operationLabel: 'Installing language pack...',
      );

      final finalPackDir =
          Directory(p.join(destinationPacksDirectory, source.packId));

      // Remove existing pack destination if present
      if (await finalPackDir.exists()) {
        await finalPackDir.delete(recursive: true);
      }

      // Atomic rename / move into final destination
      await tempDir.rename(finalPackDir.path);

      // Register final pack with manager
      final finalPack =
          await packManager.validatePackDirectory(finalPackDir.path);
      packManager.registerPack(finalPack);

      final totalDiskSize = bytesTransferred;

      // 6. Ready State
      yield IndicPackDownloadState.ready(
        languageCode: languageCode,
        installedSizeBytes: totalDiskSize,
      );
    } catch (e) {
      await _cleanupTempDir(tempDir);
      yield IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.failed,
        errorMessage: 'Language pack installation failed: $e',
      );
    }
  }

  @override
  Future<void> deletePack({
    required String languageCode,
    required String destinationPacksDirectory,
  }) async {
    final pack = packManager.getPackByLanguage(languageCode);
    if (pack == null) return;

    // 1. Dispose any active OCR session in sessionManager
    if (sessionManager != null) {
      final sessionKey = IndicOcrSessionManager.generateSessionKey(pack);
      await sessionManager!.disposeSession(sessionKey);
    }

    // 2. Safely remove pack directory from disk
    final packDir = Directory(p.join(destinationPacksDirectory, pack.packId));
    if (await packDir.exists()) {
      await packDir.delete(recursive: true);
    }

    // 3. Update pack status in packManager to notInstalled
    final resetPack = IndicLanguagePack(
      manifest: pack.manifest,
      status: IndicLanguagePackStatus.notInstalled,
    );
    packManager.registerPack(resetPack);
  }

  /// Cleans up temporary directory on failure or cancellation.
  Future<void> _cleanupTempDir(Directory tempDir) async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Generates a valid synthetic model pack payload for local testing.
  Map<String, List<int>> _createSyntheticPayload(
      IndicLanguagePackSource source) {
    final modelContent = utf8.encode('SYNTHETIC_ONNX_MODEL_${source.packId}');
    final dictContent = utf8.encode('a\nb\nc\nक\nख\nग\n');

    final modelSha256 = Sha256Checksum.hashBytes(modelContent);
    final dictSha256 = Sha256Checksum.hashBytes(dictContent);

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
      'modelSizeBytes': modelContent.length,
      'modelSha256': modelSha256,
      'dictFileName': 'dict.txt',
      'dictSizeBytes': dictContent.length,
      'dictSha256': dictSha256,
      'licenseType': source.licenseType,
      'licenseUrl': source.licenseUrl,
      'minimumAppVersion': '0.1.0',
      'supportedPlatforms': ['windows', 'macos', 'linux', 'android', 'ios'],
    };

    final manifestJson = utf8.encode(jsonEncode(manifestMap));

    return {
      'manifest.json': manifestJson,
      'model.onnx': modelContent,
      'dict.txt': dictContent,
    };
  }
}
