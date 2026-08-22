import 'package:meta/meta.dart';

import '../normalized_page_rect.dart';
import 'ocr_confidence.dart';

/// Base contract for any recognized OCR spatial text fragment.
abstract class OcrTextRegion {
  /// The recognized textual string content.
  String get text;

  /// Canonical normalized bounding rectangle on the page (0.0 .. 1.0 top-left origin).
  NormalizedPageRect get boundingBox;

  /// Recognition confidence score.
  OcrConfidence get confidence;
}

/// A single recognized word token with its normalized bounding geometry.
@immutable
class OcrWord implements OcrTextRegion {
  @override
  final String text;

  @override
  final NormalizedPageRect boundingBox;

  @override
  final OcrConfidence confidence;

  /// 0-based word index within its parent line.
  final int wordIndex;

  const OcrWord({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    this.wordIndex = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrWord &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          confidence == other.confidence &&
          wordIndex == other.wordIndex;

  @override
  int get hashCode => Object.hash(text, boundingBox, confidence, wordIndex);

  @override
  String toString() => 'OcrWord("$text", $confidence, bbox: $boundingBox)';

  Map<String, Object?> toJson() => {
        'text': text,
        'boundingBox': boundingBox.toJson(),
        'confidence': confidence.toJson(),
        'wordIndex': wordIndex,
      };

  factory OcrWord.fromJson(Map<String, Object?> json) {
    return OcrWord(
      text: json['text'] as String? ?? '',
      boundingBox: NormalizedPageRect.fromJson(
          json['boundingBox'] as Map<String, Object?>? ?? {}),
      confidence: OcrConfidence.fromJson(
          json['confidence'] as Map<String, Object?>? ?? {}),
      wordIndex: (json['wordIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A recognized line of text containing one or more ordered [OcrWord] tokens.
@immutable
class OcrLine implements OcrTextRegion {
  @override
  final String text;

  @override
  final NormalizedPageRect boundingBox;

  @override
  final OcrConfidence confidence;

  /// 0-based line index within its parent block.
  final int lineIndex;

  /// Ordered words comprising this line.
  final List<OcrWord> words;

  const OcrLine({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    this.lineIndex = 0,
    this.words = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrLine &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          confidence == other.confidence &&
          lineIndex == other.lineIndex &&
          _listEquals(words, other.words);

  @override
  int get hashCode => Object.hash(
      text, boundingBox, confidence, lineIndex, Object.hashAll(words));

  @override
  String toString() =>
      'OcrLine("$text", words: ${words.length}, $confidence, bbox: $boundingBox)';

  Map<String, Object?> toJson() => {
        'text': text,
        'boundingBox': boundingBox.toJson(),
        'confidence': confidence.toJson(),
        'lineIndex': lineIndex,
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory OcrLine.fromJson(Map<String, Object?> json) {
    final rawWords = json['words'] as List<dynamic>? ?? [];
    return OcrLine(
      text: json['text'] as String? ?? '',
      boundingBox: NormalizedPageRect.fromJson(
          json['boundingBox'] as Map<String, Object?>? ?? {}),
      confidence: OcrConfidence.fromJson(
          json['confidence'] as Map<String, Object?>? ?? {}),
      lineIndex: (json['lineIndex'] as num?)?.toInt() ?? 0,
      words: rawWords
          .map((w) => OcrWord.fromJson(w as Map<String, Object?>))
          .toList(),
    );
  }
}

/// A recognized logical block or paragraph containing one or more [OcrLine]s.
@immutable
class OcrBlock implements OcrTextRegion {
  @override
  final String text;

  @override
  final NormalizedPageRect boundingBox;

  @override
  final OcrConfidence confidence;

  /// 0-based block index on the page.
  final int blockIndex;

  /// Ordered lines comprising this block.
  final List<OcrLine> lines;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    this.blockIndex = 0,
    this.lines = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrBlock &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          boundingBox == other.boundingBox &&
          confidence == other.confidence &&
          blockIndex == other.blockIndex &&
          _listEquals(lines, other.lines);

  @override
  int get hashCode => Object.hash(
      text, boundingBox, confidence, blockIndex, Object.hashAll(lines));

  @override
  String toString() =>
      'OcrBlock("$text", lines: ${lines.length}, $confidence, bbox: $boundingBox)';

  Map<String, Object?> toJson() => {
        'text': text,
        'boundingBox': boundingBox.toJson(),
        'confidence': confidence.toJson(),
        'blockIndex': blockIndex,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory OcrBlock.fromJson(Map<String, Object?> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return OcrBlock(
      text: json['text'] as String? ?? '',
      boundingBox: NormalizedPageRect.fromJson(
          json['boundingBox'] as Map<String, Object?>? ?? {}),
      confidence: OcrConfidence.fromJson(
          json['confidence'] as Map<String, Object?>? ?? {}),
      blockIndex: (json['blockIndex'] as num?)?.toInt() ?? 0,
      lines: rawLines
          .map((l) => OcrLine.fromJson(l as Map<String, Object?>))
          .toList(),
    );
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
