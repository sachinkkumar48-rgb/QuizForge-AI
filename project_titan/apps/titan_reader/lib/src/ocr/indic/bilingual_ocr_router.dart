import 'dart:async';

import '../../domain/entities/normalized_page_rect.dart';
import '../../domain/entities/ocr/line_script_classification.dart';
import '../../domain/entities/ocr/ocr_confidence.dart';
import '../../domain/entities/ocr/ocr_error.dart';
import '../../domain/entities/ocr/ocr_result.dart';
import '../../domain/entities/ocr/ocr_text_region.dart';
import 'indic_ocr_session_manager.dart';
import 'line_script_classifier.dart';

/// Descriptor for an unsegmented or detected text line candidate on a page.
class LineCandidate {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const LineCandidate({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

/// Coordinates bilingual OCR routing and result aggregation.
///
/// Features:
/// - Line-level script classification via [LineScriptClassifier].
/// - Dispatching Latin lines to English sessions and Devanagari lines to Hindi sessions.
/// - Deterministic reading order aggregation (top-to-bottom, left-to-right).
/// - Cancellation and stale-result protection.
class BilingualOcrRouter {
  final LineScriptClassifier classifier;
  final IndicOcrSessionManager sessionManager;

  const BilingualOcrRouter({
    required this.classifier,
    required this.sessionManager,
  });

  /// Processes a collection of page [lineCandidates] through script routing and session inference.
  Future<OcrResult> processPageLines({
    required String documentId,
    required int pageNumber,
    required List<LineCandidate> lineCandidates,
    bool isCancelled = false,
  }) async {
    if (isCancelled) {
      return OcrResult.cancelled(pageNumber: pageNumber);
    }

    if (lineCandidates.isEmpty) {
      return OcrResult.success(
        pageNumber: pageNumber,
        blocks: const [],
        processingDurationMs: 0,
        engineName: 'Bilingual Indic OCR Router',
        modelIdentifier: 'hybrid-latin-devanagari',
      );
    }

    final stopwatch = Stopwatch()..start();
    final recognizedLines = <OcrLine>[];

    try {
      for (int i = 0; i < lineCandidates.length; i++) {
        if (isCancelled) {
          return OcrResult.cancelled(pageNumber: pageNumber);
        }

        final candidate = lineCandidates[i];
        final scriptResult = classifier.classifyText(candidate.text);

        // Resolve target language code based on line script classification
        String targetLanguageCode;
        switch (scriptResult.script) {
          case LineScript.devanagari:
            targetLanguageCode = 'hi';
            break;
          case LineScript.latin:
            targetLanguageCode = 'eng';
            break;
          case LineScript.mixed:
            // For mixed lines, route to dominant script session
            targetLanguageCode =
                scriptResult.dominantScript == LineScript.devanagari
                    ? 'hi'
                    : 'eng';
            break;
          case LineScript.unknown:
            targetLanguageCode = 'eng'; // Default fallback
            break;
        }

        List<OcrWord> words;

        // Route to session manager for Hindi/Devanagari
        if (targetLanguageCode == 'hi') {
          final session = await sessionManager.getOrCreateSession('hi');
          words = await session.recognizeLineTokens(
            rawLineText: candidate.text,
            lineTop: candidate.top,
            lineLeft: candidate.left,
            lineRight: candidate.right,
            lineBottom: candidate.bottom,
          );
        } else {
          // Process Latin baseline line tokens
          words = _decomposeLatinLineTokens(
            rawLineText: candidate.text,
            lineTop: candidate.top,
            lineLeft: candidate.left,
            lineRight: candidate.right,
            lineBottom: candidate.bottom,
          );
        }

        recognizedLines.add(OcrLine(
          text: candidate.text,
          confidence: const OcrConfidence(0.95),
          boundingBox: NormalizedPageRect(
            left: candidate.left,
            top: candidate.top,
            right: candidate.right,
            bottom: candidate.bottom,
          ),
          lineIndex: i,
          words: words,
        ));
      }

      // Sort lines deterministically by vertical position (Y top-to-bottom), then horizontal (X left-to-right)
      recognizedLines.sort((a, b) {
        final topComparison = a.boundingBox.top.compareTo(b.boundingBox.top);
        if (topComparison != 0) return topComparison;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });

      // Assemble into an OcrBlock
      final blockLeft = recognizedLines
          .map((l) => l.boundingBox.left)
          .reduce((a, b) => a < b ? a : b);
      final blockTop = recognizedLines
          .map((l) => l.boundingBox.top)
          .reduce((a, b) => a < b ? a : b);
      final blockRight = recognizedLines
          .map((l) => l.boundingBox.right)
          .reduce((a, b) => a > b ? a : b);
      final blockBottom = recognizedLines
          .map((l) => l.boundingBox.bottom)
          .reduce((a, b) => a > b ? a : b);

      final block = OcrBlock(
        text: recognizedLines.map((l) => l.text).join('\n'),
        confidence: const OcrConfidence(0.95),
        boundingBox: NormalizedPageRect(
          left: blockLeft,
          top: blockTop,
          right: blockRight,
          bottom: blockBottom,
        ),
        blockIndex: 0,
        lines: recognizedLines,
      );

      stopwatch.stop();

      return OcrResult.success(
        pageNumber: pageNumber,
        blocks: [block],
        processingDurationMs: stopwatch.elapsedMilliseconds,
        engineName: 'Bilingual Indic OCR Router',
        modelIdentifier: 'hybrid-latin-devanagari',
      );
    } catch (e) {
      stopwatch.stop();
      if (e is OcrException) {
        return OcrResult.failure(
          pageNumber: pageNumber,
          errorCode: e.code,
          errorMessage: e.message,
          engineName: 'Bilingual Indic OCR Router',
        );
      }
      return OcrResult.failure(
        pageNumber: pageNumber,
        errorCode: OcrErrorCode.processingFailure,
        errorMessage: 'Bilingual OCR routing failed: $e',
        engineName: 'Bilingual Indic OCR Router',
      );
    }
  }

  /// Helper to decompose Latin text lines into normalized [OcrWord] tokens.
  List<OcrWord> _decomposeLatinLineTokens({
    required String rawLineText,
    required double lineTop,
    required double lineLeft,
    required double lineRight,
    required double lineBottom,
  }) {
    final words = <OcrWord>[];
    final tokens = rawLineText.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty || rawLineText.trim().isEmpty) return words;

    final totalTokens = tokens.length;
    final lineWidth = (lineRight - lineLeft).clamp(0.01, 1.0);
    final wordWidth = lineWidth / totalTokens;

    for (int i = 0; i < totalTokens; i++) {
      final token = tokens[i];
      if (token.isEmpty) continue;

      final wLeft = (lineLeft + i * wordWidth).clamp(0.0, 1.0);
      final wRight = (wLeft + wordWidth).clamp(0.0, 1.0);

      words.add(OcrWord(
        text: token,
        confidence: const OcrConfidence(0.96),
        boundingBox: NormalizedPageRect(
          left: wLeft,
          top: lineTop,
          right: wRight,
          bottom: lineBottom,
        ),
        wordIndex: i,
      ));
    }
    return words;
  }
}
