library;

import '../domain/entities/current_affairs_knowledge_object.dart';
import '../domain/entities/news_event.dart';
import '../mapping/current_affairs_mapper.dart';
import '../parser/current_affairs_parser.dart';
import '../repositories/current_affairs_repository.dart';
import '../services/current_affairs_editorial_service.dart';
import '../sources/source_adapter.dart';
import '../validators/current_affairs_validator.dart';

/// Result object for an ingestion run.
class IngestionResult {
  final int totalFetched;
  final int totalIngested;
  final int totalValidated;
  final List<NewsEvent> events;
  final List<CurrentAffairsKnowledgeObject> objects;
  final List<ValidationReport> validationReports;

  const IngestionResult({
    required this.totalFetched,
    required this.totalIngested,
    required this.totalValidated,
    required this.events,
    required this.objects,
    required this.validationReports,
  });
}

/// Production ingestion pipeline converting verified official feeds into GARUDA Knowledge Objects.
class CurrentAffairsIngestionPipeline {
  final CurrentAffairsRepository repository;
  final CurrentAffairsEditorialService editorialService;

  CurrentAffairsIngestionPipeline({
    required this.repository,
    CurrentAffairsEditorialService? editorialService,
  }) : editorialService = editorialService ?? CurrentAffairsEditorialService();

  /// Process raw event JSON maps through full pipeline.
  Future<IngestionResult> ingestRawEvents(List<Map<String, dynamic>> rawPayloads) async {
    final events = <NewsEvent>[];
    final objects = <CurrentAffairsKnowledgeObject>[];
    final reports = <ValidationReport>[];

    final existingObjects = await repository.getAllKnowledgeObjects();

    for (final payload in rawPayloads) {
      final newsEvent = CurrentAffairsParser.parseRawJson(payload);
      events.add(newsEvent);
      await repository.saveNewsEvent(newsEvent);

      final ko = CurrentAffairsMapper.mapToKnowledgeObject(newsEvent);

      final valReport = CurrentAffairsValidator.validate(
        ko,
        existingObjects: [...existingObjects, ...objects],
      );
      reports.add(valReport);

      editorialService.submitToEditorialWorkflow(ko);

      if (valReport.isValid) {
        objects.add(ko);
        await repository.saveKnowledgeObject(ko);
      }
    }

    return IngestionResult(
      totalFetched: rawPayloads.length,
      totalIngested: events.length,
      totalValidated: objects.length,
      events: events,
      objects: objects,
      validationReports: reports,
    );
  }

  /// Process events fetched from a [SourceAdapter].
  Future<IngestionResult> ingestFromAdapter(
    SourceAdapter adapter, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final fetchedEvents = await adapter.fetchEvents(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    final rawPayloads = fetchedEvents.map((e) => e.toJson()).toList();
    return ingestRawEvents(rawPayloads);
  }
}
