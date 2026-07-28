import 'package:titan_ai/titan_ai.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import '../cleaners/text_cleaning_engine.dart';
import '../extractors/concept_extraction_engine.dart';
import '../extractors/metadata_extractor.dart';
import '../extractors/source_extractor.dart';
import '../integration/knowledge_graph_adapter.dart';
import '../integration/search_index_adapter.dart';
import '../language/language_detector.dart';
import '../models/ingestion_source.dart';
import '../models/knowledge_object.dart';
import '../parser/structural_parser.dart';
import '../repository/knowledge_repository.dart';
import '../validators/knowledge_validator.dart';

/// Processing result emitted by [KnowledgeIngestionEngine].
class KnowledgeIngestionResult {
  final KnowledgeObject knowledgeObject;
  final ValidationResult validationResult;
  final KnowledgeGraph knowledgeGraph;
  final bool searchIndexed;
  final DateTime processedAt;

  KnowledgeIngestionResult({
    required this.knowledgeObject,
    required this.validationResult,
    required this.knowledgeGraph,
    required this.searchIndexed,
    DateTime? processedAt,
  }) : processedAt = processedAt ?? DateTime.now();
}

/// Pure Dart Master Engine for Knowledge Ingestion Pipeline.
class KnowledgeIngestionEngine {
  final TextCleaningEngine cleaningEngine;
  final LanguageDetector languageDetector;
  final StructuralParser structuralParser;
  final ConceptExtractionEngine conceptExtractor;
  final MetadataExtractor metadataExtractor;
  final KnowledgeValidator validator;
  final KnowledgeRepository repository;
  final SearchIndexAdapter searchAdapter;
  final KnowledgeGraphAdapter graphAdapter;

  KnowledgeIngestionEngine({
    TextCleaningEngine? cleaningEngine,
    LanguageDetector? languageDetector,
    StructuralParser? structuralParser,
    ConceptExtractionEngine? conceptExtractor,
    MetadataExtractor? metadataExtractor,
    KnowledgeValidator? validator,
    required this.repository,
    required SearchRepository searchRepository,
    required KnowledgeGraphRepository graphRepository,
    AIService? aiService,
  })  : cleaningEngine = cleaningEngine ?? TextCleaningEngine(),
        languageDetector =
            languageDetector ?? LanguageDetector(aiService: aiService),
        structuralParser = structuralParser ?? StructuralParser(),
        conceptExtractor =
            conceptExtractor ?? ConceptExtractionEngine(aiService: aiService),
        metadataExtractor = metadataExtractor ?? MetadataExtractor(),
        validator = validator ?? KnowledgeValidator(),
        searchAdapter = SearchIndexAdapter(searchRepository: searchRepository),
        graphAdapter = KnowledgeGraphAdapter(graphRepository: graphRepository);

  /// Executes full pure Dart Knowledge Ingestion Pipeline on [RawDocumentInput].
  Future<KnowledgeIngestionResult> process(RawDocumentInput input) async {
    // Stage 1: Text Extraction from Source
    final extractor = ExtractorFactory.getExtractor(input.sourceType);
    final rawText = await extractor.extractText(input);

    // Stage 2: Text Cleaning & Normalization
    final cleanedText = cleaningEngine.clean(rawText);

    // Stage 3: Language Detection
    final language = await languageDetector.detectLanguage(cleanedText);

    // Stage 4: Structural Parsing & Block Breakdown
    final structure =
        structuralParser.parse(cleanedText, fallbackTitle: input.fileName);

    // Stage 5: Concept & Glossary Extraction
    final conceptResult =
        await conceptExtractor.extract(cleanedText, structure.title);

    // Stage 6: Metadata Extraction
    final metadata = metadataExtractor.extract(
      input: input,
      cleanedText: cleanedText,
      detectedLanguage: language,
      titleFromStructure: structure.title,
    );

    // Stage 7: Canonical Knowledge Object Construction
    final knowledgeObj = KnowledgeObject(
      id: input.id,
      title: structure.title,
      summary: '[K2 Placeholder Summary]',
      chapter: structure.chapter,
      module: structure.module,
      course: structure.course,
      source: input.fileName,
      language: language,
      difficulty: 'medium',
      estimatedReadingTime:
          (cleanedText.split(RegExp(r'\s+')).length / 200).ceil(),
      learningObjectives: structure.topics,
      prerequisites: const [],
      learningOutcomes: structure.subtopics,
      concepts: conceptResult.concepts,
      keywords: conceptResult.keywords,
      glossary: conceptResult.glossary,
      references: const [],
      contentBlocks: structure.blocks,
      metadata: metadata,
      relationships: const [],
    );

    // Stage 8: Knowledge Validation
    final existingObjects = await repository.getAllKnowledgeObjects();
    final validationResult =
        validator.validate(knowledgeObj, existingObjects: existingObjects);

    if (!validationResult.isValid) {
      throw FormatException(
          'KnowledgeObject validation failed: ${validationResult.errors.join(', ')}');
    }

    // Stage 9: Knowledge Repository Persistence
    await repository.saveKnowledgeObject(knowledgeObj);

    // Stage 10: titan_search Indexing
    await searchAdapter.indexKnowledgeObject(knowledgeObj);

    // Stage 11: titan_knowledge_graph Node & Edge Builder
    final graph = await graphAdapter.buildAndSaveGraph(knowledgeObj);

    return KnowledgeIngestionResult(
      knowledgeObject: knowledgeObj,
      validationResult: validationResult,
      knowledgeGraph: graph,
      searchIndexed: true,
    );
  }

  /// Incremental/Stream Batch Processing for Large Books / Documents.
  Stream<KnowledgeIngestionResult> processBatch(
      List<RawDocumentInput> inputs) async* {
    for (final input in inputs) {
      final result = await process(input);
      yield result;
    }
  }
}
