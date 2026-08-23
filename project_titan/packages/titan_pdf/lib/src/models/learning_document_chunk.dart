import 'package:meta/meta.dart';
import 'pdf_chunk.dart';
import 'text_provenance.dart';

/// Immutable domain model representing a structured, AI-ready chunk of learning text.
///
/// Designed for deterministic ingestion, semantic grounding, MCQ generation,
/// flashcard generation, and local RAG retrieval across Project TITAN.
@immutable
class LearningDocumentChunk {
  /// Stable deterministic chunk identifier (e.g. "doc_123_chunk_0").
  final String chunkId;

  /// Unique identifier of the parent document.
  final String documentId;

  /// 0-based sequential index of this chunk within the document.
  final int index;

  /// Cleaned, normalized text content suitable for LLM prompt context.
  final String text;

  /// 1-based start page where this chunk's content originates.
  final int startPage;

  /// 1-based end page where this chunk's content finishes.
  final int endPage;

  /// Extraction provenance (native PDF text, OCR recognized, or mixed).
  final TextProvenance provenance;

  /// Estimated LLM token count.
  final int tokenEstimate;

  /// Total character length of [text].
  final int characterCount;

  /// Dominant script / language (e.g. 'latin', 'devanagari', 'bilingual').
  final String script;

  /// Overall confidence score (1.0 for native, 0.0 .. 1.0 for OCR).
  final double confidence;

  /// Hierarchical section or topic headings relevant to this chunk.
  final List<String> sectionHeadings;

  /// Extensible metadata (e.g. bounding rects, source anchors, chapter IDs).
  final Map<String, dynamic> metadata;

  LearningDocumentChunk({
    required this.chunkId,
    required this.documentId,
    required this.index,
    required this.text,
    required this.startPage,
    required this.endPage,
    this.provenance = TextProvenance.nativePdf,
    required this.tokenEstimate,
    int? characterCount,
    this.script = 'latin',
    this.confidence = 1.0,
    this.sectionHeadings = const [],
    this.metadata = const {},
  }) : characterCount = characterCount ?? text.length;

  const LearningDocumentChunk.constChunk({
    required this.chunkId,
    required this.documentId,
    required this.index,
    required this.text,
    required this.startPage,
    required this.endPage,
    required this.provenance,
    required this.tokenEstimate,
    required this.characterCount,
    this.script = 'latin',
    this.confidence = 1.0,
    this.sectionHeadings = const [],
    this.metadata = const {},
  });

  /// Adapts this [LearningDocumentChunk] to a legacy [PdfChunk] for backward compatibility.
  PdfChunk toPdfChunk() {
    return PdfChunk(
      chunkId: chunkId,
      documentId: documentId,
      index: index,
      text: text,
      startPage: startPage,
      endPage: endPage,
      tokenEstimate: tokenEstimate,
      characterCount: characterCount,
    );
  }

  /// Creates a [LearningDocumentChunk] from a legacy [PdfChunk].
  factory LearningDocumentChunk.fromPdfChunk(
    PdfChunk chunk, {
    TextProvenance provenance = TextProvenance.nativePdf,
    String script = 'latin',
    double confidence = 1.0,
    List<String> sectionHeadings = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return LearningDocumentChunk(
      chunkId: chunk.chunkId,
      documentId: chunk.documentId,
      index: chunk.index,
      text: chunk.text,
      startPage: chunk.startPage,
      endPage: chunk.endPage,
      provenance: provenance,
      tokenEstimate: chunk.tokenEstimate,
      characterCount: chunk.characterCount,
      script: script,
      confidence: confidence,
      sectionHeadings: sectionHeadings,
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningDocumentChunk &&
          runtimeType == other.runtimeType &&
          chunkId == other.chunkId &&
          documentId == other.documentId &&
          index == other.index &&
          text == other.text &&
          startPage == other.startPage &&
          endPage == other.endPage &&
          provenance == other.provenance &&
          tokenEstimate == other.tokenEstimate &&
          characterCount == other.characterCount &&
          script == other.script &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      chunkId.hashCode ^
      documentId.hashCode ^
      index.hashCode ^
      text.hashCode ^
      startPage.hashCode ^
      endPage.hashCode ^
      provenance.hashCode ^
      tokenEstimate.hashCode ^
      characterCount.hashCode ^
      script.hashCode ^
      confidence.hashCode;
}
