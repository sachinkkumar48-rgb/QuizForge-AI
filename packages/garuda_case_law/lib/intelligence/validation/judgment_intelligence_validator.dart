/// Evidence-gated validation for Judgment Intelligence (TITAN-KO-015.0 P4).
///
/// Validation is deliberately evidence-gated: a component may only claim
/// `verified` confidence when its evidence reference resolves against the
/// official-source registry. Uncertain information is never auto-marked as
/// verified — it must be surfaced as a limitation instead.
library;

import 'package:meta/meta.dart';

import '../../data/case_official_sources.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../domain/intelligence_enums.dart';
import '../domain/judgment_intelligence.dart';

/// Severity of an intelligence validation issue.
enum IntelligenceIssueSeverity { error, warning }

@immutable
class IntelligenceValidationIssue {
  final String code;
  final String message;
  final String caseId;

  /// Layer of intelligence the issue concerns (e.g. 'bench', 'holding').
  final String layer;
  final IntelligenceIssueSeverity severity;

  const IntelligenceValidationIssue({
    required this.code,
    required this.message,
    required this.caseId,
    required this.layer,
    this.severity = IntelligenceIssueSeverity.error,
  });

  @override
  String toString() =>
      '[$code] ($caseId/$layer): $message (${severity.name})';
}

@immutable
class IntelligenceValidationResult {
  final bool isValid;
  final List<IntelligenceValidationIssue> issues;

  const IntelligenceValidationResult({
    required this.isValid,
    this.issues = const [],
  });

  factory IntelligenceValidationResult.success() =>
      const IntelligenceValidationResult(isValid: true);

  factory IntelligenceValidationResult.failure(
          List<IntelligenceValidationIssue> issues) =>
      IntelligenceValidationResult(isValid: false, issues: issues);

  List<IntelligenceValidationIssue> get errors =>
      issues.where((i) => i.severity == IntelligenceIssueSeverity.error).toList();

  List<IntelligenceValidationIssue> get warnings =>
      issues.where((i) => i.severity == IntelligenceIssueSeverity.warning).toList();
}

/// Validates the Judgment Intelligence attached to a case record.
class JudgmentIntelligenceValidator {
  /// Validates a case's judgment intelligence. Cases without intelligence are
  /// reported as a `MISSING_INTELLIGENCE` error (corpus integrity).
  static IntelligenceValidationResult validate(CaseKnowledgeObject c) {
    final intel = c.judgmentIntelligence;
    if (intel == null) {
      return IntelligenceValidationResult.failure([
        IntelligenceValidationIssue(
          code: 'MISSING_INTELLIGENCE',
          message: 'Case record carries no Judgment Intelligence.',
          caseId: c.caseId,
          layer: 'intelligence',
        ),
      ]);
    }
    final issues = <IntelligenceValidationIssue>[];
    _checkIntelligenceId(intel, c.caseId, issues);
    _checkRoundTrip(intel, c.caseId, issues);
    _checkHoldings(intel, c.caseId, issues);
    _checkRatios(intel, c.caseId, issues);
    _checkIssues(intel, c.caseId, issues);
    _checkBench(intel, c.caseId, issues);
    _checkOutcome(intel, c.caseId, issues);
    _checkSignificance(intel, c.caseId, issues);
    _checkEvidence(intel, c.caseId, issues);
    return issues.where((i) => i.severity == IntelligenceIssueSeverity.error).isEmpty
        ? IntelligenceValidationResult(isValid: true, issues: issues)
        : IntelligenceValidationResult(isValid: false, issues: issues);
  }

  /// Validates a repository of cases; returns aggregate issues.
  static IntelligenceValidationResult validateRepository(
      Iterable<CaseKnowledgeObject> cases) {
    final issues = <IntelligenceValidationIssue>[];
    var anyMissing = false;
    for (final c in cases) {
      final r = validate(c);
      issues.addAll(r.issues);
      if (!r.isValid) anyMissing = true;
    }
    return IntelligenceValidationResult(isValid: !anyMissing, issues: issues);
  }

  // -------------------------------------------------------------------------
  // Checks
  // -------------------------------------------------------------------------

  static void _checkIntelligenceId(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    if (intel.caseId.trim().isEmpty) {
      issues.add(IntelligenceValidationIssue(
        code: 'EMPTY_INTELLIGENCE_CASE_ID',
        message: 'JudgmentIntelligence caseId is empty.',
        caseId: caseId,
        layer: 'intelligence',
      ));
    } else if (intel.caseId != caseId) {
      issues.add(IntelligenceValidationIssue(
        code: 'INTELLIGENCE_CASE_ID_MISMATCH',
        message: 'Intelligence caseId "${intel.caseId}" does not match record "$caseId".',
        caseId: caseId,
        layer: 'intelligence',
      ));
    }
  }

