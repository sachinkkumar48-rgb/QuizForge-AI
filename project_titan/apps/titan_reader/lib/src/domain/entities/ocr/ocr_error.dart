import 'package:meta/meta.dart';

/// Error categories for OCR subsystem operations.
enum OcrErrorCode {
  /// The underlying native OCR engine library was not found or failed to link.
  engineUnavailable,

  /// The requested language model file was not found locally.
  modelUnavailable,

  /// Engine or model initialization failed during session startup.
  initializationFailure,

  /// The input request parameters, dimensions, or byte payload are malformed.
  invalidInput,

  /// The image format or pixel layout is unsupported.
  unsupportedImage,

  /// Runtime inference failure during tensor execution.
  processingFailure,

  /// The OCR job was explicitly cancelled by the caller.
  cancelled,

  /// The host operating system / architecture is not supported for native OCR.
  platformUnsupported,
}

/// Domain exception encapsulating OCR engine and pipeline failures.
@immutable
class OcrException implements Exception {
  /// The specific error category.
  final OcrErrorCode code;

  /// Human-readable diagnostic description of the failure.
  final String message;

  /// Optional underlying error cause.
  final Object? cause;

  const OcrException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'OcrException(${code.name}): $message';
}
