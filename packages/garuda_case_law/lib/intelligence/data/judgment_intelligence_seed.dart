/// Curated Judgment Intelligence seed data for the 49-case GARUDA Landmark
/// Case Corpus (TITAN-KO-015.0 P4).
///
/// This table provides the analytical layers — holdings, outcome, reasoning,
/// significance, UPSC intelligence and timeline — for every landmark case.
/// Bench, issues and ratios are derived from the verified P3 record by
/// `JudgmentIntelligenceSupport`.
///
/// Evidence policy: holdings, outcome and timeline decision events carry
/// verified references (they trace to the official judgment record). UPSC
/// intelligence and interpretive characterizations are editorial analysis
/// grounded in those verified facts, and are surfaced as such. Where a fact
/// cannot be established, the field is left empty rather than guessed.
library;

import '../domain/intelligence_enums.dart';
import '../domain/judgment_intelligence.dart';
import 'judgment_intelligence_seed_phase1.dart';
import 'judgment_intelligence_seed_phase2.dart';

/// Curated judgment-intelligence seed for a single case.
class JudgmentIntelligenceSeed {
  final List<JudgmentHolding> holdings;
  final List<JudgmentIssue> extraIssues;
  final List<JudgmentRatio> extraRatios;
  final JudgmentReasoning? reasoning;
  final JudgmentOutcome? outcome;
  final JudicialSignificance? judicialSignificance;
  final UpscJudgmentIntelligence? upscIntelligence;
  final List<JudgmentTimelineEvent> timeline;

  const JudgmentIntelligenceSeed({
    this.holdings = const [],
    this.extraIssues = const [],
    this.extraRatios = const [],
    this.reasoning,
    this.outcome,
    this.judicialSignificance,
    this.upscIntelligence,
    this.timeline = const [],
  });
}

/// Verified evidence reference resolving to the official judgment record.
IntelligenceEvidence evr(String caseId, [String? note]) => IntelligenceEvidence(
      evidenceId: 'ev_${caseId}_official',
      source: 'Supreme Court of India official judgment record',
      verified: true,
      note: note,
    );

/// Editorial evidence reference — analytical content grounded in the verified
/// judgment record, never presented as a judicial fact itself.
IntelligenceEvidence edr(String caseId, [String? note]) => IntelligenceEvidence(
      evidenceId: 'ev_${caseId}_official',
      source: 'GARUDA editorial analysis grounded in the verified judgment record',
      verified: false,
      note: note,
    );

/// Common UPSC syllabus footprint for constitutional landmark cases.
const List<UpscSyllabusArea> upscPolityCore = [
  UpscSyllabusArea.gs2,
  UpscSyllabusArea.prelimsPolity,
  UpscSyllabusArea.essay,
  UpscSyllabusArea.interview,
];

/// Registry keyed by caseId, composed from the Phase-I and Phase-II seed
/// tables. Every case in the 49-case corpus is represented.
class JudgmentIntelligenceSeedData {
  static final Map<String, JudgmentIntelligenceSeed> seeds = {
    ...JudgmentIntelligenceSeedPhase1.seeds,
    ...JudgmentIntelligenceSeedPhase2.seeds,
  };
}
