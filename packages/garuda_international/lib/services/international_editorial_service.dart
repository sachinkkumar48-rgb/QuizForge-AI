library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/international_knowledge_object.dart';

/// GARUDA Editorial Production Engine integration for International Knowledge
/// Objects. No organisation may be published without an official source,
/// evidence and editorial approval — the editorial lifecycle is never bypassed.
class InternationalEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  InternationalEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits an International Knowledge Object into the GARUDA Editorial
  /// Production Engine (registers it in the shared GARUDA knowledge
  /// registry/index).
  void submitToEditorialWorkflow(InternationalKnowledgeObject object,
      {int priority = 3}) {
    final baseKo = object.toGarudaKnowledgeObject();
    workflowEngine.registerKnowledgeObject(baseKo, priority: priority);
  }

  /// Advances the Object to the next sequential stage in the lifecycle.
  TransitionResult advanceEditorialStage({
    required String objectId,
    required String actorId,
    required String actorName,
    String? comments,
  }) {
    return workflowEngine.advanceStage(
      objectId: objectId,
      actorId: actorId,
      actorName: actorName,
      comments: comments,
    );
  }

  /// Evaluates Quality Score breakdown for an International Knowledge Object.
  QualityScoreBreakdown calculateQualityScore(
      InternationalKnowledgeObject object) {
    return QualityScoreEngine.calculateScore(object.toGarudaKnowledgeObject());
  }

  /// Publishes an International Knowledge Object using PublicationService with
  /// Quality Gate enforcement, returning the object with updated status/version.
  InternationalKnowledgeObject publishObject(
    InternationalKnowledgeObject object, {
    required String actorId,
    required String actorName,
  }) {
    final baseKo = object.toGarudaKnowledgeObject();
    final publishedBase = workflowEngine.publicationService.publish(
      baseKo,
      actorId: actorId,
      actorName: actorName,
    );

    return object.copyWith(
      editorialStatus: publishedBase.status,
      version: publishedBase.version,
    );
  }
}
