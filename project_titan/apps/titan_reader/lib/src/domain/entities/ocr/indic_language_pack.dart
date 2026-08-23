import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../../ocr/ocr_model_lifecycle.dart';

/// Operational lifecycle state of an Indic OCR language pack.
enum IndicLanguagePackStatus {
  /// Pack metadata exists but files are not present locally.
  notInstalled,

  /// Pack files are currently being transferred or unpacked.
  installing,

  /// Files are present on disk but have not been integrity-verified.
  installed,

  /// Manifest, checksums, and structure are actively validating.
  validating,

  /// Pack has passed all integrity gates and is verified ready for inference.
  ready,

  /// Pack failed cryptographic verification or structural assertions.
  corrupted,

  /// Model format or engine version is incompatible with current reader.
  incompatible,

  /// Target platform is not supported by this model pack.
  unsupported,

  /// Pack installation, validation, or file access failed critically.
  failed,
}

/// Strongly-typed manifest representation for a `.titanpack` Indic language pack.
@immutable
class IndicPackManifest {
  /// Schema specification version of this manifest (e.g. '1.0.0').
  final String manifestVersion;

  /// Unique canonical identifier for the pack (e.g. 'titan-ocr-indic-hindi').
  final String packId;

  /// Human-readable display title (e.g. 'Hindi (Devanagari) OCR Pack').
  final String displayName;

  /// BCP-47 / ISO 639-1 language code (e.g. 'hi', 'bn', 'ta').
  final String languageCode;

  /// Human-readable language name in English (e.g. 'Hindi').
  final String languageName;

  /// ISO 15924 script code (e.g. 'Deva', 'Beng', 'Taml', 'Telu').
  final String scriptCode;

  /// Human-readable script name (e.g. 'Devanagari').
  final String scriptName;

  /// Minimum compatible OCR engine version (e.g. '1.0.0').
  final String engineVersion;

  /// Model version string (e.g. '1.0.0').
  final String modelVersion;

  /// Model serialization format ('onnx', 'tflite').
  final String modelFormat;

  /// Quantization level ('int8', 'fp16', 'fp32').
  final String quantization;

  /// Relative file name of the neural weights within the pack (e.g. 'model.onnx').
  final String modelFileName;

  /// Expected file size of the model weights in bytes.
  final int modelSizeBytes;

  /// Expected SHA-256 cryptographic hash of the model weights file.
  final String modelSha256;

  /// Relative file name of the character dictionary mapping (e.g. 'dict.txt').
  final String dictFileName;

  /// Expected file size of the dictionary file in bytes.
  final int dictSizeBytes;

  /// Expected SHA-256 cryptographic hash of the dictionary file.
  final String dictSha256;

  /// Software license identifier ('Apache-2.0', 'MIT', 'CC-BY-4.0').
  final String licenseType;

  /// URL pointing to the model's upstream repository or license text.
  final String? licenseUrl;

  /// Minimum TITAN app version required to run this pack.
  final String minimumAppVersion;

  /// List of supported operating system identifiers ('windows', 'macos', 'linux', 'android', 'ios').
  final List<String> supportedPlatforms;

  const IndicPackManifest({
    required this.manifestVersion,
    required this.packId,
    required this.displayName,
    required this.languageCode,
    required this.languageName,
    required this.scriptCode,
    required this.scriptName,
    required this.engineVersion,
    required this.modelVersion,
    required this.modelFormat,
    required this.quantization,
    required this.modelFileName,
    required this.modelSizeBytes,
    required this.modelSha256,
    required this.dictFileName,
    required this.dictSizeBytes,
    required this.dictSha256,
    required this.licenseType,
    this.licenseUrl,
    required this.minimumAppVersion,
    required this.supportedPlatforms,
  });

