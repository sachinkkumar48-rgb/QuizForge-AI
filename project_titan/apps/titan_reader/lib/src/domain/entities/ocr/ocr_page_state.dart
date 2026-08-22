import 'package:meta/meta.dart';

import 'ocr_error.dart';
import 'ocr_result.dart';
import 'page_text_classification.dart';

/// Visual display modes for rendering the OCR layer on top of a PDF page.
enum OcrOverlayDisplayMode {
  /// The OCR overlay is hidden.
  hidden,

  /// Only bounding box outlines with confidence color-coding are rendered.
  boundingBoxesOnly,

  /// Bounding box outlines along with readable recognized text badges are rendered.
  textAndBoxes,

  /// A semi-transparent selectable text layer matching the scanned text layout.
  invisibleSelectable,
}

/// Lifecycle status of an OCR recognition task for a specific page.
enum OcrProcessingStatus {
  /// No OCR task has been initiated for this page.
  idle,

  /// Page content is being analyzed for native text vs raster images.
  analyzing,

  /// OCR recognition inference is actively running in the background.
  processing,

  /// OCR recognition successfully finished and text regions are available.
  completed,

  /// OCR recognition or classification encountered a failure.
  error,

  /// OCR was skipped (e.g. page contains searchable digital text).
  skipped,
}

/// Immutable state capturing the OCR lifecycle and overlay configuration for a single PDF page.
@immutable
class OcrPageState {
  /// Unique identifier of the document.
  final String documentId;

  /// 1-based page number.
  final int pageNumber;

  /// Current processing status.
  final OcrProcessingStatus status;

  /// The recognition result when [status] is [OcrProcessingStatus.completed].
  final OcrResult? result;

  /// The page classification if analyzed.
  final PageTextClassification? classification;

  /// Error diagnostic message if [status] is [OcrProcessingStatus.error].
  final String? errorMessage;

  /// Structured error code if [status] is [OcrProcessingStatus.error].
  final OcrErrorCode? errorCode;

  /// Normalized progress value between 0.0 and 1.0.
  final double progress;

  /// Active visual display mode for the page overlay.
  final OcrOverlayDisplayMode displayMode;

  const OcrPageState({
    required this.documentId,
    required this.pageNumber,
    this.status = OcrProcessingStatus.idle,
    this.result,
    this.classification,
    this.errorMessage,
    this.errorCode,
    this.progress = 0.0,
    this.displayMode = OcrOverlayDisplayMode.textAndBoxes,
  });

  /// Factory for an initial idle page state.
  factory OcrPageState.idle({
    required String documentId,
    required int pageNumber,
    OcrOverlayDisplayMode displayMode = OcrOverlayDisplayMode.textAndBoxes,
  }) {
    return OcrPageState(
      documentId: documentId,
      pageNumber: pageNumber,
      status: OcrProcessingStatus.idle,
      displayMode: displayMode,
    );
  }

  /// Factory for a processing page state.
  factory OcrPageState.processing({
    required String documentId,
    required int pageNumber,
    double progress = 0.0,
    PageTextClassification? classification,
    OcrOverlayDisplayMode displayMode = OcrOverlayDisplayMode.textAndBoxes,
  }) {
    return OcrPageState(
      documentId: documentId,
      pageNumber: pageNumber,
      status: OcrProcessingStatus.processing,
      progress: progress.clamp(0.0, 1.0),
      classification: classification,
      displayMode: displayMode,
    );
  }

  /// Factory for a completed page state with recognition results.
  factory OcrPageState.completed({
    required String documentId,
    required int pageNumber,
    required OcrResult result,
    PageTextClassification? classification,
    OcrOverlayDisplayMode displayMode = OcrOverlayDisplayMode.textAndBoxes,
  }) {
    return OcrPageState(
      documentId: documentId,
      pageNumber: pageNumber,
      status: OcrProcessingStatus.completed,
      result: result,
      progress: 1.0,
      classification: classification,
      displayMode: displayMode,
    );
  }

