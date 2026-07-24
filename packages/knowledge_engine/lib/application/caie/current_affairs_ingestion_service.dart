import '../../domain/entities/knowledge_object.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../pipeline/knowledge_ingestion_pipeline.dart';
import 'current_affairs_item.dart';
import 'current_affairs_mapper.dart';
import 'current_affairs_parser.dart';
import 'current_affairs_validation_result.dart';

/// Application service responsible for ingesting Current Affairs knowledge payloads
/// into the TITAN Knowledge Engine.
///
/// Validates, normalizes, maps, and persists Current Affairs items as canonical
/// [KnowledgeObject] entities into [KnowledgeRepository].
class CurrentAffairsIngestionService {
  final KnowledgeRepository _repository;
  final CurrentAffairsParser _parser;
  final CurrentAffairsMapper _mapper;
  final KnowledgeIngestionPipeline? _ingestionPipeline;

  /// Constructs a [CurrentAffairsIngestionService].
  CurrentAffairsIngestionService({
    required KnowledgeRepository repository,
    CurrentAffairsParser? parser,
    CurrentAffairsMapper? mapper,
    KnowledgeIngestionPipeline? ingestionPipeline,
  })  : _repository = repository,
        _parser = parser ?? CurrentAffairsParser(),
        _mapper = mapper ?? CurrentAffairsMapper(parser: parser),
        _ingestionPipeline = ingestionPipeline;

  /// Validates a [CurrentAffairsItem] using the parser.
  CurrentAffairsValidationResult validate(CurrentAffairsItem item) {
    return _parser.validate(item);
  }

  /// Maps a [CurrentAffairsItem] to a canonical [KnowledgeObject].
  KnowledgeObject mapToKnowledge(CurrentAffairsItem item) {
    return _mapper.mapToKnowledge(item);
  }

  /// Ingests a single [CurrentAffairsItem] into TITAN Knowledge Engine.
  Future<CurrentAffairsValidationResult> ingest(CurrentAffairsItem item) async {
    return await ingestBatch([item]);
  }

  /// Ingests a batch list of [CurrentAffairsItem] entities into TITAN Knowledge Engine.
  Future<CurrentAffairsValidationResult> ingestBatch(
    List<CurrentAffairsItem> items,
  ) async {
    final stopwatch = Stopwatch()..start();

    final allWarnings = <String>[];
    final allErrors = <String>[];
    final savedObjects = <KnowledgeObject>[];

    var processedCount = 0;
    var skippedCount = 0;

    for (final item in items) {
      final validation = validate(item);

      if (!validation.isValid) {
        skippedCount++;
        allErrors.addAll(validation.errors.map((e) => '[Item ${item.id}] $e'));
        allWarnings
            .addAll(validation.warnings.map((w) => '[Item ${item.id}] $w'));
        continue;
      }

      allWarnings
          .addAll(validation.warnings.map((w) => '[Item ${item.id}] $w'));

      final normalizedItem = _parser.normalize(item);
      final kObj = mapToKnowledge(normalizedItem);

      await _repository.save(kObj);
      savedObjects.add(kObj);

      // Optionally process through ingestion pipeline if configured
      final pipeline = _ingestionPipeline;
      if (pipeline != null) {
        await pipeline.process(
          rawText: normalizedItem.content,
          title: normalizedItem.title,
          type: kObj.type,
          source: normalizedItem.source,
          subjects: normalizedItem.relatedSubjects,
          topics: normalizedItem.tags,
          metadata: kObj.metadata,
          baseId: normalizedItem.id,
        );
      }

      processedCount++;
    }

    stopwatch.stop();

    return CurrentAffairsValidationResult(
      success: allErrors.isEmpty,
      warnings: allWarnings,
      errors: allErrors,
      statistics: {
        'totalItems': items.length,
        'processedCount': processedCount,
        'skippedCount': skippedCount,
        'savedKnowledgeObjectsCount': savedObjects.length,
        'executionTimeMs': stopwatch.elapsedMilliseconds,
      },
    );
  }
}
