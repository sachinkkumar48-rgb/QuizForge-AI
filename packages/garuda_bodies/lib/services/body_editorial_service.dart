library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/body_knowledge_object.dart';

/// GARUDA Editorial Production Engine integration for Body Knowledge Objects.
/// No Body may be published without an official source, evidence and editorial
/// approval — the editorial lifecycle is never bypassed.
class BodyEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  BodyEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits a Body Knowledge Object into the GARUDA Editorial Production
  /// Engine (registers it in the shared GARUDA knowledge registry/index).
  void submitToEditorialWorkflow(BodyKnowledgeObject object,
      {int priority = 3}) {
    final baseKo = object.toGarudaKnowledgeObject();
    workflowEngine.registerKnowledgeObject(baseKo, priority: priority);
  }

  /// Advances the Body Object to the next sequential stage in the lifecycle.
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

  /// Evaluates Quality Score breakdown for a Body Knowledge Object.
  QualityScoreBreakdown calculateQualityScore(BodyKnowledgeObject object) {
    return QualityScoreEngine.calculateScore(object.toGarudaKnowledgeObject());
  }

  /// Publishes a Body Knowledge Object using PublicationService with Quality
  /// Gate enforcement, returning the object with its updated status/version.
  BodyKnowledgeObject publishObject(
    BodyKnowledgeObject object, {
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
