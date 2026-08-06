import '../../audit/knowledge_audit_trail.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../../repositories/knowledge_repository.dart';
import '../models/knowledge_editorial_status.dart';

/// Publication Workflow & Editorial Queue Service for GARUDA Knowledge Ingestion.
class KnowledgePublicationService {
  final KnowledgeRepository repository;
  final KnowledgeAuditTrail auditTrail;

  final Map<String, KnowledgeEditorialStatus> _editorialQueue = {};

  KnowledgePublicationService({
    required this.repository,
    required this.auditTrail,
  });

  /// Submit an ingested object into the editorial queue with initial state (Default: draft).
  void queueForReview(KnowledgeObject object, {KnowledgeEditorialStatus initialStatus = KnowledgeEditorialStatus.draft}) {
    _editorialQueue[object.id.value] = initialStatus;
    auditTrail.record(AuditRecord(
      timestamp: DateTime.now(),
      packageName: 'publication_service',
      objectId: object.id.value,
      objectType: object.type.name,
      version: object.currentVersion.versionNumber,
      operation: 'QUEUE_REVIEW',
      result: 'SUCCESS',
      durationMs: 0.0,
      details: 'Queued with status ${initialStatus.name}',
    ));
  }

  /// Get current editorial status of an object.
  KnowledgeEditorialStatus getStatus(String objectId) {
    return _editorialQueue[objectId] ?? KnowledgeEditorialStatus.draft;
  }

  /// Transition object editorial status.
  Future<bool> transitionStatus({
    required String objectId,
    required KnowledgeEditorialStatus newStatus,
    String? reviewerNotes,
  }) async {
    final current = getStatus(objectId);
    if (current == newStatus) return true;

    // Validate state transitions
    if (!_isValidTransition(current, newStatus)) {
      auditTrail.record(AuditRecord(
        timestamp: DateTime.now(),
        packageName: 'publication_service',
        objectId: objectId,
        objectType: 'KNOWLEDGE_OBJECT',
        version: 1,
        operation: 'TRANSITION_STATUS',
        result: 'FAILURE',
        durationMs: 0.0,
        details: 'Invalid transition from ${current.name} to ${newStatus.name}',
      ));
      return false;
    }

    _editorialQueue[objectId] = newStatus;

    // Update object metadata in repository if object exists
    final obj = await repository.findById(KnowledgeObjectId(objectId));
    if (obj != null) {
      final updatedMeta = KnowledgeMetadata(
        createdAt: obj.metadata.createdAt,
        updatedAt: DateTime.now(),
        createdBy: obj.metadata.createdBy,
        lastUpdatedBy: 'Publication_Service',
        locale: obj.metadata.locale,
        customAttributes: {
          ...obj.metadata.customAttributes,
          'editorialStatus': newStatus.name,
          'lastReviewedAt': DateTime.now().toIso8601String(),
          if (reviewerNotes != null) 'reviewerNotes': reviewerNotes,
        },
      );
      await repository.update(obj.copyWith(metadata: updatedMeta));
    }

    auditTrail.record(AuditRecord(
      timestamp: DateTime.now(),
      packageName: 'publication_service',
      objectId: objectId,
      objectType: 'KNOWLEDGE_OBJECT',
      version: 1,
      operation: 'TRANSITION_STATUS',
      result: 'SUCCESS',
      durationMs: 0.0,
      details: 'Transitioned from ${current.name} to ${newStatus.name}. Notes: $reviewerNotes',
    ));

    return true;
  }

  bool _isValidTransition(KnowledgeEditorialStatus current, KnowledgeEditorialStatus next) {
    if (current == next) return true;
    switch (current) {
      case KnowledgeEditorialStatus.draft:
        return next == KnowledgeEditorialStatus.editorialReview || next == KnowledgeEditorialStatus.archived;
      case KnowledgeEditorialStatus.editorialReview:
        return next == KnowledgeEditorialStatus.approved || next == KnowledgeEditorialStatus.draft || next == KnowledgeEditorialStatus.archived;
      case KnowledgeEditorialStatus.approved:
        return next == KnowledgeEditorialStatus.published || next == KnowledgeEditorialStatus.editorialReview || next == KnowledgeEditorialStatus.archived;
      case KnowledgeEditorialStatus.published:
        return next == KnowledgeEditorialStatus.archived || next == KnowledgeEditorialStatus.editorialReview;
      case KnowledgeEditorialStatus.archived:
        return next == KnowledgeEditorialStatus.draft;
    }
  }

  /// Returns list of object IDs in a specific status state.
  List<String> getObjectsByStatus(KnowledgeEditorialStatus status) {
    return _editorialQueue.entries
        .where((e) => e.value == status)
        .map((e) => e.key)
        .toList();
  }
}
