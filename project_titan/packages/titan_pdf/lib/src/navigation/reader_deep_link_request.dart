import 'package:meta/meta.dart';

/// Immutable domain entity representing a deep-link request to navigate directly
/// to a specific document, page, chunk, or text span in TITAN Reader.
@immutable
class ReaderDeepLinkRequest {
  final String documentId;
  final int pageNumber;
  final String? chunkId;
  final String? selectedText;
  final Map<String, double>? boundingRegion;
  final String source;
  final DateTime createdAt;

  ReaderDeepLinkRequest({
    required this.documentId,
    required this.pageNumber,
    this.chunkId,
    this.selectedText,
    this.boundingRegion,
    this.source = 'quizforge_assessment',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  const ReaderDeepLinkRequest.constRequest({
    required this.documentId,
    required this.pageNumber,
    required this.chunkId,
    required this.selectedText,
    required this.boundingRegion,
    required this.source,
    required this.createdAt,
  });

  /// True if request specifies a specific chunk within the page.
  bool get hasChunk => chunkId != null && chunkId!.trim().isNotEmpty;

  /// True if request contains text for highlighting.
  bool get hasSelectedText =>
      selectedText != null && selectedText!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderDeepLinkRequest &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          chunkId == other.chunkId &&
          selectedText == other.selectedText &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
        documentId,
        pageNumber,
        chunkId,
        selectedText,
        source,
      );

  @override
  String toString() =>
      'ReaderDeepLinkRequest(doc: $documentId, page: $pageNumber, chunk: $chunkId, source: $source)';
}
