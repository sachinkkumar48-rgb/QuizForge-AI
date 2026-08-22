import 'package:meta/meta.dart';

import '../../../pdf/pdf_engine_contracts.dart';
import '../normalized_page_rect.dart';
import 'ocr_confidence.dart';
import 'ocr_result.dart';

/// An indexed word or punctuation token within a normalized OCR text stream.
@immutable
class OcrTextToken {
  /// 0-based token index on the page.
  final int tokenIndex;

  /// The raw token text string.
  final String text;

  /// Start character offset (inclusive) in the parent page's full text.
  final int startOffset;

  /// End character offset (exclusive) in the parent page's full text.
  final int endOffset;

  /// Canonical normalized bounding box on the page (0.0 .. 1.0).
  final NormalizedPageRect boundingBox;

  /// Recognition confidence score.
  final OcrConfidence confidence;

  /// 0-based line index in the page.
  final int lineIndex;

  /// 0-based block index in the page.
  final int blockIndex;

  const OcrTextToken({
    required this.tokenIndex,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.boundingBox,
    required this.confidence,
    this.lineIndex = 0,
    this.blockIndex = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrTextToken &&
          runtimeType == other.runtimeType &&
          tokenIndex == other.tokenIndex &&
          text == other.text &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset &&
          boundingBox == other.boundingBox &&
          confidence == other.confidence &&
          lineIndex == other.lineIndex &&
          blockIndex == other.blockIndex;

  @override
  int get hashCode => Object.hash(
        tokenIndex,
        text,
        startOffset,
        endOffset,
        boundingBox,
        confidence,
        lineIndex,
        blockIndex,
      );

  @override
  String toString() =>
      'OcrTextToken($tokenIndex: "$text" [$startOffset..$endOffset], bbox: $boundingBox)';

  Map<String, Object?> toJson() => {
        'tokenIndex': tokenIndex,
        'text': text,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'boundingBox': boundingBox.toJson(),
        'confidence': confidence.toJson(),
        'lineIndex': lineIndex,
        'blockIndex': blockIndex,
      };

  factory OcrTextToken.fromJson(Map<String, Object?> json) {
    return OcrTextToken(
      tokenIndex: (json['tokenIndex'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      startOffset: (json['startOffset'] as num?)?.toInt() ?? 0,
      endOffset: (json['endOffset'] as num?)?.toInt() ?? 0,
      boundingBox: NormalizedPageRect.fromJson(
          json['boundingBox'] as Map<String, Object?>? ?? {}),
      confidence: OcrConfidence.fromJson(
          json['confidence'] as Map<String, Object?>? ?? {}),
      lineIndex: (json['lineIndex'] as num?)?.toInt() ?? 0,
      blockIndex: (json['blockIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A search match located in an OCR-processed PDF page.
@immutable
class OcrSearchMatch {
  /// 0-based match index within search results.
  final int index;

  /// Identifier of the document containing this match.
  final String documentId;

  /// 1-based page number containing this match.
  final int pageNumber;

  /// Exact text substring that matched the query.
  final String matchedText;

  /// Formatted contextual snippet surrounding the match.
  final String snippet;

  /// Character start offset (inclusive) in page text.
  final int startOffset;

  /// Character end offset (exclusive) in page text.
  final int endOffset;

  /// Normalized bounding boxes of all OCR tokens covered by this match.
  final List<NormalizedPageRect> boundingBoxes;

  /// Average recognition confidence across the matched tokens.
  final double confidence;

  const OcrSearchMatch({
    required this.index,
    required this.documentId,
    required this.pageNumber,
    required this.matchedText,
    required this.snippet,
    required this.startOffset,
    required this.endOffset,
    required this.boundingBoxes,
    required this.confidence,
  });

  /// Converts this match to a standard engine-agnostic [PdfSearchMatch].
  PdfSearchMatch toPdfSearchMatch([int? unifiedIndex]) {
    return PdfSearchMatch(
      index: unifiedIndex ?? index,
      pageNumber: pageNumber,
      snippet: snippet,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrSearchMatch &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          matchedText == other.matchedText &&
          snippet == other.snippet &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset &&
          _listEquals(boundingBoxes, other.boundingBoxes);

  @override
  int get hashCode => Object.hash(
        index,
        documentId,
        pageNumber,
        matchedText,
        snippet,
        startOffset,
        endOffset,
        Object.hashAll(boundingBoxes),
      );

  @override
  String toString() =>
      'OcrSearchMatch($index, doc: $documentId, p$pageNumber, "$snippet", boxes: ${boundingBoxes.length})';

  Map<String, Object?> toJson() => {
        'index': index,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'matchedText': matchedText,
        'snippet': snippet,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'boundingBoxes': boundingBoxes.map((b) => b.toJson()).toList(),
        'confidence': confidence,
      };

  factory OcrSearchMatch.fromJson(Map<String, Object?> json) {
    final rawBoxes = json['boundingBoxes'] as List<dynamic>? ?? [];
    return OcrSearchMatch(
      index: (json['index'] as num?)?.toInt() ?? 0,
      documentId: json['documentId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      matchedText: json['matchedText'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      startOffset: (json['startOffset'] as num?)?.toInt() ?? 0,
      endOffset: (json['endOffset'] as num?)?.toInt() ?? 0,
      boundingBoxes: rawBoxes
          .map((b) => NormalizedPageRect.fromJson(b as Map<String, Object?>))
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// An active or captured text selection over an OCR-processed PDF page.
@immutable
class OcrTextSelection {
  /// Identifier of the document containing this selection.
  final String documentId;

  /// 1-based page number containing this selection.
  final int pageNumber;

  /// Full selected text string.
  final String selectedText;

  /// Start character offset in normalized page text.
  final int startOffset;

  /// End character offset in normalized page text.
  final int endOffset;

  /// Indices of all tokens included in this selection.
  final List<int> selectedTokenIndices;

  /// Normalized bounding rectangles covered by the selection.
  final List<NormalizedPageRect> boundingBoxes;

  const OcrTextSelection({
    required this.documentId,
    required this.pageNumber,
    required this.selectedText,
    required this.startOffset,
    required this.endOffset,
    required this.selectedTokenIndices,
    required this.boundingBoxes,
  });

  /// Converts this OCR selection to a standard [PdfTextSelectionSnapshot].
  PdfTextSelectionSnapshot toSnapshot() {
    return PdfTextSelectionSnapshot(
      text: selectedText,
      fragments: boundingBoxes
          .map((rect) =>
              PdfSelectionFragment(pageNumber: pageNumber, rect: rect))
          .toList(),
    );
  }

  /// Whether a specific token index is included in this selection.
  bool containsToken(int tokenIndex) =>
      selectedTokenIndices.contains(tokenIndex);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrTextSelection &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          selectedText == other.selectedText &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset &&
          _listEquals(selectedTokenIndices, other.selectedTokenIndices) &&
          _listEquals(boundingBoxes, other.boundingBoxes);

  @override
  int get hashCode => Object.hash(
        documentId,
        pageNumber,
        selectedText,
        startOffset,
        endOffset,
        Object.hashAll(selectedTokenIndices),
        Object.hashAll(boundingBoxes),
      );

  @override
  String toString() =>
      'OcrTextSelection(doc: $documentId, p$pageNumber, "$selectedText", tokens: ${selectedTokenIndices.length})';

  Map<String, Object?> toJson() => {
        'documentId': documentId,
        'pageNumber': pageNumber,
        'selectedText': selectedText,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'selectedTokenIndices': selectedTokenIndices,
        'boundingBoxes': boundingBoxes.map((b) => b.toJson()).toList(),
      };

  factory OcrTextSelection.fromJson(Map<String, Object?> json) {
    final rawTokens = json['selectedTokenIndices'] as List<dynamic>? ?? [];
    final rawBoxes = json['boundingBoxes'] as List<dynamic>? ?? [];
    return OcrTextSelection(
      documentId: json['documentId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      selectedText: json['selectedText'] as String? ?? '',
      startOffset: (json['startOffset'] as num?)?.toInt() ?? 0,
      endOffset: (json['endOffset'] as num?)?.toInt() ?? 0,
      selectedTokenIndices: rawTokens.map((t) => (t as num).toInt()).toList(),
      boundingBoxes: rawBoxes
          .map((b) => NormalizedPageRect.fromJson(b as Map<String, Object?>))
          .toList(),
    );
  }
}

/// A linear, normalized representation of an OCR-recognized page's text stream,
/// providing offset mapping, substring search, snippet generation, and selection synthesis.
@immutable
class NormalizedOcrPageText {
  /// Identifier of the document.
  final String documentId;

  /// 1-based page number.
  final int pageNumber;

  /// Linearized concatenated full text string.
  final String fullText;

  /// Ordered token sequence comprising this page's text.
  final List<OcrTextToken> tokens;

  const NormalizedOcrPageText({
    required this.documentId,
    required this.pageNumber,
    required this.fullText,
    required this.tokens,
  });

  /// Constructs a normalized text model from an [OcrResult].
  factory NormalizedOcrPageText.fromOcrResult({
    required String documentId,
    required OcrResult result,
  }) {
    final textBuffer = StringBuffer();
    final tokens = <OcrTextToken>[];
    var tokenIndex = 0;

    for (var b = 0; b < result.blocks.length; b++) {
      final block = result.blocks[b];
      for (var l = 0; l < block.lines.length; l++) {
        final line = block.lines[l];
        for (var w = 0; w < line.words.length; w++) {
          final word = line.words[w];
          final startOffset = textBuffer.length;
          textBuffer.write(word.text);
          final endOffset = textBuffer.length;

          tokens.add(OcrTextToken(
            tokenIndex: tokenIndex++,
            text: word.text,
            startOffset: startOffset,
            endOffset: endOffset,
            boundingBox: word.boundingBox,
            confidence: word.confidence,
            lineIndex: l,
            blockIndex: b,
          ));

          if (w < line.words.length - 1) {
            textBuffer.write(' ');
          }
        }
        if (l < block.lines.length - 1) {
          textBuffer.writeln();
        }
      }
      if (b < result.blocks.length - 1) {
        textBuffer.writeln();
      }
    }

    return NormalizedOcrPageText(
      documentId: documentId,
      pageNumber: result.pageNumber,
      fullText: textBuffer.toString(),
      tokens: List.unmodifiable(tokens),
    );
  }

  /// Searches for [query] in the normalized page text and returns all matches.
  List<OcrSearchMatch> search(
    String query, {
    bool caseSensitive = false,
    bool wholeWord = false,
  }) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || fullText.isEmpty) {
      return const [];
    }

    String pattern = RegExp.escape(cleanQuery);
    if (wholeWord) {
      pattern = r'\b' + pattern + r'\b';
    }

    final regExp = RegExp(pattern, caseSensitive: caseSensitive);
    final matches = <OcrSearchMatch>[];
    var matchIndex = 0;

    for (final m in regExp.allMatches(fullText)) {
      final start = m.start;
      final end = m.end;
      final matchedText = fullText.substring(start, end);

      // Find all tokens overlapping this match range
      final overlappingTokens = tokens
          .where((t) => t.startOffset < end && t.endOffset > start)
          .toList();

      final boundingBoxes =
          overlappingTokens.map((t) => t.boundingBox).toList();

      final avgConf = overlappingTokens.isNotEmpty
          ? overlappingTokens
                  .map((t) => t.confidence.value)
                  .reduce((a, b) => a + b) /
              overlappingTokens.length
          : 1.0;

      final snippet = _createSnippet(start, end);

      matches.add(OcrSearchMatch(
        index: matchIndex++,
        documentId: documentId,
        pageNumber: pageNumber,
        matchedText: matchedText,
        snippet: snippet,
        startOffset: start,
        endOffset: end,
        boundingBoxes: boundingBoxes,
        confidence: avgConf,
      ));
    }

    return List.unmodifiable(matches);
  }

  /// Creates a selection covering character offsets [startOffset] to [endOffset].
  OcrTextSelection? createSelectionFromOffsets(int startOffset, int endOffset) {
    if (startOffset >= endOffset || fullText.isEmpty) return null;
    final clampedStart = startOffset.clamp(0, fullText.length);
    final clampedEnd = endOffset.clamp(0, fullText.length);
    if (clampedStart >= clampedEnd) return null;

    final selectedTokens = tokens
        .where((t) => t.startOffset < clampedEnd && t.endOffset > clampedStart)
        .toList();

    if (selectedTokens.isEmpty) return null;

    return OcrTextSelection(
      documentId: documentId,
      pageNumber: pageNumber,
      selectedText: fullText.substring(clampedStart, clampedEnd),
      startOffset: clampedStart,
      endOffset: clampedEnd,
      selectedTokenIndices: selectedTokens.map((t) => t.tokenIndex).toList(),
      boundingBoxes: selectedTokens.map((t) => t.boundingBox).toList(),
    );
  }

  /// Creates a selection from a set of token indices.
  OcrTextSelection? createSelectionFromTokens(List<int> tokenIndices) {
    if (tokenIndices.isEmpty || tokens.isEmpty) return null;

    final selectedTokens = tokens
        .where((t) => tokenIndices.contains(t.tokenIndex))
        .toList(growable: false);

    if (selectedTokens.isEmpty) return null;

    final first = selectedTokens.first;
    final last = selectedTokens.last;
    final start = first.startOffset;
    final end = last.endOffset;

    return OcrTextSelection(
      documentId: documentId,
      pageNumber: pageNumber,
      selectedText: fullText.substring(start, end),
      startOffset: start,
      endOffset: end,
      selectedTokenIndices: selectedTokens.map((t) => t.tokenIndex).toList(),
      boundingBoxes: selectedTokens.map((t) => t.boundingBox).toList(),
    );
  }

  String _createSnippet(int start, int end, {int contextChars = 30}) {
    final prefixStart = (start - contextChars).clamp(0, fullText.length);
    final suffixEnd = (end + contextChars).clamp(0, fullText.length);

    var prefix = fullText.substring(prefixStart, start).replaceAll('\n', ' ');
    var matched = fullText.substring(start, end).replaceAll('\n', ' ');
    var suffix = fullText.substring(end, suffixEnd).replaceAll('\n', ' ');

    if (prefixStart > 0) prefix = '…$prefix';
    if (suffixEnd < fullText.length) suffix = '$suffix…';

    return '$prefix$matched$suffix'.trim();
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