  static void _checkRoundTrip(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    try {
      final restored = JudgmentIntelligence.fromJson(intel.toJson());
      if (restored != intel) {
        issues.add(IntelligenceValidationIssue(
          code: 'ROUND_TRIP_FAILURE',
          message: 'Intelligence toJson/fromJson round-trip does not preserve equality.',
          caseId: caseId,
          layer: 'intelligence',
        ));
      }
    } catch (_) {
      issues.add(IntelligenceValidationIssue(
        code: 'MALFORMED_INTELLIGENCE',
        message: 'Intelligence serialization threw during round-trip.',
        caseId: caseId,
        layer: 'intelligence',
      ));
    }
  }

  static void _checkHoldings(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    if (intel.holdings.isEmpty) {
      issues.add(IntelligenceValidationIssue(
        code: 'EMPTY_HOLDINGS',
        message: 'No holdings recorded for this judgment.',
        caseId: caseId,
        layer: 'holdings',
        severity: IntelligenceIssueSeverity.warning,
      ));
    }
    final seen = <String>{};
    for (final h in intel.holdings) {
      if (h.holdingId.isEmpty) {
        issues.add(IntelligenceValidationIssue(
          code: 'EMPTY_HOLDING_ID',
          message: 'A holding has an empty holdingId.',
          caseId: caseId,
          layer: 'holdings',
        ));
      } else if (!seen.add(h.holdingId)) {
        issues.add(IntelligenceValidationIssue(
          code: 'DUPLICATE_HOLDING_ID',
          message: 'Duplicate holdingId "${h.holdingId}".',
          caseId: caseId,
          layer: 'holdings',
        ));
      }
      if (h.holding.trim().isEmpty) {
        issues.add(IntelligenceValidationIssue(
          code: 'EMPTY_HOLDING_TEXT',
          message: 'Holding "${h.holdingId}" has empty text.',
          caseId: caseId,
          layer: 'holdings',
        ));
      }
    }
  }

  static void _checkRatios(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    if (intel.ratios.isEmpty) {
      issues.add(IntelligenceValidationIssue(
        code: 'EMPTY_RATIO',
        message: 'No ratio recorded for this judgment.',
        caseId: caseId,
        layer: 'ratios',
        severity: IntelligenceIssueSeverity.warning,
      ));
    }
    for (final r in intel.ratios) {
      if (r.ratio.trim().isEmpty) {
        issues.add(IntelligenceValidationIssue(
          code: 'EMPTY_RATIO_TEXT',
          message: 'A ratio has empty text.',
          caseId: caseId,
          layer: 'ratios',
        ));
      }
    }
  }

  static void _checkIssues(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    final seen = <String>{};
    for (final i in intel.issues) {
      if (i.issueId.isEmpty) {
        issues.add(IntelligenceValidationIssue(
          code: 'EMPTY_ISSUE_ID',
          message: 'An issue has an empty issueId.',
          caseId: caseId,
          layer: 'issues',
        ));
      } else if (!seen.add(i.issueId)) {
        issues.add(IntelligenceValidationIssue(
          code: 'DUPLICATE_ISSUE_ID',
          message: 'Duplicate issueId "${i.issueId}".',
          caseId: caseId,
          layer: 'issues',
        ));
      }
      if (i.issue.trim().isEmpty) {
        issues.add(IntelligenceValidationIssue(
          code: 'EMPTY_ISSUE_TEXT',
          message: 'Issue "${i.issueId}" has empty text.',
          caseId: caseId,
          layer: 'issues',
        ));
      }
      _checkArticleRefs(i.relatedArticles, caseId, 'issues', issues);
    }
  }

  static void _checkBench(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    final bench = intel.bench;
    if (bench == null) {
      issues.add(IntelligenceValidationIssue(
        code: 'MISSING_BENCH',
        message: 'No bench recorded.',
        caseId: caseId,
        layer: 'bench',
        severity: IntelligenceIssueSeverity.warning,
      ));
      return;
    }
    if (bench.benchSize < 0) {
      issues.add(IntelligenceValidationIssue(
        code: 'NEGATIVE_BENCH_SIZE',
        message: 'Bench size cannot be negative.',
        caseId: caseId,
        layer: 'bench',
      ));
    }
    if (!bench.isEstablished) {
      issues.add(IntelligenceValidationIssue(
        code: 'UNESTABLISHED_BENCH',
        message: 'Bench is present but neither size nor judge names are established.',
        caseId: caseId,
        layer: 'bench',
        severity: IntelligenceIssueSeverity.warning,
      ));
    }
  }

