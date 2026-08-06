import '../analytics/knowledge_analytics_engine.dart';
import '../audit/knowledge_audit_trail.dart';
import '../domain/entities/knowledge_object.dart';
import '../indexing/knowledge_index_manager.dart';
import '../integration/cache/knowledge_cache_manager.dart';
import '../integration/events/knowledge_event_bus.dart';
import '../integration/events/pipeline_events.dart';
import '../middleware/knowledge_pipeline_middleware.dart';
import '../repositories/knowledge_repository.dart';
import '../transactions/knowledge_rollback_manager.dart';
import '../transactions/knowledge_transaction.dart';
import '../validators/broken_reference_validator.dart';
import '../validators/circular_reference_validator.dart';
import '../validators/duplicate_id_validator.dart';
import '../validators/invalid_relationship_validator.dart';
import '../validators/invalid_version_validator.dart';
import 'knowledge_pipeline_context.dart';
import 'knowledge_pipeline_metrics.dart';
import 'knowledge_pipeline_result.dart';

class KnowledgeRegistrationPipeline {
  final KnowledgeRepository repository;
  final KnowledgeCacheManager cacheManager;
  final KnowledgeIndexManager indexManager;
  final KnowledgeAnalyticsEngine analyticsEngine;
  final KnowledgeEventBus eventBus;
  final KnowledgeRollbackManager rollbackManager;
  final KnowledgeAuditTrail auditTrail;
  final KnowledgePipelineMetrics metrics;

  final List<KnowledgePipelineMiddleware> middlewares = [];

  // Validators
  final _dupIdValidator = DuplicateIdValidator();
  final _brokenRefValidator = BrokenReferenceValidator();
  final _circRefValidator = CircularReferenceValidator();
  final _invalidVerValidator = InvalidVersionValidator();
  final _invalidRelValidator = InvalidRelationshipValidator();

  KnowledgeRegistrationPipeline({
    required this.repository,
    required this.cacheManager,
    required this.indexManager,
    required this.analyticsEngine,
    required this.eventBus,
    required this.rollbackManager,
    required this.auditTrail,
    required this.metrics,
  });

