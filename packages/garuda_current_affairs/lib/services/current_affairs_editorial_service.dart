library;

import 'package:garuda_editor/garuda_editor.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class CurrentAffairsEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  CurrentAffairsEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits a Current Affairs Knowledge Object into the GARUDA Editorial Production Engine.
  void submitToEditorialWorkflow(CurrentAffairsKnowledgeObject object, {int priority = 3}) {
    final baseKo = object.toGarudaKnowledgeObject();
    workflowEngine.registerKnowledgeObject(baseKo, priority: priority);
  }

  /// Advances the Current Affairs Object to the next sequential stage in the 10-state lifecycle.
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

  /// Evaluates Quality Score breakdown for a Current Affairs Knowledge Object.
  QualityScoreBreakdown calculateQualityScore(CurrentAffairsKnowledgeObject object) {
    return QualityScoreEngine.calculateScore(object.toGarudaKnowledgeObject());
  }

  /// Publishes a Current Affairs Knowledge Object using PublicationService with Quality Gate enforcement.
  CurrentAffairsKnowledgeObject publishObject(
    CurrentAffairsKnowledgeObject object, {
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
