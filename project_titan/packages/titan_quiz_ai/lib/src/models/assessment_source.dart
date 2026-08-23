import 'package:meta/meta.dart';
import 'package:titan_pdf/titan_pdf.dart';

/// Immutable domain model representing a source context passage for assessment generation,
/// retaining full document provenance and page attribution.
@immutable
class AssessmentSource {
  final String documentId;
  final String chunkId;
  final int pageNumber;
  final int endPageNumber;
  final String text;
  final TextProvenance provenance;
  final String script;
  final String? sectionHeading;
  final int tokenEstimate;

  const AssessmentSource({
    required this.documentId,
    required this.chunkId,
    required this.pageNumber,
    int? endPageNumber,
    required this.text,
    this.provenance = TextProvenance.nativePdf,
    this.script = 'latin',
    this.sectionHeading,
    int? tokenEstimate,
  })  : endPageNumber = endPageNumber ?? pageNumber,
        tokenEstimate = tokenEstimate ?? (text.length ~/ 4);

  /// Factory creating an [AssessmentSource] from a [LearningDocumentChunk].
  factory AssessmentSource.fromLearningChunk(LearningDocumentChunk chunk) {
    return AssessmentSource(
      documentId: chunk.documentId,
      chunkId: chunk.chunkId,
      pageNumber: chunk.startPage,
      endPageNumber: chunk.endPage,
      text: chunk.text,
      provenance: chunk.provenance,
      script: chunk.script,
      sectionHeading:
          chunk.sectionHeadings.isNotEmpty ? chunk.sectionHeadings.first : null,
      tokenEstimate: chunk.tokenEstimate,
    );
  }

  /// Factory creating an [AssessmentSource] from a legacy [PdfChunk].
  factory AssessmentSource.fromPdfChunk(
    PdfChunk chunk, {
    TextProvenance provenance = TextProvenance.nativePdf,
    String script = 'latin',
    String? sectionHeading,
  }) {
    return AssessmentSource(
      documentId: chunk.documentId,
      chunkId: chunk.chunkId,
      pageNumber: chunk.startPage,
      endPageNumber: chunk.endPage,
      text: chunk.text,
      provenance: provenance,
      script: script,
      sectionHeading: sectionHeading,
      tokenEstimate: chunk.tokenEstimate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentSource &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          chunkId == other.chunkId &&
          pageNumber == other.pageNumber &&
          endPageNumber == other.endPageNumber &&
          text == other.text &&
          provenance == other.provenance &&
          script == other.script &&
          sectionHeading == other.sectionHeading &&
          tokenEstimate == other.tokenEstimate;

  @override
  int get hashCode => Object.hash(
        documentId,
        chunkId,
        pageNumber,
        endPageNumber,
        text,
        provenance,
        script,
        sectionHeading,
        tokenEstimate,
      );

  @override
  String toString() =>
      'AssessmentSource(chunk: $chunkId, page: $pageNumber-$endPageNumber, script: $script, provenance: $provenance)';
}