  /// Factory for a failed page state.
  factory OcrPageState.error({
    required String documentId,
    required int pageNumber,
    required String errorMessage,
    OcrErrorCode? errorCode,
    PageTextClassification? classification,
    OcrOverlayDisplayMode displayMode = OcrOverlayDisplayMode.textAndBoxes,
  }) {
    return OcrPageState(
      documentId: documentId,
      pageNumber: pageNumber,
      status: OcrProcessingStatus.error,
      errorMessage: errorMessage,
      errorCode: errorCode ?? OcrErrorCode.processingFailure,
      classification: classification,
      displayMode: displayMode,
    );
  }

  /// Factory for a skipped page state (e.g. page has native searchable digital text).
  factory OcrPageState.skipped({
    required String documentId,
    required int pageNumber,
    required PageTextClassification classification,
    OcrOverlayDisplayMode displayMode = OcrOverlayDisplayMode.hidden,
  }) {
    return OcrPageState(
      documentId: documentId,
      pageNumber: pageNumber,
      status: OcrProcessingStatus.skipped,
      classification: classification,
      displayMode: displayMode,
    );
  }

  /// Whether OCR recognition is actively in flight.
  bool get isProcessing => status == OcrProcessingStatus.processing;

  /// Whether OCR recognition has successfully produced text.
  bool get hasResult =>
      status == OcrProcessingStatus.completed &&
      result != null &&
      result!.isSuccess;

  /// Whether the overlay is currently visible.
  bool get isOverlayVisible =>
      displayMode != OcrOverlayDisplayMode.hidden && hasResult;

  /// Returns a copy of this state with updated properties.
  OcrPageState copyWith({
    String? documentId,
    int? pageNumber,
    OcrProcessingStatus? status,
    OcrResult? result,
    PageTextClassification? classification,
    String? errorMessage,
    OcrErrorCode? errorCode,
    double? progress,
    OcrOverlayDisplayMode? displayMode,
  }) {
    return OcrPageState(
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      status: status ?? this.status,
      result: result ?? this.result,
      classification: classification ?? this.classification,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      progress: progress ?? this.progress,
      displayMode: displayMode ?? this.displayMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrPageState &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          status == other.status &&
          result == other.result &&
          classification == other.classification &&
          errorMessage == other.errorMessage &&
          errorCode == other.errorCode &&
          progress == other.progress &&
          displayMode == other.displayMode;

  @override
  int get hashCode => Object.hash(
        documentId,
        pageNumber,
        status,
        result,
        classification,
        errorMessage,
        errorCode,
        progress,
        displayMode,
      );

  @override
  String toString() =>
      'OcrPageState($documentId, page: $pageNumber, status: ${status.name}, mode: ${displayMode.name}, progress: ${(progress * 100).toStringAsFixed(1)}%)';

  Map<String, Object?> toJson() => {
        'documentId': documentId,
        'pageNumber': pageNumber,
        'status': status.name,
        'displayMode': displayMode.name,
        'progress': progress,
        if (result != null) 'result': result!.toJson(),
        if (classification != null) 'classification': classification!.toJson(),
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (errorCode != null) 'errorCode': errorCode!.name,
      };

  factory OcrPageState.fromJson(Map<String, Object?> json) {
    final statusStr = json['status'] as String? ?? 'idle';
    final modeStr = json['displayMode'] as String? ?? 'textAndBoxes';
    final errCodeStr = json['errorCode'] as String?;

    return OcrPageState(
      documentId: json['documentId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      status: OcrProcessingStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => OcrProcessingStatus.idle,
      ),
      displayMode: OcrOverlayDisplayMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => OcrOverlayDisplayMode.textAndBoxes,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      result: json['result'] != null
          ? OcrResult.fromJson(json['result'] as Map<String, Object?>)
          : null,
      classification: json['classification'] != null
          ? PageTextClassification.fromJson(
              json['classification'] as Map<String, Object?>)
          : null,
      errorMessage: json['errorMessage'] as String?,
      errorCode: errCodeStr != null
          ? OcrErrorCode.values.firstWhere(
              (e) => e.name == errCodeStr,
              orElse: () => OcrErrorCode.processingFailure,
            )
          : null,
    );
  }
}
