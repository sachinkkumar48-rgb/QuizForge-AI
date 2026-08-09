/// GARUDA Judgment Intelligence domain model (TITAN-KO-015.0 P4).
///
/// Immutable, strongly-typed, evidence-backed intelligence components layered
/// on top of the P3 `CaseKnowledgeObject`. Every component that asserts a
/// judicial fact carries an evidence reference and a confidence level; nothing
/// is silently inferred.
library;

import 'package:meta/meta.dart';

import 'intelligence_enums.dart';

// ---------------------------------------------------------------------------
// IntelligenceEvidence
// ---------------------------------------------------------------------------

/// Evidence reference attached to an intelligence component.
///
/// `verified` is true only when the component traces to the official judgment
/// record or an authoritative source registered with the evidence registry.
/// Editorial analysis is surfaced with `verified: false` and a clear note.
@immutable
class IntelligenceEvidence {
  final String evidenceId;
  final String source;
  final bool verified;
  final String? note;

  const IntelligenceEvidence({
    required this.evidenceId,
    required this.source,
    required this.verified,
    this.note,
  });

  const IntelligenceEvidence.unverified({
    this.evidenceId = '',
    this.source = '',
    this.verified = false,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'evidenceId': evidenceId,
        'source': source,
        'verified': verified,
        if (note != null) 'note': note,
      };

  factory IntelligenceEvidence.fromJson(Map<String, dynamic> json) =>
      IntelligenceEvidence(
        evidenceId: json['evidenceId'] as String? ?? '',
        source: json['source'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        note: json['note'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntelligenceEvidence &&
          evidenceId == other.evidenceId &&
          source == other.source &&
          verified == other.verified &&
          note == other.note;

  @override
  int get hashCode => Object.hash(evidenceId, source, verified, note);
}

// ---------------------------------------------------------------------------
// A. JudgmentBench
// ---------------------------------------------------------------------------

/// Verified composition of the bench that decided the case.
@immutable
class JudgmentBench {
  /// Number of judges on the bench (0 when unestablished).
  final int benchSize;

  /// Judge names, recorded only where verified (P3 corpus judge list).
  final List<String> judgeNames;

  /// Type of bench (Constitution / Division / Full / Single).
  final JudgmentBenchType benchType;

  /// Human-readable constitution of bench, e.g. "13-Judge Constitution Bench".
  final String constitutionOfBench;

  /// Evidence reference.
  final IntelligenceEvidence evidence;

  const JudgmentBench({
    this.benchSize = 0,
    this.judgeNames = const [],
    this.benchType = JudgmentBenchType.other,
    this.constitutionOfBench = '',
    required this.evidence,
  });

  bool get isEstablished => benchSize > 0 || judgeNames.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'benchSize': benchSize,
        'judgeNames': judgeNames,
        'benchType': benchType.name,
        'constitutionOfBench': constitutionOfBench,
        'evidence': evidence.toJson(),
      };

  factory JudgmentBench.fromJson(Map<String, dynamic> json) => JudgmentBench(
        benchSize: json['benchSize'] as int? ?? 0,
        judgeNames: (json['judgeNames'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        benchType: JudgmentBenchType.values.firstWhere(
          (e) => e.name == json['benchType'],
          orElse: () => JudgmentBenchType.other,
        ),
        constitutionOfBench: json['constitutionOfBench'] as String? ?? '',
        evidence: IntelligenceEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentBench &&
          benchSize == other.benchSize &&
          judgeNames.length == other.judgeNames.length &&
          benchType == other.benchType &&
          constitutionOfBench == other.constitutionOfBench &&
          evidence == other.evidence;

  @override
  int get hashCode =>
      Object.hash(benchSize, benchType, constitutionOfBench, evidence);
}

// ---------------------------------------------------------------------------
// B. JudgmentIssue
// ---------------------------------------------------------------------------

/// A legal / constitutional issue framed and answered by the judgment.
@immutable
class JudgmentIssue {
  final String issueId;
  final String issue;
  final IssueCategory category;
  final IssueImportance importance;
  final List<String> relatedArticles;
  final List<String> relatedActs;

  const JudgmentIssue({
    required this.issueId,
    required this.issue,
    this.category = IssueCategory.other,
    this.importance = IssueImportance.significant,
    this.relatedArticles = const [],
    this.relatedActs = const [],
  });

  Map<String, dynamic> toJson() => {
        'issueId': issueId,
        'issue': issue,
        'category': category.name,
        'importance': importance.name,
        'relatedArticles': relatedArticles,
        'relatedActs': relatedActs,
      };

  factory JudgmentIssue.fromJson(Map<String, dynamic> json) => JudgmentIssue(
        issueId: json['issueId'] as String? ?? '',
        issue: json['issue'] as String? ?? '',
        category: IssueCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => IssueCategory.other,
        ),
        importance: IssueImportance.values.firstWhere(
          (e) => e.name == json['importance'],
          orElse: () => IssueImportance.significant,
        ),
        relatedArticles:
            (json['relatedArticles'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        relatedActs: (json['relatedActs'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentIssue &&
          issueId == other.issueId &&
          issue == other.issue &&
          category == other.category &&
          importance == other.importance;

  @override
  int get hashCode => Object.hash(issueId, issue, category, importance);
}

// ---------------------------------------------------------------------------
// C. JudgmentHolding
// ---------------------------------------------------------------------------

/// A concise holding with its underlying legal principle.
@immutable
class JudgmentHolding {
  final String holdingId;
  final String holding;
  final String legalPrinciple;
  final HoldingScope scope;
  final IntelligenceConfidence confidence;
  final IntelligenceEvidence evidence;

  const JudgmentHolding({
    required this.holdingId,
    required this.holding,
    this.legalPrinciple = '',
    this.scope = HoldingScope.medium,
    this.confidence = IntelligenceConfidence.verified,
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'holdingId': holdingId,
        'holding': holding,
        'legalPrinciple': legalPrinciple,
        'scope': scope.name,
        'confidence': confidence.name,
        'evidence': evidence.toJson(),
      };

  factory JudgmentHolding.fromJson(Map<String, dynamic> json) =>
      JudgmentHolding(
        holdingId: json['holdingId'] as String? ?? '',
        holding: json['holding'] as String? ?? '',
        legalPrinciple: json['legalPrinciple'] as String? ?? '',
        scope: HoldingScope.values.firstWhere(
          (e) => e.name == json['scope'],
          orElse: () => HoldingScope.medium,
        ),
        confidence: IntelligenceConfidence.values.firstWhere(
          (e) => e.name == json['confidence'],
          orElse: () => IntelligenceConfidence.verified,
        ),
        evidence: IntelligenceEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentHolding &&
          holdingId == other.holdingId &&
          holding == other.holding &&
          scope == other.scope &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(holdingId, holding, scope, confidence);
}

// ---------------------------------------------------------------------------
// D. JudgmentRatio
// ---------------------------------------------------------------------------

/// A ratio / principle extracted from the judgment with its legal basis.
@immutable
class JudgmentRatio {
  final String ratio;
  final RatioType type;
  final String legalProposition;
  final String constitutionalBasis;
  final IntelligenceEvidence evidence;

  const JudgmentRatio({
    required this.ratio,
    this.type = RatioType.ratioDecidendi,
    this.legalProposition = '',
    this.constitutionalBasis = '',
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'ratio': ratio,
        'type': type.name,
        'legalProposition': legalProposition,
        'constitutionalBasis': constitutionalBasis,
        'evidence': evidence.toJson(),
      };

  factory JudgmentRatio.fromJson(Map<String, dynamic> json) => JudgmentRatio(
        ratio: json['ratio'] as String? ?? '',
        type: RatioType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RatioType.ratioDecidendi,
        ),
        legalProposition: json['legalProposition'] as String? ?? '',
        constitutionalBasis: json['constitutionalBasis'] as String? ?? '',
        evidence: IntelligenceEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentRatio &&
          ratio == other.ratio &&
          type == other.type &&
          constitutionalBasis == other.constitutionalBasis;

  @override
  int get hashCode => Object.hash(ratio, type, constitutionalBasis);
}

// ---------------------------------------------------------------------------
// E. JudgmentReasoning
// ---------------------------------------------------------------------------

/// The court's interpretive approach and doctrinal reasoning.
@immutable
class JudgmentReasoning {
  final String summary;
  final InterpretiveApproach approach;
  final List<String> constitutionalPhilosophy;
  final List<String> doctrinalReasoning;
  final List<String> reasoningTools;
  final IntelligenceEvidence evidence;

  const JudgmentReasoning({
    this.summary = '',
    this.approach = InterpretiveApproach.other,
    this.constitutionalPhilosophy = const [],
    this.doctrinalReasoning = const [],
    this.reasoningTools = const [],
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'approach': approach.name,
        'constitutionalPhilosophy': constitutionalPhilosophy,
        'doctrinalReasoning': doctrinalReasoning,
        'reasoningTools': reasoningTools,
        'evidence': evidence.toJson(),
      };

  factory JudgmentReasoning.fromJson(Map<String, dynamic> json) =>
      JudgmentReasoning(
        summary: json['summary'] as String? ?? '',
        approach: InterpretiveApproach.values.firstWhere(
          (e) => e.name == json['approach'],
          orElse: () => InterpretiveApproach.other,
        ),
        constitutionalPhilosophy:
            (json['constitutionalPhilosophy'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        doctrinalReasoning:
            (json['doctrinalReasoning'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        reasoningTools: (json['reasoningTools'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        evidence: IntelligenceEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentReasoning &&
          summary == other.summary &&
          approach == other.approach;

  @override
  int get hashCode => Object.hash(summary, approach);
}

// ---------------------------------------------------------------------------
// F. JudgmentOutcome
// ---------------------------------------------------------------------------

/// Disposition and operative result of the judgment.
@immutable
class JudgmentOutcome {
  final OutcomeDisposition disposition;
  final List<String> reliefGranted;
  final List<String> reliefDenied;
  final String operativeResult;
  final String majorityOutcome;
  final String? minorityOutcome;
  final IntelligenceEvidence evidence;

  const JudgmentOutcome({
    this.disposition = OutcomeDisposition.other,
    this.reliefGranted = const [],
    this.reliefDenied = const [],
    this.operativeResult = '',
    this.majorityOutcome = '',
    this.minorityOutcome,
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'disposition': disposition.name,
        'reliefGranted': reliefGranted,
        'reliefDenied': reliefDenied,
        'operativeResult': operativeResult,
        'majorityOutcome': majorityOutcome,
        if (minorityOutcome != null) 'minorityOutcome': minorityOutcome,
        'evidence': evidence.toJson(),
      };

  factory JudgmentOutcome.fromJson(Map<String, dynamic> json) =>
      JudgmentOutcome(
        disposition: OutcomeDisposition.values.firstWhere(
          (e) => e.name == json['disposition'],
          orElse: () => OutcomeDisposition.other,
        ),
        reliefGranted: (json['reliefGranted'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        reliefDenied: (json['reliefDenied'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        operativeResult: json['operativeResult'] as String? ?? '',
        majorityOutcome: json['majorityOutcome'] as String? ?? '',
        minorityOutcome: json['minorityOutcome'] as String?,
        evidence: IntelligenceEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentOutcome &&
          disposition == other.disposition &&
          operativeResult == other.operativeResult;

  @override
  int get hashCode => Object.hash(disposition, operativeResult);
}

// ---------------------------------------------------------------------------
// G. JudicialSignificance
// ---------------------------------------------------------------------------

/// Multi-dimensional significance of the judgment.
@immutable
class JudicialSignificance {
  final String constitutionalSignificance;
  final String legalSignificance;
  final String upscSignificance;
  final String historicalSignificance;

  /// 0-100 composite significance score derived from the recorded dimensions.
  final int significanceScore;

  const JudicialSignificance({
    this.constitutionalSignificance = '',
    this.legalSignificance = '',
    this.upscSignificance = '',
    this.historicalSignificance = '',
    this.significanceScore = 0,
  });

  Map<String, dynamic> toJson() => {
        'constitutionalSignificance': constitutionalSignificance,
        'legalSignificance': legalSignificance,
        'upscSignificance': upscSignificance,
        'historicalSignificance': historicalSignificance,
        'significanceScore': significanceScore,
      };

  factory JudicialSignificance.fromJson(Map<String, dynamic> json) =>
      JudicialSignificance(
        constitutionalSignificance:
            json['constitutionalSignificance'] as String? ?? '',
        legalSignificance: json['legalSignificance'] as String? ?? '',
        upscSignificance: json['upscSignificance'] as String? ?? '',
        historicalSignificance:
            json['historicalSignificance'] as String? ?? '',
        significanceScore: json['significanceScore'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudicialSignificance &&
          constitutionalSignificance == other.constitutionalSignificance &&
          significanceScore == other.significanceScore;

  @override
  int get hashCode =>
      Object.hash(constitutionalSignificance, significanceScore);
}

// ---------------------------------------------------------------------------
// H. UpscJudgmentIntelligence
// ---------------------------------------------------------------------------

/// UPSC / civil-services preparation intelligence for the judgment.
///
/// All content here is editorial analysis grounded in verified judicial facts;
/// it is never presented as a judicial fact itself.
@immutable
class UpscJudgmentIntelligence {
  final List<String> prelimsFacts;
  final List<String> prelimsTraps;
  final List<String> mainsThemes;
  final List<String> mainsArguments;
  final List<String> mainsCounterarguments;
  final List<String> answerKeywords;
  final List<String> essayThemes;
  final List<String> interviewAreas;
  final List<String> answerEnrichmentPoints;
  final List<String> contemporaryRelevance;
  final List<String> likelyInterviewQuestions;
  final List<String> conclusionIdeas;
  final List<UpscSyllabusArea> relatedSyllabusAreas;

  const UpscJudgmentIntelligence({
    this.prelimsFacts = const [],
    this.prelimsTraps = const [],
    this.mainsThemes = const [],
    this.mainsArguments = const [],
    this.mainsCounterarguments = const [],
    this.answerKeywords = const [],
    this.essayThemes = const [],
    this.interviewAreas = const [],
    this.answerEnrichmentPoints = const [],
    this.contemporaryRelevance = const [],
    this.likelyInterviewQuestions = const [],
    this.conclusionIdeas = const [],
    this.relatedSyllabusAreas = const [],
  });

  Map<String, dynamic> toJson() => {
        'prelimsFacts': prelimsFacts,
        'prelimsTraps': prelimsTraps,
        'mainsThemes': mainsThemes,
        'mainsArguments': mainsArguments,
        'mainsCounterarguments': mainsCounterarguments,
        'answerKeywords': answerKeywords,
        'essayThemes': essayThemes,
        'interviewAreas': interviewAreas,
        'answerEnrichmentPoints': answerEnrichmentPoints,
        'contemporaryRelevance': contemporaryRelevance,
        'likelyInterviewQuestions': likelyInterviewQuestions,
        'conclusionIdeas': conclusionIdeas,
        'relatedSyllabusAreas':
            relatedSyllabusAreas.map((e) => e.name).toList(),
      };

  factory UpscJudgmentIntelligence.fromJson(Map<String, dynamic> json) =>
      UpscJudgmentIntelligence(
        prelimsFacts: (json['prelimsFacts'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        prelimsTraps: (json['prelimsTraps'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        mainsThemes: (json['mainsThemes'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        mainsArguments: (json['mainsArguments'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        mainsCounterarguments:
            (json['mainsCounterarguments'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        answerKeywords: (json['answerKeywords'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        essayThemes: (json['essayThemes'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        interviewAreas: (json['interviewAreas'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answerEnrichmentPoints:
            (json['answerEnrichmentPoints'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        contemporaryRelevance:
            (json['contemporaryRelevance'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        likelyInterviewQuestions:
            (json['likelyInterviewQuestions'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        conclusionIdeas:
            (json['conclusionIdeas'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        relatedSyllabusAreas:
            (json['relatedSyllabusAreas'] as List<dynamic>? ?? const [])
                .map((e) => UpscSyllabusArea.values.firstWhere(
                      (a) => a.name == e,
                      orElse: () => UpscSyllabusArea.gs2,
                    ))
                .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpscJudgmentIntelligence &&
          _listEquals(prelimsFacts, other.prelimsFacts) &&
          _listEquals(prelimsTraps, other.prelimsTraps) &&
          _listEquals(mainsThemes, other.mainsThemes) &&
          _listEquals(mainsArguments, other.mainsArguments);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(prelimsFacts),
        Object.hashAll(prelimsTraps),
        Object.hashAll(mainsThemes),
        Object.hashAll(mainsArguments),
      );
}

// ---------------------------------------------------------------------------
// I. JudgmentTimelineEvent
// ---------------------------------------------------------------------------

/// A dated / dated-by-year event in the judgment's timeline.
@immutable
class JudgmentTimelineEvent {
  final int? year;
  final String? date;
  final String event;
  final String significance;
  final IntelligenceEvidence evidence;

  const JudgmentTimelineEvent({
    this.year,
    this.date,
    required this.event,
    this.significance = '',
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        if (year != null) 'year': year,
        if (date != null) 'date': date,
        'event': event,
        'significance': significance,
        'evidence': evidence.toJson(),
      };

  factory JudgmentTimelineEvent.fromJson(Map<String, dynamic> json) =>
      JudgmentTimelineEvent(
        year: json['year'] as int?,
        date: json['date'] as String?,
        event: json['event'] as String? ?? '',
        significance: json['significance'] as String? ?? '',
        evidence: IntelligenceEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentTimelineEvent &&
          year == other.year &&
          event == other.event;

  @override
  int get hashCode => Object.hash(year, event);
}

// ---------------------------------------------------------------------------
// JudgmentIntelligence aggregate
// ---------------------------------------------------------------------------

/// Immutable aggregate holding the full Judgment Intelligence for one case.
///
/// `caseId` ties the intelligence back to the `CaseKnowledgeObject`. Every
/// component is optional so a case with limited verified information remains a
/// valid object; unpopulated components are represented explicitly as absent
/// rather than fabricated.
@immutable
class JudgmentIntelligence {
  final String caseId;
  final JudgmentBench? bench;
  final List<JudgmentIssue> issues;
  final List<JudgmentHolding> holdings;
  final List<JudgmentRatio> ratios;
  final JudgmentReasoning? reasoning;
  final JudgmentOutcome? outcome;
  final JudicialSignificance? judicialSignificance;
  final UpscJudgmentIntelligence? upscIntelligence;
  final List<JudgmentTimelineEvent> timeline;

  const JudgmentIntelligence({
    required this.caseId,
    this.bench,
    this.issues = const [],
    this.holdings = const [],
    this.ratios = const [],
    this.reasoning,
    this.outcome,
    this.judicialSignificance,
    this.upscIntelligence,
    this.timeline = const [],
  });

  /// True when every core intelligence layer is populated.
  bool get isComplete =>
      bench != null &&
      issues.isNotEmpty &&
      holdings.isNotEmpty &&
      ratios.isNotEmpty &&
      reasoning != null &&
      outcome != null &&
      judicialSignificance != null &&
      upscIntelligence != null;

  /// Number of populated primary layers (0-8).
  int get populatedLayers =>
      (bench != null ? 1 : 0) +
      (issues.isNotEmpty ? 1 : 0) +
      (holdings.isNotEmpty ? 1 : 0) +
      (ratios.isNotEmpty ? 1 : 0) +
      (reasoning != null ? 1 : 0) +
      (outcome != null ? 1 : 0) +
      (judicialSignificance != null ? 1 : 0) +
      (upscIntelligence != null ? 1 : 0);

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        if (bench != null) 'bench': bench!.toJson(),
        'issues': issues.map((e) => e.toJson()).toList(),
        'holdings': holdings.map((e) => e.toJson()).toList(),
        'ratios': ratios.map((e) => e.toJson()).toList(),
        if (reasoning != null) 'reasoning': reasoning!.toJson(),
        if (outcome != null) 'outcome': outcome!.toJson(),
        if (judicialSignificance != null)
          'judicialSignificance': judicialSignificance!.toJson(),
        if (upscIntelligence != null)
          'upscIntelligence': upscIntelligence!.toJson(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
      };

  factory JudgmentIntelligence.fromJson(Map<String, dynamic> json) =>
      JudgmentIntelligence(
        caseId: json['caseId'] as String? ?? '',
        bench: json['bench'] == null
            ? null
            : JudgmentBench.fromJson(json['bench'] as Map<String, dynamic>),
        issues: (json['issues'] as List<dynamic>? ?? const [])
            .map((e) => JudgmentIssue.fromJson(e as Map<String, dynamic>))
            .toList(),
        holdings: (json['holdings'] as List<dynamic>? ?? const [])
            .map((e) => JudgmentHolding.fromJson(e as Map<String, dynamic>))
            .toList(),
        ratios: (json['ratios'] as List<dynamic>? ?? const [])
            .map((e) => JudgmentRatio.fromJson(e as Map<String, dynamic>))
            .toList(),
        reasoning: json['reasoning'] == null
            ? null
            : JudgmentReasoning.fromJson(
                json['reasoning'] as Map<String, dynamic>),
        outcome: json['outcome'] == null
            ? null
            : JudgmentOutcome.fromJson(json['outcome'] as Map<String, dynamic>),
        judicialSignificance: json['judicialSignificance'] == null
            ? null
            : JudicialSignificance.fromJson(
                json['judicialSignificance'] as Map<String, dynamic>),
        upscIntelligence: json['upscIntelligence'] == null
            ? null
            : UpscJudgmentIntelligence.fromJson(
                json['upscIntelligence'] as Map<String, dynamic>),
        timeline: (json['timeline'] as List<dynamic>? ?? const [])
            .map(
                (e) => JudgmentTimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  JudgmentIntelligence copyWith({
    String? caseId,
    JudgmentBench? bench,
    List<JudgmentIssue>? issues,
    List<JudgmentHolding>? holdings,
    List<JudgmentRatio>? ratios,
    JudgmentReasoning? reasoning,
    JudgmentOutcome? outcome,
    JudicialSignificance? judicialSignificance,
    UpscJudgmentIntelligence? upscIntelligence,
    List<JudgmentTimelineEvent>? timeline,
  }) =>
      JudgmentIntelligence(
        caseId: caseId ?? this.caseId,
        bench: bench ?? this.bench,
        issues: issues ?? this.issues,
        holdings: holdings ?? this.holdings,
        ratios: ratios ?? this.ratios,
        reasoning: reasoning ?? this.reasoning,
        outcome: outcome ?? this.outcome,
        judicialSignificance: judicialSignificance ?? this.judicialSignificance,
        upscIntelligence: upscIntelligence ?? this.upscIntelligence,
        timeline: timeline ?? this.timeline,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JudgmentIntelligence &&
          caseId == other.caseId &&
          bench == other.bench &&
          _listEquals(issues, other.issues) &&
          _listEquals(holdings, other.holdings) &&
          _listEquals(ratios, other.ratios) &&
          reasoning == other.reasoning &&
          outcome == other.outcome &&
          judicialSignificance == other.judicialSignificance &&
          upscIntelligence == other.upscIntelligence;

  @override
  int get hashCode => Object.hash(
        caseId,
        bench,
        Object.hashAll(holdings),
        reasoning,
        outcome,
      );
}

bool _listEquals(List<Object> a, List<Object> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
