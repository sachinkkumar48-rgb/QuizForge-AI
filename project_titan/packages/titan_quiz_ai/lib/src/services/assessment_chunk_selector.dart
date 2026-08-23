import '../models/assessment_blueprint.dart';
import '../models/assessment_source.dart';

/// Service responsible for selecting, ordering, and batching [AssessmentSource]s
/// deterministically for LLM context window safety.
class AssessmentChunkSelector {
  const AssessmentChunkSelector();

  /// Orders and partitions [sources] into deterministic batches conforming to [blueprint.maxTokensPerBatch].
  List<List<AssessmentSource>> createBatches({
    required List<AssessmentSource> sources,
    required AssessmentBlueprint blueprint,
  }) {
    if (sources.isEmpty) return const [];

    // 1. Filter if selectedChunkIds specified
    var filtered = sources;
    if (blueprint.selectedChunkIds.isNotEmpty) {
      filtered = sources
          .where((s) => blueprint.selectedChunkIds.contains(s.chunkId))
          .toList();
    }

    if (filtered.isEmpty) return const [];

    // 2. Sort deterministically: by pageNumber, then chunkId
    final sorted = List<AssessmentSource>.from(filtered)
      ..sort((a, b) {
        final pageCmp = a.pageNumber.compareTo(b.pageNumber);
        if (pageCmp != 0) return pageCmp;
        return a.chunkId.compareTo(b.chunkId);
      });

    // 3. Batch by token limits
    final batches = <List<AssessmentSource>>[];
    var currentBatch = <AssessmentSource>[];
    var currentBatchTokens = 0;
    final maxTokens = blueprint.maxTokensPerBatch;

    for (final src in sorted) {
      if (currentBatch.isNotEmpty &&
          (currentBatchTokens + src.tokenEstimate) > maxTokens) {
        batches.add(List.unmodifiable(currentBatch));
        currentBatch = <AssessmentSource>[src];
        currentBatchTokens = src.tokenEstimate;
      } else {
        currentBatch.add(src);
        currentBatchTokens += src.tokenEstimate;
      }
    }

    if (currentBatch.isNotEmpty) {
      batches.add(List.unmodifiable(currentBatch));
    }

    return List.unmodifiable(batches);
  }
}
