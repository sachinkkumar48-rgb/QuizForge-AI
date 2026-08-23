import 'package:meta/meta.dart';

/// Lifecycle status for an Indic OCR language pack download and installation operation.
enum IndicPackDownloadStatus {
  /// Pack is not present locally and no download is active.
  notInstalled,

  /// Ready to initiate download.
  idle,

  /// Verifying local storage and pre-download requirements.
  checking,

  /// Actively streaming model and dictionary payload from local/remote source.
  downloading,

  /// Cryptographic SHA-256 verification of downloaded payload.
  verifying,

  /// Moving verified payload into active pack repository.
  installing,

  /// Pack is fully installed, verified, and available for offline OCR inference.
  ready,

  /// User explicitly cancelled the download/installation operation.
  cancelled,

  /// Download or installation failed due to an unrecoverable error.
  failed,

  /// Downloaded payload failed SHA-256 or manifest integrity checks.
  corrupted,

  /// Insufficient local storage capacity to download and unpack model weights.
  insufficientStorage,
}

/// Immutable state representation for language pack download and verification operations.
@immutable
class IndicPackDownloadState {
  /// BCP-47 language code (e.g. 'hi', 'bn', 'ta').
  final String languageCode;

  /// Current download/installation lifecycle status.
  final IndicPackDownloadStatus status;

  /// Number of bytes transferred so far.
  final int bytesDownloaded;

  /// Total expected payload size in bytes (0 if unknown).
  final int totalBytes;

  /// Normalized progress ratio (0.0 to 1.0).
  final double progressRatio;

  /// User-friendly label describing the current sub-operation.
  final String operationLabel;

  /// Error message if status is failed, corrupted, or insufficientStorage.
  final String? errorMessage;

  /// Local size on disk in bytes if currently installed.
  final int? installedSizeBytes;

  const IndicPackDownloadState({
    required this.languageCode,
    this.status = IndicPackDownloadStatus.notInstalled,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.progressRatio = 0.0,
    this.operationLabel = '',
    this.errorMessage,
    this.installedSizeBytes,
  });

  /// Factory for initial not-installed state.
  factory IndicPackDownloadState.notInstalled(String languageCode) =>
      IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.notInstalled,
      );

  /// Factory for ready/installed state.
  factory IndicPackDownloadState.ready({
    required String languageCode,
    int? installedSizeBytes,
  }) =>
      IndicPackDownloadState(
        languageCode: languageCode,
        status: IndicPackDownloadStatus.ready,
        progressRatio: 1.0,
        operationLabel: 'Ready for offline OCR',
        installedSizeBytes: installedSizeBytes,
      );

  /// Creates a copy with specified fields updated.
  IndicPackDownloadState copyWith({
    IndicPackDownloadStatus? status,
    int? bytesDownloaded,
    int? totalBytes,
    double? progressRatio,
    String? operationLabel,
    String? errorMessage,
    int? installedSizeBytes,
  }) {
    return IndicPackDownloadState(
      languageCode: languageCode,
      status: status ?? this.status,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      progressRatio: progressRatio ?? this.progressRatio,
      operationLabel: operationLabel ?? this.operationLabel,
      errorMessage: errorMessage ?? this.errorMessage,
      installedSizeBytes: installedSizeBytes ?? this.installedSizeBytes,
    );
  }

  /// Whether the pack is currently in an active progress state.
  bool get isInProgress =>
      status == IndicPackDownloadStatus.downloading ||
      status == IndicPackDownloadStatus.verifying ||
      status == IndicPackDownloadStatus.installing ||
      status == IndicPackDownloadStatus.checking;

  /// Whether the pack is ready for offline OCR.
  bool get isReady => status == IndicPackDownloadStatus.ready;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicPackDownloadState &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode &&
          status == other.status &&
          bytesDownloaded == other.bytesDownloaded &&
          totalBytes == other.totalBytes &&
          progressRatio == other.progressRatio &&
          operationLabel == other.operationLabel &&
          errorMessage == other.errorMessage &&
          installedSizeBytes == other.installedSizeBytes;

  @override
  int get hashCode => Object.hash(
        languageCode,
        status,
        bytesDownloaded,
        totalBytes,
        progressRatio,
        operationLabel,
        errorMessage,
        installedSizeBytes,
      );

  @override
  String toString() =>
      'IndicPackDownloadState($languageCode, ${status.name}, ${(progressRatio * 100).toStringAsFixed(1)}%)';
}