  static void _checkOutcome(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    final outcome = intel.outcome;
    if (outcome == null) {
      issues.add(IntelligenceValidationIssue(
        code: 'MISSING_OUTCOME',
        message: 'No outcome recorded.',
        caseId: caseId,
        layer: 'outcome',
        severity: IntelligenceIssueSeverity.warning,
      ));
      return;
    }
    // Inconsistent outcome: relief both granted and denied for the same point,
    // or an "allowed" disposition with empty operative result.
    if (outcome.disposition == OutcomeDisposition.allowed &&
        outcome.operativeResult.trim().isEmpty) {
      issues.add(IntelligenceValidationIssue(
        code: 'INCONSISTENT_OUTCOME',
        message: 'Disposition "allowed" recorded without an operative result.',
        caseId: caseId,
        layer: 'outcome',
      ));
    }
    if (outcome.disposition == OutcomeDisposition.dismissed &&
        outcome.reliefGranted.isNotEmpty) {
      issues.add(IntelligenceValidationIssue(
        code: 'INCONSISTENT_OUTCOME',
        message: 'Disposition "dismissed" records granted relief.',
        caseId: caseId,
        layer: 'outcome',
      ));
    }
  }

  static void _checkSignificance(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    final sig = intel.judicialSignificance;
    if (sig == null) {
      issues.add(IntelligenceValidationIssue(
        code: 'MISSING_SIGNIFICANCE',
        message: 'No judicial significance recorded.',
        caseId: caseId,
        layer: 'significance',
        severity: IntelligenceIssueSeverity.warning,
      ));
      return;
    }
    if (sig.significanceScore < 0 || sig.significanceScore > 100) {
      issues.add(IntelligenceValidationIssue(
        code: 'INVALID_SIGNIFICANCE_SCORE',
        message: 'Significance score ${sig.significanceScore} outside 0-100.',
        caseId: caseId,
        layer: 'significance',
      ));
    }
  }

  /// Evidence-gated: verified claims must resolve against the official
  /// evidence registry; editorial claims must be explicitly non-verified.
  static void _checkEvidence(
      JudgmentIntelligence intel, String caseId, List<IntelligenceValidationIssue> issues) {
    final components = <(String, String, IntelligenceEvidence)>[
      if (intel.bench != null)
        ('bench', 'bench', intel.bench!.evidence),
      for (final h in intel.holdings) ('holding', h.holdingId, h.evidence),
      for (final r in intel.ratios) ('ratio', r.ratio, r.evidence),
      if (intel.reasoning != null) ('reasoning', 'reasoning', intel.reasoning!.evidence),
      if (intel.outcome != null) ('outcome', 'outcome', intel.outcome!.evidence),
      for (final t in intel.timeline) ('timeline', t.event, t.evidence),
    ];
    for (final (layer, id, evidence) in components) {
      if (evidence.evidenceId.trim().isEmpty) {
        issues.add(IntelligenceValidationIssue(
          code: 'MISSING_EVIDENCE_REFERENCE',
          message: 'Component "$id" ($layer) has no evidence reference.',
          caseId: caseId,
          layer: layer,
        ));
      } else if (evidence.verified &&
          !CaseOfficialSources.isRegisteredEvidence(evidence.evidenceId)) {
        issues.add(IntelligenceValidationIssue(
          code: 'UNREGISTERED_VERIFIED_EVIDENCE',
          message: 'Component "$id" ($layer) claims verified status against '
              'unregistered evidence "${evidence.evidenceId}".',
          caseId: caseId,
          layer: layer,
        ));
      }
    }
    // Duplicate / empty UPSC content is a quality warning.
    final upsc = intel.upscIntelligence;
    if (upsc != null) {
      final all = [
        ...upsc.prelimsFacts,
        ...upsc.prelimsTraps,
        ...upsc.mainsThemes,
        ...upsc.essayThemes,
        ...upsc.interviewAreas,
      ];
      if (all.toSet().length != all.length) {
        issues.add(IntelligenceValidationIssue(
          code: 'DUPLICATE_UPSC_CONTENT',
          message: 'Duplicate UPSC intelligence content detected.',
          caseId: caseId,
          layer: 'upsc',
          severity: IntelligenceIssueSeverity.warning,
        ));
      }
    }
  }

  /// Validates constitutional Article references in the corpus's canonical
  /// 'Article N' (or bare number) format. Non-conforming references are
  /// flagged rather than silently accepted.
  static void _checkArticleRefs(List<String> articles, String caseId,
      String layer, List<IntelligenceValidationIssue> issues) {
    final pattern = RegExp(r'^(Article\s+)?\d{1,3}[A-Z]?(\([a-z]\))?$');
    for (final a in articles) {
      final cleaned = a
          .replaceAll('Art.', 'Article')
          .replaceAll('Article', 'Article')
          .trim();
      if (!pattern.hasMatch(cleaned)) {
        issues.add(IntelligenceValidationIssue(
          code: 'INVALID_ARTICLE_REFERENCE',
          message: 'Article reference "$a" is not in the canonical format '
              '(e.g. "Article 21").',
          caseId: caseId,
          layer: layer,
          severity: IntelligenceIssueSeverity.warning,
        ));
      }
    }
  }
}
