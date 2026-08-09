/// GARUDA Case Law Search enums (TITAN-KO-015.0 P6).
///
/// Small typed vocabulary used by the in-memory search engine so that no
/// search dimension is represented as an arbitrary string. These enums only
/// describe *how* a case is searched — they never add legal facts to the
/// corpus.
library;

import '../../domain/entities/case_enums.dart' show RelevanceLevel;

/// The four UPSC / civil-services relevance dimensions made searchable.
///
/// Each dimension reads the existing P3 `RelevanceLevel` field
/// (`prelimsRelevance`, `mainsRelevance`, `essayRelevance`,
/// `interviewRelevance`) and the P4 `UpscJudgmentIntelligence` layers — no new
/// UPSC content is fabricated.
enum CaseSearchUpscDimension {
  prelims,
  mains,
  essay,
  interview,
}

extension CaseSearchUpscDimensionExtension on CaseSearchUpscDimension {
  /// Human-readable label used in results and reporting.
  String get displayName => switch (this) {
        CaseSearchUpscDimension.prelims => 'Prelims',
        CaseSearchUpscDimension.mains => 'Mains',
        CaseSearchUpscDimension.essay => 'Essay',
        CaseSearchUpscDimension.interview => 'Interview',
      };
}

/// Deterministic ordering of [RelevanceLevel] used by UPSC-aware filters and
/// ranking. `critical` outranks `high`, and so on.
int relevanceRank(RelevanceLevel level) => switch (level) {
      RelevanceLevel.critical => 4,
      RelevanceLevel.high => 3,
      RelevanceLevel.medium => 2,
      RelevanceLevel.low => 1,
      RelevanceLevel.notApplicable => 0,
    };

/// Evidence posture of a search result.
///
/// Derived from the record's own evidence IDs against the official-case and
/// canonical-doctrine registries (see the engine). Search never invents
/// evidence — it only reports the posture the record already carries.
enum SearchEvidenceStatus {
  /// At least one evidence ID resolves to a registered official case record.
  verified,

  /// Evidence IDs exist but none resolve to the registered registries.
  editorial,

  /// No evidence IDs are present on the record.
  unverified,
}
