import '../domain/entities/enums.dart';
import '../domain/entities/evidence_object.dart';
import '../domain/entities/evidence_search_query.dart';
import '../domain/repositories/evidence_repository.dart';
import '../domain/usecases/collect_evidence_usecase.dart';
import '../domain/usecases/link_knowledge_object_usecase.dart';
import '../domain/usecases/search_evidence_usecase.dart';
import '../domain/usecases/store_evidence_usecase.dart';
import '../domain/usecases/validate_evidence_usecase.dart';
import '../infrastructure/collectors/collector_stubs.dart';
import '../infrastructure/collectors/evidence_collector.dart';
import '../infrastructure/storage/in_memory_evidence_repository.dart';
import '../infrastructure/validators/composite_evidence_validator.dart';
import '../infrastructure/validators/validation_result.dart';
import '../orchestration/monitoring/change_detector.dart';
import '../orchestration/queue/editorial_queue.dart';
import '../orchestration/registry/collector_registry.dart';
import '../orchestration/registry/evidence_source_registry.dart';

/// Master Gateway Service & Orchestrator for GARUDA Evidence Engine in Project TITAN.
/// Provides high-level entry points for evidence ingestion, validation, searching,
/// orchestration registry management, editorial review queueing, and Knowledge Graph linking.
class GarudaEvidenceService {
  final EvidenceRepository repository;
  final CompositeEvidenceValidator validator;
  final CollectorRegistry collectorRegistry;
  final EvidenceSourceRegistry sourceRegistry;
  final EditorialQueue editorialQueue;
  final ChangeDetector changeDetector;

  final Map<String, EvidenceCollector> _legacyCollectorMap = {};

  GarudaEvidenceService({
    EvidenceRepository? repository,
    CompositeEvidenceValidator? validator,
    CollectorRegistry? collectorRegistry,
    EvidenceSourceRegistry? sourceRegistry,
    EditorialQueue? editorialQueue,
    ChangeDetector? changeDetector,
  })  : repository = repository ?? InMemoryEvidenceRepository(),
        validator = validator ?? CompositeEvidenceValidator.standard(),
        collectorRegistry = collectorRegistry ?? InMemoryCollectorRegistry(),
        sourceRegistry = sourceRegistry ?? InMemoryEvidenceSourceRegistry(),
        editorialQueue = editorialQueue ?? InMemoryEditorialQueue(),
        changeDetector = changeDetector ?? StandardChangeDetector() {
    _registerDefaultCollectors();
  }

  void _registerDefaultCollectors() {
    final defaults = <EvidenceCollector>[
      PIBCollector(),
      PRSCollector(),
      ParliamentCollector(),
      GazetteCollector(),
      SupremeCourtCollector(),
      HighCourtCollector(),
      RBICollector(),
      SEBICollector(),
      NITICollector(),
      CAGCollector(),
      ISROCollector(),
      DRDOCollector(),
      MinistryCollector(),
      WHOCollector(),
      UNCollector(),
      IMFCollector(),
      WorldBankCollector(),
    ];

    for (final collector in defaults) {
      registerCollector(collector);
    }
  }

  /// Register a collector gateway.
  void registerCollector(EvidenceCollector collector) {
    _legacyCollectorMap[collector.sourceName.toLowerCase()] = collector;
    collectorRegistry.registerCollector(collector);
  }

  /// Get a registered collector by source name.
  EvidenceCollector? getCollector(String sourceName) {
    return _legacyCollectorMap[sourceName.toLowerCase()];
  }

  /// List all registered collectors.
  List<EvidenceCollector> getAllCollectors() {
    return _legacyCollectorMap.values.toList();
  }

  /// Collect, validate, and store evidence objects from a named source.
  Future<List<EvidenceObject>> ingestFromSource(
    String sourceName, {
    Map<String, dynamic>? params,
  }) async {
    final collector = getCollector(sourceName);
    if (collector == null) {
      throw ArgumentError('Collector for source $sourceName is not registered.');
    }

    final collectUseCase = CollectEvidenceUseCase(collector);
    final storeUseCase = StoreEvidenceUseCase(repository);

    final rawObjects = await collectUseCase(params: params);
    final storedList = <EvidenceObject>[];

    for (final evidence in rawObjects) {
      final valResult = await validator.validate(evidence);
      if (valResult.isValid) {
        await storeUseCase(evidence);
        storedList.add(evidence);
      }
    }

    return storedList;
  }

  /// Ingest and validate a specific EvidenceObject directly.
  Future<ValidationResult> ingestEvidence(EvidenceObject evidence) async {
    final validateUseCase = ValidateEvidenceUseCase(validator);
    final storeUseCase = StoreEvidenceUseCase(repository);

    final valResult = await validateUseCase(evidence);
    if (valResult.isValid) {
      await storeUseCase(evidence);
    }
    return valResult;
  }

  /// Query evidence objects using [EvidenceSearchQuery].
  Future<List<EvidenceObject>> search(EvidenceSearchQuery query) async {
    final searchUseCase = SearchEvidenceUseCase(repository);
    return await searchUseCase(query);
  }

  /// Link an EvidenceObject to a Knowledge Graph node.
  Future<EvidenceObject?> linkKnowledgeObject({
    required String evidenceId,
    required KnowledgeObjectType type,
    required String targetLinkId,
  }) async {
    final linkUseCase = LinkKnowledgeObjectUseCase(repository);
    return await linkUseCase(
      evidenceId: evidenceId,
      type: type,
      targetLinkId: targetLinkId,
    );
  }

  /// Check health status across all registered source gateways.
  Future<Map<String, HealthCheckResult>> checkAllGatewaysHealth() async {
    final results = <String, HealthCheckResult>{};
    for (final collector in _legacyCollectorMap.values) {
      results[collector.sourceName] = await collector.healthCheck();
    }
    return results;
  }
}