/// Catalog entry describing an available Indic OCR language pack source.
@immutable
class IndicLanguagePackSource {
  final String packId;
  final String displayName;
  final String languageCode;
  final String languageName;
  final String scriptCode;
  final String scriptName;
  final String version;
  final int downloadSizeBytes;
  final String modelSha256;
  final String dictSha256;
  final String licenseType;
  final String? licenseUrl;
  final bool isComingSoon;

  const IndicLanguagePackSource({
    required this.packId,
    required this.displayName,
    required this.languageCode,
    required this.languageName,
    required this.scriptCode,
    required this.scriptName,
    required this.version,
    required this.downloadSizeBytes,
    required this.modelSha256,
    required this.dictSha256,
    required this.licenseType,
    this.licenseUrl,
    this.isComingSoon = false,
  });

  /// Default full catalog of planned Indic OCR language packs.
  static const List<IndicLanguagePackSource> defaultCatalog = [
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-hindi',
      displayName: 'Hindi (Devanagari) OCR Pack',
      languageCode: 'hi',
      languageName: 'Hindi',
      scriptCode: 'Deva',
      scriptName: 'Devanagari',
      version: '1.0.0',
      downloadSizeBytes: 9870720, // ~9.4 MB INT8 model + dict
      modelSha256:
          '0000000000000000000000000000000000000000000000000000000000000000',
      dictSha256:
          '0000000000000000000000000000000000000000000000000000000000000000',
      licenseType: 'Apache-2.0',
      licenseUrl: 'https://github.com/PaddlePaddle/PaddleOCR',
      isComingSoon: false,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-bengali',
      displayName: 'Bengali OCR Pack',
      languageCode: 'bn',
      languageName: 'Bengali',
      scriptCode: 'Beng',
      scriptName: 'Bengali',
      version: '1.0.0',
      downloadSizeBytes: 9961472,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-tamil',
      displayName: 'Tamil OCR Pack',
      languageCode: 'ta',
      languageName: 'Tamil',
      scriptCode: 'Taml',
      scriptName: 'Tamil',
      version: '1.0.0',
      downloadSizeBytes: 9750000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-telugu',
      displayName: 'Telugu OCR Pack',
      languageCode: 'te',
      languageName: 'Telugu',
      scriptCode: 'Telu',
      scriptName: 'Telugu',
      version: '1.0.0',
      downloadSizeBytes: 9800000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-kannada',
      displayName: 'Kannada OCR Pack',
      languageCode: 'kn',
      languageName: 'Kannada',
      scriptCode: 'Knda',
      scriptName: 'Kannada',
      version: '1.0.0',
      downloadSizeBytes: 9700000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-malayalam',
      displayName: 'Malayalam OCR Pack',
      languageCode: 'ml',
      languageName: 'Malayalam',
      scriptCode: 'Mlym',
      scriptName: 'Malayalam',
      version: '1.0.0',
      downloadSizeBytes: 9850000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-gujarati',
      displayName: 'Gujarati OCR Pack',
      languageCode: 'gu',
      languageName: 'Gujarati',
      scriptCode: 'Gujr',
      scriptName: 'Gujarati',
      version: '1.0.0',
      downloadSizeBytes: 9600000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-punjabi',
      displayName: 'Punjabi (Gurmukhi) OCR Pack',
      languageCode: 'pa',
      languageName: 'Punjabi',
      scriptCode: 'Guru',
      scriptName: 'Gurmukhi',
      version: '1.0.0',
      downloadSizeBytes: 9650000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-odia',
      displayName: 'Odia OCR Pack',
      languageCode: 'or',
      languageName: 'Odia',
      scriptCode: 'Orya',
      scriptName: 'Odia',
      version: '1.0.0',
      downloadSizeBytes: 9700000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
    IndicLanguagePackSource(
      packId: 'titan-ocr-indic-urdu',
      displayName: 'Urdu OCR Pack',
      languageCode: 'ur',
      languageName: 'Urdu',
      scriptCode: 'Arab',
      scriptName: 'Arabic',
      version: '1.0.0',
      downloadSizeBytes: 9900000,
      modelSha256: '',
      dictSha256: '',
      licenseType: 'Apache-2.0',
      isComingSoon: true,
    ),
  ];
}
