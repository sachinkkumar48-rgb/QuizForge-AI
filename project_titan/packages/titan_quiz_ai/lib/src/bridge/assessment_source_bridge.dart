import 'package:titan_pdf/titan_pdf.dart';
import '../models/assessment_blueprint.dart';
import '../models/assessment_source.dart';

/// Bridge adapter responsible for converting document intelligence chunks into
/// normalized [AssessmentSource] entities ready for the smart assessment generator.
class AssessmentSourceBridge {
  const AssessmentSourceBridge();

  /// Converts a [LearningDocument] into an ordered list of [AssessmentSource]s.
  /// If [selectedChunkIds] are specified in [blueprint], filters to only those chunks.
  List<AssessmentSource> fromLearningDocument({
    required LearningDocument document,
    AssessmentBlueprint? blueprint,
  }) {
    var chunks = document.chunks;

    if (blueprint != null && blueprint.selectedChunkIds.isNotEmpty) {
      chunks = chunks
          .where((c) => blueprint.selectedChunkIds.contains(c.chunkId))
          .toList();
    }

    return chunks.map((c) => AssessmentSource.fromLearningChunk(c)).toList();
  }

  /// Converts a list of [LearningDocumentChunk]s into [AssessmentSource]s.
  List<AssessmentSource> fromLearningChunks(
    List<LearningDocumentChunk> chunks, {
    List<String>? selectedChunkIds,
  }) {
    var filtered = chunks;
    if (selectedChunkIds != null && selectedChunkIds.isNotEmpty) {
      filtered =
          filtered.where((c) => selectedChunkIds.contains(c.chunkId)).toList();
    }
    return filtered.map((c) => AssessmentSource.fromLearningChunk(c)).toList();
  }

  /// Converts legacy [PdfChunk]s into [AssessmentSource]s.
  List<AssessmentSource> fromPdfChunks(
    List<PdfChunk> chunks, {
    List<String>? selectedChunkIds,
    TextProvenance provenance = TextProvenance.nativePdf,
  }) {
    var filtered = chunks;
    if (selectedChunkIds != null && selectedChunkIds.isNotEmpty) {
      filtered =
          filtered.where((c) => selectedChunkIds.contains(c.chunkId)).toList();
    }
    return filtered
        .map((c) => AssessmentSource.fromPdfChunk(c, provenance: provenance))
        .toList();
  }
}
