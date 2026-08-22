import 'package:meta/meta.dart';

import 'ocr_confidence.dart';
import 'ocr_error.dart';
import 'ocr_text_region.dart';

/// The final outcome of an OCR recognition task for a single PDF page.
@immutable
class OcrResult {
  /// 1-based page number.
  final int pageNumber;

  /// Whether recognition completed successfully.
  final bool isSuccess;

  /// Whether recognition was cancelled.
  final bool isCancelled;

  /// Full concatenated page text reconstructed from recognized regions.
  final String fullText;

  /// Ordered logical blocks recognized on the page.
  final List<OcrBlock> blocks;

  /// Flatted list of all lines across blocks.
  final List<OcrLine> lines;

  /// Flattened list of all words across lines.
  final List<OcrWord> words;

  /// Mean recognition confidence across all recognized tokens.
  final OcrConfidence averageConfidence;

  /// End-to-end processing time in milliseconds.
  final int processingDurationMs;

  /// Name of the engine executing the task.
  final String engineName;

  /// Identifier / version of the active language model.
  final String modelIdentifier;

  /// Error code if the task failed.
  final OcrErrorCode? errorCode;

  /// Error diagnostic message if the task failed.
  final String? errorMessage;

  const OcrResult({
    required this.pageNumber,
    required this.isSuccess,
    this.isCancelled = false,
    this.fullText = '',
    this.blocks = const [],
    this.lines = const [],
    this.words = const [],
    this.averageConfidence = OcrConfidence.zero,
    this.processingDurationMs = 0,
    this.engineName = '',
    this.modelIdentifier = '',
    this.errorCode,
    this.errorMessage,
  });

  /// Factory constructor for successful OCR recognition.
  factory OcrResult.success({
    required int pageNumber,
    required List<OcrBlock> blocks,
    required int processingDurationMs,
    required String engineName,
    required String modelIdentifier,
  }) {
    final allLines = <OcrLine>[];
    final allWords = <OcrWord>[];
    final textBuffer = StringBuffer();
    var confidenceSum = 0.0;
    var tokenCount = 0;

    for (var b = 0; b < blocks.length; b++) {
      final block = blocks[b];
      for (var l = 0; l < block.lines.length; l++) {
        final line = block.lines[l];
        allLines.add(line);
        textBuffer.writeln(line.text);
        for (var w = 0; w < line.words.length; w++) {
          final word = line.words[w];
          allWords.add(word);
          confidenceSum += word.confidence.value;
          tokenCount++;
        }
      }
      if (b < blocks.length - 1) {
        textBuffer.writeln();
      }
    }

    final avgConf = tokenCount > 0
        ? OcrConfidence(confidenceSum / tokenCount)
        : (blocks.isNotEmpty ? blocks.first.confidence : OcrConfidence.perfect);

    return OcrResult(
      pageNumber: pageNumber,
      isSuccess: true,
      fullText: textBuffer.toString().trim(),
      blocks: List.unmodifiable(blocks),
      lines: List.unmodifiable(allLines),
      words: List.unmodifiable(allWords),
      averageConfidence: avgConf,
      processingDurationMs: processingDurationMs,
      engineName: engineName,
      modelIdentifier: modelIdentifier,
    );
  }

  /// Factory constructor for a failed OCR task.
  factory OcrResult.failure({
    required int pageNumber,
    required OcrErrorCode errorCode,
    required String errorMessage,
    String engineName = '',
  }) {
    return OcrResult(
      pageNumber: pageNumber,
      isSuccess: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      engineName: engineName,
    );
  }

  /// Factory constructor for a cancelled OCR task.
  factory OcrResult.cancelled({
    required int pageNumber,
    String engineName = '',
  }) {
    return OcrResult(
      pageNumber: pageNumber,
      isSuccess: false,
      isCancelled: true,
      errorCode: OcrErrorCode.cancelled,
      errorMessage: 'OCR recognition was cancelled.',
      engineName: engineName,
    );
  }

  /// True if the result represents a failure (not successful and not cancelled).
  bool get isFailure => !isSuccess && !isCancelled;

  @override
  String toString() {
    if (isSuccess) {
      return 'OcrResult.success(page: $pageNumber, words: ${words.length}, avgConf: $averageConfidence, ${processingDurationMs}ms)';
    }
    if (isCancelled) {
      return 'OcrResult.cancelled(page: $pageNumber)';
    }
    return 'OcrResult.failure(page: $pageNumber, ${errorCode?.name}: $errorMessage)';
  }

  Map<String, Object?> toJson() => {
        'pageNumber': pageNumber,
        'isSuccess': isSuccess,
        'isCancelled': isCancelled,
        'fullText': fullText,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'averageConfidence': averageConfidence.toJson(),
        'processingDurationMs': processingDurationMs,
        'engineName': engineName,
        'modelIdentifier': modelIdentifier,
        if (errorCode != null) 'errorCode': errorCode!.name,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory OcrResult.fromJson(Map<String, Object?> json) {
    final isSuccess = json['isSuccess'] as bool? ?? false;
    final isCancelled = json['isCancelled'] as bool? ?? false;
    final pageNumber = (json['pageNumber'] as num?)?.toInt() ?? 1;

    if (!isSuccess) {
      final errCodeStr = json['errorCode'] as String?;
      final errCode = errCodeStr != null
          ? OcrErrorCode.values.firstWhere(
              (e) => e.name == errCodeStr,
              orElse: () => OcrErrorCode.processingFailure,
            )
          : (isCancelled
              ? OcrErrorCode.cancelled
              : OcrErrorCode.processingFailure);
      return OcrResult(
        pageNumber: pageNumber,
        isSuccess: false,
        isCancelled: isCancelled,
        errorCode: errCode,
        errorMessage: json['errorMessage'] as String?,
        engineName: json['engineName'] as String? ?? '',
      );
    }

    final rawBlocks = json['blocks'] as List<dynamic>? ?? [];
    final blocks = rawBlocks
        .map((b) => OcrBlock.fromJson(b as Map<String, Object?>))
        .toList();

    return OcrResult.success(
      pageNumber: pageNumber,
      blocks: blocks,
      processingDurationMs:
          (json['processingDurationMs'] as num?)?.toInt() ?? 0,
      engineName: json['engineName'] as String? ?? '',
      modelIdentifier: json['modelIdentifier'] as String? ?? '',
    );
  }
}