  Future<KnowledgePipelineResult> process(
    KnowledgeObject inputObject, {
    String packageName = 'default',
    Map<String, dynamic> metadata = const {},
  }) async {
    final startTime = DateTime.now();
    final context = KnowledgePipelineContext(
      inputObject: inputObject,
      packageName: packageName,
      startTime: startTime,
      metadata: metadata,
    );

    for (final mw in middlewares) {
      await mw.preProcess(context);
    }

    eventBus.publish(BeforeRegistrationEvent(
      objectId: inputObject.id.value,
      packageName: packageName,
    ));

    String? txId;

    try {
      // Stage 1: Receive Object
      final object = context.inputObject;

      // Stage 2: Validate Structure
      if (object.title.trim().isEmpty || object.content.trim().isEmpty) {
        return _fail(context, stage: 2, message: 'Invalid object structure: title and content must not be empty');
      }

      // Stage 3: Validate References
      final existingAll = await repository.bulkExport();
      final brokenRes = _brokenRefValidator.validate([...existingAll, object]);
      if (!brokenRes.isValid) {
        return _fail(context, stage: 3, message: 'Broken reference validation failed', issues: brokenRes.issues);
      }

      // Stage 4: Duplicate Detection & Version Check setup
      final dupRes = _dupIdValidator.validate([object]);
      if (!dupRes.isValid && existingAll.isEmpty) {
        metrics.duplicateCount++;
      }

      final existing = await repository.findById(object.id);
      context.previousState = existing;
      context.isUpdateOperation = (existing != null);

      if (existing != null && object.currentVersion.versionNumber <= existing.currentVersion.versionNumber) {
        metrics.duplicateCount++;
        return _fail(
          context,
          stage: 5,
          message: 'Version comparison failed: New version (${object.currentVersion.versionNumber}) is not greater than existing version (${existing.currentVersion.versionNumber})',
        );
      }

      // Stage 5: Version Comparison & Sequence Validation
      final verRes = _invalidVerValidator.validate([object]);
      if (!verRes.isValid) {
        return _fail(context, stage: 5, message: 'Invalid version sequence', issues: verRes.issues);
      }

      // Stage 6: Relationship Validation & Circularity
      final relRes = _invalidRelValidator.validate([object]);
      if (!relRes.isValid) {
        return _fail(context, stage: 6, message: 'Relationship validation failed', issues: relRes.issues);
      }

      final circRes = _circRefValidator.validate([...existingAll, object]);
      if (!circRes.isValid) {
        return _fail(context, stage: 6, message: 'Circular reference detected', issues: circRes.issues);
      }

      eventBus.publish(AfterValidationEvent(objectId: object.id.value, isValid: true, issueCount: 0));

      // Stage 7: Repository Write (with Transaction)
      txId = 'TX-${object.id.value}-${DateTime.now().millisecondsSinceEpoch}';
      final tx = KnowledgeTransaction(
        transactionId: txId,
        targetObject: object,
        originalState: existing,
        startedAt: startTime,
      );
      rollbackManager.startTransaction(tx);

      eventBus.publish(BeforeRepositoryWriteEvent(
        objectId: object.id.value,
        operation: context.isUpdateOperation ? 'UPDATE' : 'CREATE',
      ));

      if (context.isUpdateOperation) {
        await repository.update(object);
      } else {
        await repository.create(object);
      }

      await rollbackManager.commitTransaction(txId);
      eventBus.publish(RepositoryUpdatedEvent(
        objectId: object.id.value,
        operation: context.isUpdateOperation ? 'UPDATE' : 'CREATE',
      ));

      // Stage 8: Cache Update & Invalidation
      cacheManager.cacheLookup(object);
      cacheManager.invalidateRelationships(object.id.value);
      cacheManager.invalidateStatistics(packageName);

      // Stage 9: Search Index Update
      indexManager.indexObject(object);
      eventBus.publish(IndexUpdatedEvent(objectId: object.id.value));

      // Stage 10: Analytics Update
      eventBus.publish(AnalyticsUpdatedEvent(objectId: object.id.value));

      // Stage 11: Event Publishing
      final durationMs = DateTime.now().difference(startTime).inMicroseconds / 1000.0;
      eventBus.publish(RegistrationCompletedEvent(
        objectId: object.id.value,
        durationMs: durationMs,
      ));

      // Stage 12: Audit Recording
      auditTrail.record(AuditRecord(
        timestamp: DateTime.now(),
        packageName: packageName,
        objectId: object.id.value,
        objectType: object.type.name,
        version: object.currentVersion.versionNumber,
        operation: context.isUpdateOperation ? 'UPDATE' : 'CREATE',
        result: 'SUCCESS',
        durationMs: durationMs,
      ));

      metrics.recordSuccess(durationMs);
      final result = KnowledgePipelineResult.success(object: object, durationMs: durationMs);

      for (final mw in middlewares) {
        await mw.postProcess(context, result);
      }

      return result;
    } catch (e) {
      if (txId != null) {
        await rollbackManager.rollbackTransaction(txId, e.toString());
      }
      return _fail(context, stage: 7, message: 'Exception during write: $e');
    }
  }

  KnowledgePipelineResult _fail(
    KnowledgePipelineContext context, {
    required int stage,
    required String message,
    List<dynamic> issues = const [],
  }) {
    final durationMs = DateTime.now().difference(context.startTime).inMicroseconds / 1000.0;
    metrics.recordFailure(durationMs, isValidation: stage <= 6);

    eventBus.publish(RegistrationFailedEvent(
      objectId: context.inputObject.id.value,
      reason: message,
      failedStage: stage,
    ));

    auditTrail.record(AuditRecord(
      timestamp: DateTime.now(),
      packageName: context.packageName,
      objectId: context.inputObject.id.value,
      objectType: context.inputObject.type.name,
      version: context.inputObject.currentVersion.versionNumber,
      operation: context.isUpdateOperation ? 'UPDATE' : 'CREATE',
      result: 'FAILURE',
      durationMs: durationMs,
      details: message,
    ));

    return KnowledgePipelineResult.failure(
      stage: stage,
      message: message,
      durationMs: durationMs,
    );
  }
}
