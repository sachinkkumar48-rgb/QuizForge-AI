/// Judgment Intelligence Service (TITAN-KO-015.0 P4).
///
/// Read-side accessors over the Judgment Intelligence of a case plus build /
/// enrich / validate operations. The API is deliberately repository-bound so
/// future ingestion sources can be plugged in without changing callers.
library;

import '../../domain/entities/case_knowledge_object.dart';
import '../../repositories/case_repository.dart';
import '../../repositories/in_memory_case_repository.dart';
import '../data/judgment_intelligence_support.dart';
import '../domain/intelligence_enums.dart';
import '../domain/judgment_intelligence.dart';
import '../validation/judgment_intelligence_validator.dart';

/// Production Judgment Intelligence service.
class JudgmentIntelligenceService {
  final CaseRepository repository;

  JudgmentIntelligenceService({CaseRepository? repository})
      : repository = repository ?? InMemoryCaseRepository();

  Future<CaseKnowledgeObject?> _find(String caseId) =>
      repository.findCase(caseId);

  // -------------------------------------------------------------------------
  // Read accessors
  // -------------------------------------------------------------------------

  Future<JudgmentBench?> getBench(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.bench;

  Future<List<JudgmentIssue>> getIssues(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.issues ?? const [];

  Future<List<JudgmentHolding>> getHoldings(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.holdings ?? const [];

  Future<List<JudgmentRatio>> getRatio(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.ratios ?? const [];

  Future<JudgmentReasoning?> getReasoning(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.reasoning;

  Future<JudgmentOutcome?> getOutcome(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.outcome;

  Future<JudicialSignificance?> getJudicialSignificance(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.judicialSignificance;

  Future<UpscJudgmentIntelligence?> getUpscIntelligence(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.upscIntelligence;

  Future<List<JudgmentTimelineEvent>> getTimeline(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence?.timeline ?? const [];

  /// The full intelligence aggregate for a case.
  Future<JudgmentIntelligence?> getIntelligence(String caseId) async =>
      (await _find(caseId))?.judgmentIntelligence;

  // -------------------------------------------------------------------------
  // Build / enrich / validate
  // -------------------------------------------------------------------------

  /// Builds the full Judgment Intelligence for a case from its verified
  /// record plus the curated seed (if any).
  JudgmentIntelligence buildIntelligence(CaseKnowledgeObject c) =>
      JudgmentIntelligenceSupport.buildIntelligence(c);

  /// Attaches the given intelligence to a case, returning a new record.
  CaseKnowledgeObject enrichCase(
          CaseKnowledgeObject c, JudgmentIntelligence intelligence) =>
      c.copyWith(judgmentIntelligence: intelligence);

  /// Attaches the built intelligence to a case, returning a new record.
  CaseKnowledgeObject enrichCaseFromRecord(CaseKnowledgeObject c) =>
      JudgmentIntelligenceSupport.enrichCase(c);

  /// Validates the intelligence attached to a case. See
  /// [JudgmentIntelligenceValidator] for the evidence-gated rule set.
  IntelligenceValidationResult validateIntelligence(CaseKnowledgeObject c) =>
      JudgmentIntelligenceValidator.validate(c);

  /// Validates intelligence across a whole repository.
  Future<IntelligenceValidationResult> validateRepository() async {
    final cases = await repository.getCases();
    return JudgmentIntelligenceValidator.validateRepository(cases);
  }

  // -------------------------------------------------------------------------
  // Analytical helpers over the UPSC intelligence
  // -------------------------------------------------------------------------

  /// UPSC syllabus areas covered by a case (empty when no UPSC intelligence).
  Future<List<UpscSyllabusArea>> getSyllabusAreas(String caseId) async =>
      (await _find(caseId))
              ?.judgmentIntelligence
              ?.upscIntelligence
              ?.relatedSyllabusAreas ??
          const [];

  /// Composite preliminary-relevance keywords for a case (facts + traps).
  Future<List<String>> getPrelimsKeywords(String caseId) async {
    final upsc = (await _find(caseId))?.judgmentIntelligence?.upscIntelligence;
    if (upsc == null) return const [];
    return [
      ...upsc.prelimsFacts,
      ...upsc.prelimsTraps,
      ...upsc.answerKeywords,
    ];
  }
}
