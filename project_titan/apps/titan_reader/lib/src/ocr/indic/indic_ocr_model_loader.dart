import 'dart:io';

import '../../domain/entities/ocr/indic_language_pack.dart';
import '../../domain/entities/ocr/ocr_error.dart';
import '../../services/indic_language_pack_manager.dart';
import '../onnx/onnx_ocr_engine.dart';
import 'indic_ocr_session_manager.dart';

/// Contract for validating and loading an installed Indic OCR language pack into a runtime session.
abstract class IndicOcrModelLoader {
  /// Validates pack integrity, verifies cryptographic checksums, and loads an active [IndicOcrSession].
  Future<IndicOcrSession> loadModelSession(
    IndicLanguagePack pack, {
    OnnxRunnerFactory? runnerFactory,
  });
}

/// Production implementation of [IndicOcrModelLoader].
///
/// Ensures:
/// - Re-validation of manifest, model weights, and character dictionary prior to runtime activation.
/// - Cryptographic SHA-256 verification matching manifest declarations.
/// - Path security and prohibited file extension validation.
/// - Graceful cleanup with zero leaked native memory allocations on initialization failure.
/// - 100% offline runtime operation without network access or telemetry.
class DefaultIndicOcrModelLoader implements IndicOcrModelLoader {
  const DefaultIndicOcrModelLoader();

  @override
  Future<IndicOcrSession> loadModelSession(
    IndicLanguagePack pack, {
    OnnxRunnerFactory? runnerFactory,
  }) async {
    // 1. Validate status readiness
    if (pack.status != IndicLanguagePackStatus.ready &&
        pack.status != IndicLanguagePackStatus.installed) {
      throw OcrException(
        code: OcrErrorCode.modelUnavailable,
        message:
            'Cannot activate Indic OCR pack "${pack.packId}" with status ${pack.status.name}. Pack must be ready or installed.',
      );
    }

    // 2. Validate manifest completeness
    final manifest = pack.manifest;
    if (manifest.languageCode.trim().isEmpty ||
        manifest.modelFileName.trim().isEmpty ||
        manifest.dictFileName.trim().isEmpty) {
      throw OcrException(
        code: OcrErrorCode.modelUnavailable,
        message:
            'Malformed pack manifest for "${pack.packId}": missing critical language or file descriptors.',
      );
    }

    // 3. If disk assets are specified, perform physical and cryptographic verification
    if (pack.directoryPath != null) {
      final packDir = Directory(pack.directoryPath!);
      if (!await packDir.exists()) {
        throw OcrException(
          code: OcrErrorCode.modelUnavailable,
          message:
              'Language pack directory not found at path: ${pack.directoryPath}.',
        );
      }

      // Validate filenames against directory traversal and prohibited extensions
      try {
        IndicLanguagePackManager.validatePackFileName(
          manifest.modelFileName,
          pack.directoryPath!,
        );
        IndicLanguagePackManager.validatePackFileName(
          manifest.dictFileName,
          pack.directoryPath!,
        );
      } catch (e) {
        throw OcrException(
          code: OcrErrorCode.modelUnavailable,
          message: 'Security validation failed for pack "${pack.packId}": $e',
        );
      }

      // Check model weights file existence and integrity
      if (pack.modelFilePath == null) {
        throw OcrException(
          code: OcrErrorCode.modelUnavailable,
          message: 'Model weights file path unresolved for "${pack.packId}".',
        );
      }

      final modelFile = File(pack.modelFilePath!);
      if (!await modelFile.exists()) {
        throw OcrException(
          code: OcrErrorCode.modelUnavailable,
          message: 'Model weights file not found at: ${pack.modelFilePath}.',
        );
      }

      // Verify SHA-256 of model weights if declared in manifest
      if (manifest.modelSha256.isNotEmpty &&
          manifest.modelSha256 !=
              '0000000000000000000000000000000000000000000000000000000000000000') {
        final modelBytes = await modelFile.readAsBytes();
        final actualSha = Sha256Checksum.hashBytes(modelBytes);
        if (actualSha.toLowerCase() != manifest.modelSha256.toLowerCase()) {
          throw OcrException(
            code: OcrErrorCode.modelUnavailable,
            message:
                'SHA-256 verification failed for model weights in pack "${pack.packId}". Expected: ${manifest.modelSha256}, Actual: $actualSha.',
          );
        }
      }

      // Check dictionary file existence and integrity
      if (pack.dictionaryFilePath == null) {
        throw OcrException(
          code: OcrErrorCode.modelUnavailable,
          message:
              'Character dictionary file path unresolved for "${pack.packId}".',
        );
      }

      final dictFile = File(pack.dictionaryFilePath!);
      if (!await dictFile.exists()) {
        throw OcrException(
          code: OcrErrorCode.modelUnavailable,
          message:
              'Character dictionary file not found at: ${pack.dictionaryFilePath}.',
        );
      }

      // Verify SHA-256 of dictionary if declared in manifest
      if (manifest.dictSha256.isNotEmpty &&
          manifest.dictSha256 !=
              '0000000000000000000000000000000000000000000000000000000000000000') {
        final dictBytes = await dictFile.readAsBytes();
        final actualDictSha = Sha256Checksum.hashBytes(dictBytes);
        if (actualDictSha.toLowerCase() != manifest.dictSha256.toLowerCase()) {
          throw OcrException(
            code: OcrErrorCode.modelUnavailable,
            message:
                'SHA-256 verification failed for character dictionary in pack "${pack.packId}". Expected: ${manifest.dictSha256}, Actual: $actualDictSha.',
          );
        }
      }
    }

    // 4. Instantiate native runner if factory is provided
    OnnxSessionRunner? runner;
    if (runnerFactory != null) {
      try {
        runner = runnerFactory(pack);
        if (pack.modelFilePath != null) {
          await runner.loadSession(pack.modelFilePath!);
        }
      } catch (e) {
        if (runner != null) {
          try {
            await runner.closeSession();
          } catch (_) {}
        }
        throw OcrException(
          code: OcrErrorCode.engineUnavailable,
          message:
              'Failed to initialize ONNX session runner for "${pack.packId}": $e',
        );
      }
    }

    final key = IndicOcrSessionManager.generateSessionKey(pack);
    return IndicOcrSession(
      sessionKey: key,
      pack: pack,
      runner: runner,
    );
  }
}
