import '../../domain/entities/knowledge_object.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../pipeline/knowledge_ingestion_pipeline.dart';
import 'previous_year_question.dart';
import 'pyq_mapper.dart';
import 'pyq_metadata_extractor.dart';
import 'pyq_parser.dart';
import 'pyq_validation_result.dart';

/// Application service responsible for ingesting Previous Year Questions into
/// the TITAN Knowledge Engine.
///
/// Validates, normalizes, maps, and persists PYQs as canonical [KnowledgeObject]
/// entities into [KnowledgeRepository].
class PYQIngestionService {
  final KnowledgeRepository _repository;
  final PYQParser _parser;
  final PYQMapper _mapper;
  final KnowledgeIngestionPipeline? _ingestionPipeline;

  /// Constructs a [PYQIngestionService].
  PYQIngestionService({
    required KnowledgeRepository repository,
    PYQParser? parser,
    PYQMetadataExtractor? extractor,
    PYQMapper? mapper,
    KnowledgeIngestionPipeline? ingestionPipeline,
  })  : _repository = repository,
        _parser = parser ?? PYQParser(),
        _mapper = mapper ?? PYQMapper(parser: parser, extractor: extractor),
        _ingestionPipeline = ingestionPipeline;

  /// Validates a [PreviousYearQuestion] using the parser.
  PYQValidationResult validate(PreviousYearQuestion question) {
    return _parser.validate(question);
  }

  /// Maps a [PreviousYearQuestion] to a canonical [KnowledgeObject].
  KnowledgeObject mapToKnowledge(PreviousYearQuestion question) {
    return _mapper.mapToKnowledge(question);
  }

  /// Ingests a single [PreviousYearQuestion] into TITAN Knowledge Engine.
  Future<PYQValidationResult> ingest(PreviousYearQuestion question) async {
    return await ingestBatch([question]);
  }

  /// Ingests a batch list of [PreviousYearQuestion] entities into TITAN Knowledge Engine.
  Future<PYQValidationResult> ingestBatch(
    List<PreviousYearQuestion> questions,
  ) async {
    final stopwatch = Stopwatch()..start();

    final allWarnings = <String>[];
    final allErrors = <String>[];
    final savedObjects = <KnowledgeObject>[];

    var processedCount = 0;
    var skippedCount = 0;

    for (final question in questions) {
      final validation = validate(question);

      if (!validation.isValid) {
        skippedCount++;
        allErrors.addAll(
            validation.errors.map((e) => '[Question ${question.id}] $e'));
        allWarnings.addAll(
            validation.warnings.map((w) => '[Question ${question.id}] $w'));
        continue;
      }

      allWarnings.addAll(
          validation.warnings.map((w) => '[Question ${question.id}] $w'));

      final normalizedQuestion = _parser.normalize(question);
      final kObj = mapToKnowledge(normalizedQuestion);

      await _repository.save(kObj);
      savedObjects.add(kObj);

      // Optionally process through ingestion pipeline if configured
      final pipeline = _ingestionPipeline;
      if (pipeline != null) {
        final contentText = '${normalizedQuestion.question}\n\n'
            '${normalizedQuestion.options.join('\n')}\n\n'
            'Explanation: ${normalizedQuestion.explanation}';

        await pipeline.process(
          rawText: contentText,
          title: kObj.title,
          type: kObj.type,
          source: kObj.source,
          subjects: kObj.subjects,
          topics: kObj.topics,
          keywords: kObj.keywords,
          metadata: kObj.metadata,
          baseId: normalizedQuestion.id,
        );
      }

      processedCount++;
    }

    stopwatch.stop();

    return PYQValidationResult(
      success: allErrors.isEmpty,
      warnings: allWarnings,
      errors: allErrors,
      statistics: {
        'totalQuestions': questions.length,
        'processedCount': processedCount,
        'skippedCount': skippedCount,
        'savedKnowledgeObjectsCount': savedObjects.length,
        'executionTimeMs': stopwatch.elapsedMilliseconds,
      },
    );
  }
}
