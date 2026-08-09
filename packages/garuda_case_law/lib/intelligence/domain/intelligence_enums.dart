/// GARUDA Judgment Intelligence enums (TITAN-KO-015.0 P4).
///
/// Strongly-typed vocabulary used across the Judgment Intelligence Engine so
/// that no intelligence field is represented as an arbitrary string.
library;

/// Confidence in the evidentiary basis of a piece of judgment intelligence.
///
/// Evidence-gated: a component may only be `verified` where it traces to the
/// official judgment record or an authoritative source registered with the
/// evidence registry. Everything analytical is surfaced as `editorial`.
enum IntelligenceConfidence {
  /// Traceable to the official judgment record / registered corpus evidence.
  verified,

  /// Editorial interpretation grounded in verified facts (UPSC analysis etc.).
  editorial,

  /// Partial or uncertain — the limitation is represented explicitly.
  limited,
}

/// Composition of the bench that heard the case.
enum JudgmentBenchType {
  /// Constitution Bench (5 or more judges) under Article 145(3).
  constitutionBench,

  /// Division Bench (2-3 judges).
  divisionBench,

  /// Larger Full Bench (7 or more judges).
  fullBench,

  /// Single-judge bench.
  singleJudgeBench,

  /// Composition not established.
  other,
}

/// Category of a legal / constitutional issue framed by the court.
enum IssueCategory {
  constitutional,
  statutory,
  administrative,
  criminal,
  civil,
  rights,
  governance,
  electoral,
  environmental,
  federalism,
  socialJustice,
  service,
  economic,
  procedural,
  other,
}

/// Importance of an issue relative to the core of the judgment.
enum IssueImportance {
  core,
  significant,
  peripheral,
}

/// Scope of a holding — how far the rule announced reaches.
enum HoldingScope {
  /// Confined to the decided point.
  narrow,

  /// Covers the decided point and its direct corollaries.
  medium,

  /// Announces a wide rule or a set of guiding principles.
  broad,
}

/// Nature of a ratio / principle extracted from the judgment.
enum RatioType {
  ratioDecidendi,
  obiterDictum,
  guidingPrinciple,
}

/// Interpretive approach adopted by the court in construing the Constitution.
enum InterpretiveApproach {
  literal,
  purposive,
  harmonious,
  progressive,
  originalist,
  pragmatic,
  textualist,
  other,
}

/// Disposition of the case.
enum OutcomeDisposition {
  upheld,
  upheldWithDirections,
  struckDown,
  partlyStruckDown,
  allowed,
  partlyAllowed,
  dismissed,
  guidelinesIssued,
  declaration,
  stayGranted,
  ordersIssued,
  reference,
  other,
}

/// UPSC syllabus areas a judgment serves.
enum UpscSyllabusArea {
  gs1,
  gs2,
  gs3,
  gs4,
  essay,
  prelimsPolity,
  prelimsGovernance,
  prelimsHistory,
  prelimsEnvironment,
  prelimsSocial,
  interview,
}

extension IntelligenceConfidenceExtension on IntelligenceConfidence {
  String get displayName => switch (this) {
        IntelligenceConfidence.verified => 'Verified',
        IntelligenceConfidence.editorial => 'Editorial Analysis',
        IntelligenceConfidence.limited => 'Limited / Unavailable',
      };
}

extension JudgmentBenchTypeExtension on JudgmentBenchType {
  String get displayName => switch (this) {
        JudgmentBenchType.constitutionBench => 'Constitution Bench',
        JudgmentBenchType.divisionBench => 'Division Bench',
        JudgmentBenchType.fullBench => 'Full Bench',
        JudgmentBenchType.singleJudgeBench => 'Single-Judge Bench',
        JudgmentBenchType.other => 'Other',
      };
}

extension UpscSyllabusAreaExtension on UpscSyllabusArea {
  String get displayName => switch (this) {
        UpscSyllabusArea.gs1 => 'GS Paper I',
        UpscSyllabusArea.gs2 => 'GS Paper II',
        UpscSyllabusArea.gs3 => 'GS Paper III',
        UpscSyllabusArea.gs4 => 'GS Paper IV',
        UpscSyllabusArea.essay => 'Essay Paper',
        UpscSyllabusArea.prelimsPolity => 'Prelims — Polity',
        UpscSyllabusArea.prelimsGovernance => 'Prelims — Governance',
        UpscSyllabusArea.prelimsHistory => 'Prelims — History',
        UpscSyllabusArea.prelimsEnvironment => 'Prelims — Environment',
        UpscSyllabusArea.prelimsSocial => 'Prelims — Society',
        UpscSyllabusArea.interview => 'Interview',
      };
}
