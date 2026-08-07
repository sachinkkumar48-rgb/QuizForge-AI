library;

import 'package:garuda_editor/garuda_editor.dart';
import '../domain/entities/committee_knowledge_object.dart';

class CommitteeEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  CommitteeEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits a Committee Knowledge Object into the GARUDA Editorial Production Engine.
  void submitToEditorialWorkflow(CommitteeKnowledgeObject object, {int priority = 3}) {
    final baseKo = object.toGarudaKnowledgeObject();
    workflowEngine.registerKnowledgeObject(baseKo, priority: priority);
  }

  /// Advances the Committee Object to the next sequential stage in the 10-state lifecycle.
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

  /// Evaluates Quality Score breakdown for a Committee Knowledge Object.
  QualityScoreBreakdown calculateQualityScore(CommitteeKnowledgeObject object) {
    return QualityScoreEngine.calculateScore(object.toGarudaKnowledgeObject());
  }

  /// Publishes a Committee Knowledge Object using PublicationService with Quality Gate enforcement.
  CommitteeKnowledgeObject publishObject(
    CommitteeKnowledgeObject object, {
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
