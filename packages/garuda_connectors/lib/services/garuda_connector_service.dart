library;

import 'package:garuda_evidence/garuda_evidence.dart';
import '../connector_sdk/garuda_connector.dart';
import '../pib/pib_connector.dart';
import '../shared/deduplicator.dart';
import '../shared/versioning_orchestrator.dart';

/// High-level orchestration facade linking [GarudaConnector] SDK instances
/// directly to the [GarudaEvidenceService], [EditorialQueue], and Event pipeline.
class GarudaConnectorService {
  final GarudaEvidenceService evidenceService;
  final Map<String, GarudaConnector> _connectors = {};
  final List<EvidenceEvent> _emittedEvents = [];

  GarudaConnectorService({GarudaEvidenceService? evidenceService})
      : evidenceService = evidenceService ?? GarudaEvidenceService() {
    _registerDefaults();
  }

  void _registerDefaults() {
    registerConnector(PIBConnector());
  }

  /// Register a [GarudaConnector] into the service pipeline.
  void registerConnector(GarudaConnector connector) {
    _connectors[connector.sourceName.toLowerCase()] = connector;
    evidenceService.registerCollector(connector);
    evidenceService.sourceRegistry.register(connector.source());
  }

  /// Retrieve a registered connector by source name.
  GarudaConnector? getConnector(String sourceName) {
    return _connectors[sourceName.toLowerCase()];
  }

  /// List all registered connectors.
  List<GarudaConnector> getAllConnectors() => _connectors.values.toList();

  /// Retrieve all events emitted during ingestion.
  List<EvidenceEvent> getEmittedEvents() => List.unmodifiable(_emittedEvents);

  /// Run complete end-to-end ingestion for a named connector:
  /// discover -> fetch -> parse -> validate -> deduplicate -> version -> enqueue into EditorialQueue.
  Future<List<EvidenceObject>> runIngestionPipeline(
    String sourceName, {
    Map<String, dynamic>? params,
  }) async {
    final connector = getConnector(sourceName);
    if (connector == null) {
      throw ArgumentError('Connector for source "$sourceName" is not registered.');
    }

    final payloads = await connector.discover(params: params);
    final processedEvidence = <EvidenceObject>[];
    final now = DateTime.now();

    for (final payload in payloads) {
      _emittedEvents.add(EvidenceCollected(
        eventId: 'evt_coll_${payload.sourceIdentifier}',
        timestamp: now,
        sourceName: connector.sourceName,
        evidenceId: payload.sourceIdentifier,
      ));

      final evidence = await connector.parseRaw(payload);
      _emittedEvents.add(EvidenceParsed(
        eventId: 'evt_parse_${evidence.id}',
        timestamp: now,
        evidence: evidence,
      ));

      final valResult = await evidenceService.validator.validate(evidence);
      _emittedEvents.add(EvidenceValidated(
        eventId: 'evt_val_${evidence.id}',
        timestamp: now,
        evidenceId: evidence.id,
        isValid: valResult.isValid,
      ));

      if (!valResult.isValid) continue;

      // Deduplication check against repository
      final existing = await evidenceService.repository.findById(evidence.id);
      EvidenceObject finalToSave = evidence;

      if (existing != null) {
        if (EvidenceDeduplicator.isDuplicate(evidence, existing)) {
          // Versioning: create Version 2 without overwriting
          finalToSave = VersioningOrchestrator.createNextVersion(
            existing: existing,
            updatedContent: evidence,
            editorOrConnector: connector.metadata().connectorName,
            reason: 'Content update detected during connector ingestion',
          );
        }
      }

      // Store in repository
      await evidenceService.repository.save(finalToSave);

      // Enqueue in EditorialQueue for REVIEW_PENDING status
      final queuedItem = await evidenceService.editorialQueue.enqueue(
        finalToSave,
        reason: 'Ingested via ${connector.metadata().connectorName} - pending editorial review',
      );

      _emittedEvents.add(EvidenceApproved(
        eventId: 'evt_queue_${finalToSave.id}',
        timestamp: now,
        evidenceId: finalToSave.id,
        reviewer: 'EditorialQueue_ReviewPending',
      ));

      processedEvidence.add(queuedItem.evidence);
    }

    // Health check event
    final health = await connector.healthCheckDiagnostic();
    _emittedEvents.add(CollectorFailed(
      eventId: 'evt_health_${connector.sourceName}',
      timestamp: now,
      collectorName: connector.sourceName,
      errorMessage: health.message,
    ));

    return processedEvidence;
  }
}
