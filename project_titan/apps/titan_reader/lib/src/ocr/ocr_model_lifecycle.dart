import 'package:meta/meta.dart';

/// Operational lifecycle state of an OCR model.
enum OcrModelStatus {
  /// The model is not loaded into memory.
  uninitialized,

  /// Model weights and session are actively loading.
  loading,

  /// Model is fully loaded in memory and ready for inference.
  ready,

  /// Model is actively executing inference on a worker isolate.
  processing,

  /// Model loading or inference encountered a critical error.
  error,
}

/// Metadata descriptor for an OCR neural model or language pack.
@immutable
class OcrModelDescriptor {
  /// Unique identifier of the model (e.g. 'ppocr-v4-en-int8').
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Target BCP-47 / ISO language code (e.g. 'eng', 'hin').
  final String languageCode;

  /// Model format / framework ('onnx', 'tflite', 'mock').
  final String format;

  /// Model version string.
  final String version;

  /// File size of model weights in bytes.
  final int sizeBytes;

  /// Path to the local model weights file, if present.
  final String? localFilePath;

  /// Whether the model is bundled in the application assets or present locally.
  final bool isAvailableLocally;

  const OcrModelDescriptor({
    required this.id,
    required this.displayName,
    required this.languageCode,
    required this.format,
    required this.version,
    required this.sizeBytes,
    this.localFilePath,
    this.isAvailableLocally = false,
  });

  /// English baseline PP-OCRv4 quantized model descriptor.
  static const OcrModelDescriptor englishBaseline = OcrModelDescriptor(
    id: 'ppocr-v4-en-int8',
    displayName: 'PP-OCRv4 English (INT8 Quantized)',
    languageCode: 'eng',
    format: 'onnx',
    version: '4.0.0',
    sizeBytes: 1024 * 1024 * 18, // ~18 MB
    isAvailableLocally: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrModelDescriptor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, version);

  @override
  String toString() =>
      'OcrModelDescriptor($id, $languageCode, v$version, local: $isAvailableLocally)';
}
