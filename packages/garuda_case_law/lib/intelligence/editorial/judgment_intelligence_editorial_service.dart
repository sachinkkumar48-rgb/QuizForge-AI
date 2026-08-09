/// GARUDA Editorial Production Engine integration for Judgment Intelligence
/// (TITAN-KO-015.0 P4).
///
/// Judgment Intelligence reuses the existing editorial infrastructure — the
/// EditorialWorkflowEngine, QualityScoreEngine and PublicationService — rather
/// than duplicating it. Intelligence respects the same evidence verification,
/// quality scoring, review, approval and publication gates as every other
/// GARUDA Knowledge Object.
library;

import 'package:garuda_editor/garuda_editor.dart';

import '../../domain/entities/case_knowledge_object.dart';
import '../validation/judgment_intelligence_validator.dart';

/// Editorial integration service for Judgment Intelligence.
class JudgmentIntelligenceEditorialService {
  final EditorialWorkflowEngine workflowEngine;

  JudgmentIntelligenceEditorialService({EditorialWorkflowEngine? workflowEngine})
      : workflowEngine = workflowEngine ?? EditorialWorkflowEngine();

  /// Submits a case (with its Judgment Intelligence) into the GARUDA Editorial
  /// Production Engine.
  void submitToEditorialWorkflow(CaseKnowledgeObject c, {int priority = 3}) {
    workflowEngine.registerKnowledgeObject(c.toGarudaKnowledgeObject(),
        priority: priority);
  }

  /// Advances the case through the sequential 10-state editorial lifecycle.
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

  /// Evaluates the Quality Score breakdown for a case (evidence completeness,
  /// official source, knowledge links, editorial review, etc.).
  QualityScoreBreakdown calculateQualityScore(CaseKnowledgeObject c) {
    return QualityScoreEngine.calculateScore(c.toGarudaKnowledgeObject());
  }

  /// Runs the publication Quality Gates for a case. The gate enforces evidence
  /// attachment, official source, structural metadata, editorial approval and
  /// the quality-score threshold.
  QualityGateResult validatePublicationGate(CaseKnowledgeObject c) {
    return QualityGates.validatePublicationGate(c.toGarudaKnowledgeObject());
  }

  /// Publishes a case through the PublicationService with Quality Gates
  /// enforced.
  CaseKnowledgeObject publish(
    CaseKnowledgeObject c, {
    required String actorId,
    required String actorName,
  }) {
    final baseKo = c.toGarudaKnowledgeObject();
    final publishedBase = workflowEngine.publicationService.publish(
      baseKo,
      actorId: actorId,
      actorName: actorName,
    );
    // Keep the package's UPPERCASE editorial-status convention so the bridged
    // object round-trips through _toEditorialStatus() consistently.
    return c.copyWith(
      editorialStatus: publishedBase.status.name.toUpperCase(),
      version: publishedBase.version,
    );
  }

  /// Evidence gate for Judgment Intelligence: a case may only be submitted
  /// with intelligence that passes the evidence-gated validator. Returns the
  /// validation result and whether it is fit for editorial submission.
  IntelligenceValidationResult evidenceVerificationGate(CaseKnowledgeObject c) {
    final result = JudgmentIntelligenceValidator.validate(c);
    return result;
  }

  /// Whether the case's intelligence clears the evidence gate (no errors).
  bool passesEvidenceGate(CaseKnowledgeObject c) {
    final result = JudgmentIntelligenceValidator.validate(c);
    return result.isValid;
  }
}
