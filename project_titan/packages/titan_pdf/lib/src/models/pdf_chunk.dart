import 'package:meta/meta.dart';

/// Immutable domain model representing a segmented text chunk extracted from a PDF document.
@immutable
class PdfChunk {
  final String chunkId;
  final String documentId;
  final int index;
  final String text;
  final int startPage;
  final int endPage;
  final int tokenEstimate;
  final int characterCount;

  PdfChunk({
    required this.chunkId,
    required this.documentId,
    required this.index,
    required this.text,
    required this.startPage,
    required this.endPage,
    required this.tokenEstimate,
    int? characterCount,
  }) : characterCount = characterCount ?? text.length;

  const PdfChunk.constChunk({
    required this.chunkId,
    required this.documentId,
    required this.index,
    required this.text,
    required this.startPage,
    required this.endPage,
    required this.tokenEstimate,
    required this.characterCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfChunk &&
          runtimeType == other.runtimeType &&
          chunkId == other.chunkId &&
          documentId == other.documentId &&
          index == other.index &&
          text == other.text &&
          startPage == other.startPage &&
          endPage == other.endPage &&
          tokenEstimate == other.tokenEstimate &&
          characterCount == other.characterCount;

  @override
  int get hashCode =>
      chunkId.hashCode ^
      documentId.hashCode ^
      index.hashCode ^
      text.hashCode ^
      startPage.hashCode ^
      endPage.hashCode ^
      tokenEstimate.hashCode ^
      characterCount.hashCode;

  @override
  String toString() =>
      'PdfChunk(#$index doc:$documentId, chars: $characterCount, tokens: ~$tokenEstimate)';
}
