import 'package:meta/meta.dart';
import 'pdf_encryption_options.dart';

/// Status of a PDF encryption operation.
enum PdfEncryptionStatus {
  completed,
  cancelled,
  failed,
}

/// Immutable result object returned by the PDF encryption pipeline.
@immutable
class PdfEncryptionResult {
  final PdfEncryptionStatus status;
  final String? outputPath;
  final int? encryptedSizeBytes;
  final PdfEncryptionAlgorithm? algorithm;
  final String? errorMessage;
  final DateTime timestamp;

  const PdfEncryptionResult._({
    required this.status,
    this.outputPath,
    this.encryptedSizeBytes,
    this.algorithm,
    this.errorMessage,
    required this.timestamp,
  });

  /// Factory for a successful encryption result.
  factory PdfEncryptionResult.completed({
    required String outputPath,
    required int encryptedSizeBytes,
    required PdfEncryptionAlgorithm algorithm,
    DateTime? timestamp,
  }) {
    return PdfEncryptionResult._(
      status: PdfEncryptionStatus.completed,
      outputPath: outputPath,
      encryptedSizeBytes: encryptedSizeBytes,
      algorithm: algorithm,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Factory for a user-cancelled operation.
  const PdfEncryptionResult.cancelled({DateTime? timestamp})
      : this._(
          status: PdfEncryptionStatus.cancelled,
          timestamp: timestamp ?? const _ZeroDateTime(),
        );

  /// Factory for a failed encryption operation.
  factory PdfEncryptionResult.failed(String errorMessage,
      {DateTime? timestamp}) {
    return PdfEncryptionResult._(
      status: PdfEncryptionStatus.failed,
      errorMessage: errorMessage,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  bool get isSuccess => status == PdfEncryptionStatus.completed;
  bool get isCancelled => status == PdfEncryptionStatus.cancelled;
  bool get isFailure => status == PdfEncryptionStatus.failed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfEncryptionResult &&
          other.status == status &&
          other.outputPath == outputPath &&
          other.encryptedSizeBytes == encryptedSizeBytes &&
          other.algorithm == algorithm &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        outputPath,
        encryptedSizeBytes,
        algorithm,
        errorMessage,
      );

  @override
  String toString() =>
      'PdfEncryptionResult($status, outputPath: $outputPath, size: $encryptedSizeBytes, error: $errorMessage)';
}

class _ZeroDateTime implements DateTime {
  const _ZeroDateTime();

  @override
  bool isAfter(DateTime other) => false;
  @override
  bool isBefore(DateTime other) => false;
  @override
  bool isAtSameMomentAs(DateTime other) => false;
  @override
  int compareTo(DateTime other) => 0;

  @override
  DateTime add(Duration duration) => this;
  @override
  DateTime subtract(Duration duration) => this;
  @override
  Duration difference(DateTime other) => Duration.zero;

  @override
  int get year => 1970;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  bool get isUtc => true;

  @override
  DateTime toLocal() => this;
  @override
  DateTime toUtc() => this;
  @override
  String toIso8601String() => '1970-01-01T00:00:00.000Z';
}
