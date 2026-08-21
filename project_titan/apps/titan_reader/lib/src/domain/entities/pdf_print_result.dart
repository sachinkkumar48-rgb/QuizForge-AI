import 'package:meta/meta.dart';

/// Status of a PDF print operation.
enum PdfPrintStatus {
  /// Print job was successfully submitted to the OS print system.
  completed,

  /// Print operation was cancelled by the user in the native print dialog.
  cancelled,

  /// Print operation failed due to a system, driver, or file error.
  failed,
}

/// Immutable result model for a native OS PDF printing operation.
@immutable
class PdfPrintResult {
  /// Outcome status of the print request.
  final PdfPrintStatus status;

  /// Human-readable error message if status is [PdfPrintStatus.failed].
  final String? errorMessage;

  /// Optional name of the selected target printer.
  final String? printerName;

  /// Timestamp when the print operation was recorded.
  final DateTime? timestamp;

  const PdfPrintResult({
    required this.status,
    this.errorMessage,
    this.printerName,
    this.timestamp,
  });

  /// Creates a successful print result.
  const PdfPrintResult.completed({this.printerName, this.timestamp})
      : status = PdfPrintStatus.completed,
        errorMessage = null;

  /// Creates a user-cancelled print result.
  const PdfPrintResult.cancelled({this.timestamp})
      : status = PdfPrintStatus.cancelled,
        errorMessage = null,
        printerName = null;

  /// Creates a failed print result.
  const PdfPrintResult.failed(this.errorMessage, {this.timestamp})
      : status = PdfPrintStatus.failed,
        printerName = null;

  /// Whether the print request succeeded.
  bool get isSuccess => status == PdfPrintStatus.completed;

  /// Whether the print request was cancelled by the user.
  bool get isCancelled => status == PdfPrintStatus.cancelled;

  /// Whether the print request encountered an error.
  bool get isFailure => status == PdfPrintStatus.failed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPrintResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          printerName == other.printerName;

  @override
  int get hashCode => Object.hash(status, errorMessage, printerName);

  @override
  String toString() {
    switch (status) {
      case PdfPrintStatus.completed:
        return 'PdfPrintResult.completed(${printerName != null ? 'printer: $printerName' : ''})';
      case PdfPrintStatus.cancelled:
        return 'PdfPrintResult.cancelled()';
      case PdfPrintStatus.failed:
        return 'PdfPrintResult.failed(error: $errorMessage)';
    }
  }
}
