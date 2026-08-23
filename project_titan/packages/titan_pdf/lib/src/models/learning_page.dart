import 'package:meta/meta.dart';
import 'text_provenance.dart';

/// Represents a discrete rectangular text block within a [LearningPage].
@immutable
class LearningPageBlock {
  /// Extracted text content of this block.
  final String text;

  /// 0-based block index within the page.
  final int blockIndex;

  /// Classification script (e.g. 'latin', 'devanagari', 'bilingual').
  final String script;

  /// Recognition confidence score (1.0 for native digital text, 0.0 .. 1.0 for OCR).
  final double confidence;

  /// Optional normalized bounding box [left, top, width, height] normalized to (0.0 .. 1.0).
  final List<double>? boundingBox;

  const LearningPageBlock({
    required this.text,
    required this.blockIndex,
    this.script = 'latin',
    this.confidence = 1.0,
    this.boundingBox,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningPageBlock &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          blockIndex == other.blockIndex &&
          script == other.script &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      text.hashCode ^
      blockIndex.hashCode ^
      script.hashCode ^
      confidence.hashCode;
}

/// Represents an individual document page containing normalized text and provenance metadata.
@immutable
class LearningPage {
  /// Document identifier to which this page belongs.
  final String documentId;

  /// 1-based page number.
  final int pageNumber;

  /// Full concatenated and normalized text of the page.
  final String text;

  /// Originating source provenance (native digital PDF stream or OCR).
  final TextProvenance provenance;

  /// Dominant script / language (e.g. 'latin', 'devanagari', 'bilingual').
  final String script;

  /// Aggregate confidence score across the page (1.0 for digital, 0.0 .. 1.0 for OCR).
  final double confidence;

  /// Total character count.
  final int characterCount;

  /// Discrete text blocks forming the page, preserved in visual reading order.
  final List<LearningPageBlock> blocks;

  LearningPage({
    required this.documentId,
    required this.pageNumber,
    required this.text,
    required this.provenance,
    this.script = 'latin',
    this.confidence = 1.0,
    int? characterCount,
    this.blocks = const [],
  }) : characterCount = characterCount ?? text.length;

  const LearningPage.constPage({
    required this.documentId,
    required this.pageNumber,
    required this.text,
    required this.provenance,
    required this.script,
    required this.confidence,
    required this.characterCount,
    this.blocks = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningPage &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          text == other.text &&
          provenance == other.provenance &&
          script == other.script &&
          confidence == other.confidence &&
          characterCount == other.characterCount;

  @override
  int get hashCode =>
      documentId.hashCode ^
      pageNumber.hashCode ^
      text.hashCode ^
      provenance.hashCode ^
      script.hashCode ^
      confidence.hashCode ^
      characterCount.hashCode;
}