  /// Deserializes a manifest from a JSON object.
  factory IndicPackManifest.fromJson(Map<String, dynamic> json) {
    return IndicPackManifest(
      manifestVersion: json['manifestVersion'] as String? ?? '1.0.0',
      packId: json['packId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      languageCode: json['languageCode'] as String? ?? '',
      languageName: json['languageName'] as String? ?? '',
      scriptCode: json['scriptCode'] as String? ?? '',
      scriptName: json['scriptName'] as String? ?? '',
      engineVersion: json['engineVersion'] as String? ?? '1.0.0',
      modelVersion: json['modelVersion'] as String? ?? '1.0.0',
      modelFormat: json['modelFormat'] as String? ?? 'onnx',
      quantization: json['quantization'] as String? ?? 'int8',
      modelFileName: json['modelFileName'] as String? ?? 'model.onnx',
      modelSizeBytes: json['modelSizeBytes'] as int? ?? 0,
      modelSha256: json['modelSha256'] as String? ?? '',
      dictFileName: json['dictFileName'] as String? ?? 'dict.txt',
      dictSizeBytes: json['dictSizeBytes'] as int? ?? 0,
      dictSha256: json['dictSha256'] as String? ?? '',
      licenseType: json['licenseType'] as String? ?? 'Apache-2.0',
      licenseUrl: json['licenseUrl'] as String?,
      minimumAppVersion: json['minimumAppVersion'] as String? ?? '0.1.0',
      supportedPlatforms: (json['supportedPlatforms'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const ['windows', 'macos', 'linux', 'android', 'ios'],
    );
  }

  /// Serializes the manifest to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'manifestVersion': manifestVersion,
        'packId': packId,
        'displayName': displayName,
        'languageCode': languageCode,
        'languageName': languageName,
        'scriptCode': scriptCode,
        'scriptName': scriptName,
        'engineVersion': engineVersion,
        'modelVersion': modelVersion,
        'modelFormat': modelFormat,
        'quantization': quantization,
        'modelFileName': modelFileName,
        'modelSizeBytes': modelSizeBytes,
        'modelSha256': modelSha256,
        'dictFileName': dictFileName,
        'dictSizeBytes': dictSizeBytes,
        'dictSha256': dictSha256,
        'licenseType': licenseType,
        if (licenseUrl != null) 'licenseUrl': licenseUrl,
        'minimumAppVersion': minimumAppVersion,
        'supportedPlatforms': supportedPlatforms,
      };

  /// Performs schema and sanity validation on manifest fields.
  ///
  /// Returns a list of human-readable error descriptions, or empty if valid.
  List<String> validate() {
    final errors = <String>[];
    if (packId.trim().isEmpty) errors.add('Missing packId.');
    if (languageCode.trim().isEmpty) errors.add('Missing languageCode.');
    if (scriptCode.trim().isEmpty) errors.add('Missing scriptCode.');
    if (modelFileName.trim().isEmpty) errors.add('Missing modelFileName.');
    if (dictFileName.trim().isEmpty) errors.add('Missing dictFileName.');
    if (modelSizeBytes <= 0) errors.add('modelSizeBytes must be positive.');
    if (dictSizeBytes <= 0) errors.add('dictSizeBytes must be positive.');
    if (modelSha256.trim().length != 64) {
      errors.add(
          'modelSha256 must be a 64-character hexadecimal SHA-256 string.');
    }
    if (dictSha256.trim().length != 64) {
      errors
          .add('dictSha256 must be a 64-character hexadecimal SHA-256 string.');
    }
    if (supportedPlatforms.isEmpty) {
      errors
          .add('supportedPlatforms must contain at least one target platform.');
    }
    return errors;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicPackManifest &&
          runtimeType == other.runtimeType &&
          packId == other.packId &&
          modelVersion == other.modelVersion &&
          modelSha256 == other.modelSha256;

  @override
  int get hashCode => Object.hash(packId, modelVersion, modelSha256);
}

/// Domain entity representing an Indic OCR Language Pack in TITAN Reader.
@immutable
class IndicLanguagePack {
  /// Manifest metadata defining the pack.
  final IndicPackManifest manifest;

  /// Absolute directory path on the local filesystem where pack files reside.
  final String? directoryPath;

  /// Current lifecycle and verification status of the pack.
  final IndicLanguagePackStatus status;

  /// Detailed error message if [status] is corrupted, incompatible, or failed.
  final String? errorMessage;

  /// Timestamp when the pack was verified and marked ready.
  final DateTime? installedAt;

  /// Timestamp when the pack was last accessed for inference (for LRU eviction).
  final DateTime? lastAccessedAt;

  const IndicLanguagePack({
    required this.manifest,
    this.directoryPath,
    this.status = IndicLanguagePackStatus.notInstalled,
    this.errorMessage,
    this.installedAt,
    this.lastAccessedAt,
  });

  /// Convenience getters delegating to the underlying manifest.
  String get packId => manifest.packId;
  String get displayName => manifest.displayName;
  String get languageCode => manifest.languageCode;
  String get languageName => manifest.languageName;
  String get scriptCode => manifest.scriptCode;
  String get scriptName => manifest.scriptName;
  String get version => manifest.modelVersion;

  /// Whether this pack is ready and verified for OCR inference.
  bool get isReady => status == IndicLanguagePackStatus.ready;

  /// Whether this pack has encountered a corruption or verification failure.
  bool get isCorrupted => status == IndicLanguagePackStatus.corrupted;

  /// Absolute filesystem path to the model weights file, if installed.
  String? get modelFilePath => directoryPath != null
      ? p.join(directoryPath!, manifest.modelFileName)
      : null;

  /// Absolute filesystem path to the character dictionary file, if installed.
  String? get dictionaryFilePath => directoryPath != null
      ? p.join(directoryPath!, manifest.dictFileName)
      : null;

  /// Creates a copy of this pack entity with specified fields updated.
  IndicLanguagePack copyWith({
    IndicPackManifest? manifest,
    String? directoryPath,
    IndicLanguagePackStatus? status,
    String? errorMessage,
    DateTime? installedAt,
    DateTime? lastAccessedAt,
  }) {
    return IndicLanguagePack(
      manifest: manifest ?? this.manifest,
      directoryPath: directoryPath ?? this.directoryPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      installedAt: installedAt ?? this.installedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  /// Converts this language pack into the standard [OcrModelDescriptor] contract.
  ///
  /// This bridges the modular language pack entity into the frozen [OcrEngine]
  /// pipeline without requiring interface modifications.
  OcrModelDescriptor toOcrModelDescriptor() {
    return OcrModelDescriptor(
      id: manifest.packId,
      displayName: manifest.displayName,
      languageCode: manifest.languageCode,
      format: manifest.modelFormat,
      version: manifest.modelVersion,
      sizeBytes: manifest.modelSizeBytes,
      localFilePath: modelFilePath,
      isAvailableLocally: isReady,
    );
  }

  /// Predefined metadata foundation descriptor for Hindi / Devanagari (P0 Target).
  static const IndicLanguagePack hindiFoundationDescriptor = IndicLanguagePack(
    manifest: IndicPackManifest(
      manifestVersion: '1.0.0',
      packId: 'titan-ocr-indic-hindi',
      displayName: 'Hindi (Devanagari) OCR Pack',
      languageCode: 'hi',
      languageName: 'Hindi',
      scriptCode: 'Deva',
      scriptName: 'Devanagari',
      engineVersion: '1.0.0',
      modelVersion: '1.0.0',
      modelFormat: 'onnx',
      quantization: 'int8',
      modelFileName: 'model.onnx',
      modelSizeBytes: 9856512, // ~9.4 MB INT8 Target
      modelSha256:
          '0000000000000000000000000000000000000000000000000000000000000000',
      dictFileName: 'dict.txt',
      dictSizeBytes: 14208,
      dictSha256:
          '0000000000000000000000000000000000000000000000000000000000000000',
      licenseType: 'Apache-2.0',
      licenseUrl: 'https://github.com/PaddlePaddle/PaddleOCR',
      minimumAppVersion: '0.1.0',
      supportedPlatforms: ['windows', 'macos', 'linux', 'android', 'ios'],
    ),
    status: IndicLanguagePackStatus.notInstalled,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicLanguagePack &&
          runtimeType == other.runtimeType &&
          manifest == other.manifest &&
          status == other.status &&
          directoryPath == other.directoryPath;

  @override
  int get hashCode => Object.hash(manifest, status, directoryPath);
}
