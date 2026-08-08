library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/scheme_knowledge_object.dart';

/// GARUDA Editorial Production Engine integration for Scheme Knowledge Objects.
/// No Scheme may be published without an official source, evidence and
/// editorial approval — the editorial lifecycle is never bypassed.
class SchemeEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  SchemeEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits a Scheme Knowledge Object into the GARUDA Editorial Production
  /// Engine (registers it in the shared GARUDA knowledge registry/index).
  void submitToEditorialWorkflow(SchemeKnowledgeObject object,
      {int priority = 3}) {
    final baseKo = object.toGarudaKnowledgeObject();
    workflowEngine.registerKnowledgeObject(baseKo, priority: priority);
  }

  /// Advances the Scheme Object to the next sequential stage in the lifecycle.
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

  /// Evaluates Quality Score breakdown for a Scheme Knowledge Object.
  QualityScoreBreakdown calculateQualityScore(SchemeKnowledgeObject object) {
    return QualityScoreEngine.calculateScore(object.toGarudaKnowledgeObject());
  }

  /// Publishes a Scheme Knowledge Object using PublicationService with
  /// Quality Gate enforcement, returning the object with its updated status
  /// and version.
  SchemeKnowledgeObject publishObject(
    SchemeKnowledgeObject object, {
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
