import '../../domain/entities/knowledge_object.dart';
import '../../domain/value_objects/knowledge_type.dart';
import 'knowledge_chunk_builder.dart';
import 'knowledge_object_factory.dart';
import 'pipeline_result.dart';
import 'text_normalizer.dart';

/// Main orchestrator of the Knowledge Ingestion Pipeline.
///
/// Accepts raw text from any source (PDF, Article, PYQ, Book, Note, Report)
/// and normalizes, chunks, and transforms it into immutable [KnowledgeObject] entities.
class KnowledgeIngestionPipeline {
  /// Text normalization component.
  final TextNormalizer normalizer;

  /// Deterministic chunking component.
  final KnowledgeChunkBuilder chunkBuilder;

  /// Knowledge object factory component.
  final KnowledgeObjectFactory objectFactory;

  /// Constructs a [KnowledgeIngestionPipeline] with optional custom components.
  KnowledgeIngestionPipeline({
    TextNormalizer? normalizer,
    KnowledgeChunkBuilder? chunkBuilder,
    KnowledgeObjectFactory? objectFactory,
  })  : normalizer = normalizer ?? TextNormalizer(),
        chunkBuilder = chunkBuilder ?? const KnowledgeChunkBuilder(),
        objectFactory = objectFactory ?? KnowledgeObjectFactory();

  /// Processes [rawText] and transforms it into a [PipelineResult] containing
  /// generated [KnowledgeObject] entities and processing statistics.
  Future<PipelineResult> process({
    required String rawText,
    required String title,
    required KnowledgeType type,
    String source = '',
    String language = 'en',
    List<String> subjects = const [],
    List<String> topics = const [],
    List<String> keywords = const [],
    Map<String, dynamic> metadata = const {},
    KnowledgeChunkOptions? chunkOptions,
    String? baseId,
  }) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    final originalCharCount = rawText.length;

    // Handle empty input edge case
    if (rawText.trim().isEmpty) {
      stopwatch.stop();
      warnings.add('Raw input text is empty or whitespace only.');
      return PipelineResult(
        objects: const [],
        statistics: PipelineStats(
          originalCharCount: originalCharCount,
          normalizedCharCount: 0,
          chunkCount: 0,
          totalWords: 0,
        ),
        processingDuration: stopwatch.elapsed,
        warnings: warnings,
        isSuccess: true,
      );
    }

    // 1. Text Normalization
    final normalizedText = normalizer.normalize(rawText);
    final normalizedCharCount = normalizedText.length;

    if (normalizedText.isEmpty) {
      warnings.add('Text normalization resulted in empty content.');
    }

    // 2. Chunk Building
    final chunks = chunkBuilder.buildChunks(
      normalizedText,
      options: chunkOptions,
    );

    // 3. Knowledge Object Creation
    final objects = <KnowledgeObject>[];
    var totalWords = 0;

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final object = objectFactory.createFromChunk(
        chunkText: chunk,
        chunkIndex: i,
        totalChunks: chunks.length,
        sourceTitle: title,
        type: type,
        source: source,
        language: language,
        subjects: subjects,
        topics: topics,
        keywords: keywords,
        metadata: metadata,
        baseId: baseId,
      );

      objects.add(object);
      final wordCount = object.metadata['wordCount'] as int? ?? 0;
      totalWords += wordCount;
    }

    stopwatch.stop();

    final stats = PipelineStats(
      originalCharCount: originalCharCount,
      normalizedCharCount: normalizedCharCount,
      chunkCount: objects.length,
      totalWords: totalWords,
    );

    return PipelineResult(
      objects: objects,
      statistics: stats,
      processingDuration: stopwatch.elapsed,
      warnings: warnings,
      isSuccess: true,
    );
  }
}
