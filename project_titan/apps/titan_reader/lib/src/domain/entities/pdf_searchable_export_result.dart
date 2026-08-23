import 'package:meta/meta.dart';

/// Status outcomes of a Searchable PDF Export operation.
enum PdfSearchableExportStatus {
  /// Export completed successfully with OCR text layer injected.
  success,

  /// No OCR recognition data was provided for any scanned page.
  noOcrData,

  /// The source PDF is encrypted or password-protected and cannot be modified.
  encrypted,

  /// The source PDF file is missing, empty, or corrupted.
  invalidDocument,

  /// The document contains unsupported features for export.
  unsupported,

  /// The user or caller cancelled the export operation.
  cancelled,

  /// An unrecoverable error occurred during generation or file writing.
  failed,
}

/// Immutable structured result representing the outcome of a Searchable PDF Export.
@immutable
class PdfSearchableExportResult {
  /// The final status outcome of the export operation.
  final PdfSearchableExportStatus status;

  /// Absolute file path of the newly generated searchable PDF on success.
  final String? outputPath;

  /// Total number of pages injected with OCR text layers.
  final int exportedPagesCount;

  /// Total number of pages in the document.
  final int totalPagesCount;

  /// Size of the generated PDF in bytes on success.
  final int fileSizeBytes;

  /// Total elapsed duration for the export operation.
  final Duration elapsed;

  /// Error message or diagnostic detail when status is not success.
  final String? errorMessage;

  const PdfSearchableExportResult({
    required this.status,
    this.outputPath,
    this.exportedPagesCount = 0,
    this.totalPagesCount = 0,
    this.fileSizeBytes = 0,
    this.elapsed = Duration.zero,
    this.errorMessage,
  });

  /// Whether the export completed successfully.
  bool get isSuccess => status == PdfSearchableExportStatus.success;

  /// Whether the export was explicitly cancelled.
  bool get isCancelled => status == PdfSearchableExportStatus.cancelled;

  /// Convenience constructor for successful export.
  factory PdfSearchableExportResult.success({
    required String outputPath,
    required int exportedPagesCount,
    required int totalPagesCount,
    required int fileSizeBytes,
    required Duration elapsed,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.success,
        outputPath: outputPath,
        exportedPagesCount: exportedPagesCount,
        totalPagesCount: totalPagesCount,
        fileSizeBytes: fileSizeBytes,
        elapsed: elapsed,
      );

  /// Convenience constructor for missing OCR data.
  factory PdfSearchableExportResult.noOcrData({
    String? message,
    int totalPagesCount = 0,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.noOcrData,
        totalPagesCount: totalPagesCount,
        errorMessage: message ?? 'No OCR text layer data found for export.',
      );

  /// Convenience constructor for encrypted/password protected documents.
  factory PdfSearchableExportResult.encrypted({
    String? message,
    int totalPagesCount = 0,
    Duration elapsed = Duration.zero,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.encrypted,
        totalPagesCount: totalPagesCount,
        errorMessage:
            message ?? 'Source PDF is encrypted or password-protected.',
        elapsed: elapsed,
      );

  /// Convenience constructor for missing or invalid document files.
  factory PdfSearchableExportResult.invalidDocument({
    required String message,
    Duration elapsed = Duration.zero,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.invalidDocument,
        errorMessage: message,
        elapsed: elapsed,
      );

  /// Convenience constructor for unsupported PDF features.
  factory PdfSearchableExportResult.unsupported({
    required String reason,
    int totalPagesCount = 0,
    Duration elapsed = Duration.zero,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.unsupported,
        totalPagesCount: totalPagesCount,
        errorMessage: 'Unsupported PDF structure: $reason',
        elapsed: elapsed,
      );

  /// Convenience constructor for cancelled export operations.
  factory PdfSearchableExportResult.cancelled({
    Duration elapsed = Duration.zero,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.cancelled,
        elapsed: elapsed,
      );

  /// Convenience constructor for general failures.
  factory PdfSearchableExportResult.failed({
    required String errorMessage,
    Duration elapsed = Duration.zero,
  }) =>
      PdfSearchableExportResult(
        status: PdfSearchableExportStatus.failed,
        errorMessage: errorMessage,
        elapsed: elapsed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'status': status.name,
        'outputPath': outputPath,
        'exportedPagesCount': exportedPagesCount,
        'totalPagesCount': totalPagesCount,
        'fileSizeBytes': fileSizeBytes,
        'elapsedMs': elapsed.inMilliseconds,
        'errorMessage': errorMessage,
      };

  factory PdfSearchableExportResult.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String?;
    final status = PdfSearchableExportStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => PdfSearchableExportStatus.failed,
    );
    return PdfSearchableExportResult(
      status: status,
      outputPath: json['outputPath'] as String?,
      exportedPagesCount: json['exportedPagesCount'] as int? ?? 0,
      totalPagesCount: json['totalPagesCount'] as int? ?? 0,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      elapsed: Duration(milliseconds: json['elapsedMs'] as int? ?? 0),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfSearchableExportResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          outputPath == other.outputPath &&
          exportedPagesCount == other.exportedPagesCount &&
          totalPagesCount == other.totalPagesCount &&
          fileSizeBytes == other.fileSizeBytes &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        outputPath,
        exportedPagesCount,
        totalPagesCount,
        fileSizeBytes,
        errorMessage,
      );

  @override
  String toString() =>
      'PdfSearchableExportResult(status: $status, pages: $exportedPagesCount/$totalPagesCount, output: $outputPath)';
}
