library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/report_knowledge_object.dart';

/// GARUDA Editorial Production Engine integration for Report Knowledge Objects.
/// No Report Knowledge Object may be published without an official source, evidence
/// and editorial approval.
class ReportEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  ReportEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits a Report Knowledge Object into the GARUDA Editorial Production Engine.
  void submitToEditorialWorkflow(ReportKnowledgeObject object,
      {int priority = 3}) {
    workflowEngine.registerKnowledgeObject(object.toGarudaKnowledgeObject(),
        priority: priority);
  }

  /// Submits any GARUDA base Knowledge Object (Index, Survey, Indicator, ...)
  /// into the Editorial Production Engine.
  void submitKnowledgeObject(KnowledgeObject object, {int priority = 3}) {
    workflowEngine.registerKnowledgeObject(object, priority: priority);
  }

  /// Advances the Report Object to the next sequential stage in the 10-state lifecycle.
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

  /// Evaluates Quality Score breakdown for a Report Knowledge Object.
  QualityScoreBreakdown calculateQualityScore(ReportKnowledgeObject object) {
    return QualityScoreEngine.calculateScore(object.toGarudaKnowledgeObject());
  }

  /// Publishes a Report Knowledge Object using PublicationService with Quality Gate enforcement.
  ReportKnowledgeObject publishObject(
    ReportKnowledgeObject object, {
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
