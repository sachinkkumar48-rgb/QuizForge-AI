/// Judgment Intelligence analytics (TITAN-KO-015.0 P4).
///
/// All metrics are derived from the actual corpus data — no hard-coded
/// expectations. Coverage rates are computed against the number of cases
/// carrying intelligence.
library;

import '../../domain/entities/case_knowledge_object.dart';
import '../domain/intelligence_enums.dart';
import '../domain/judgment_intelligence.dart';

/// Analytics report over the Judgment Intelligence of a corpus.
class JudgmentIntelligenceAnalyticsReport {
  final int totalCases;
  final int missingIntelligenceCount;

  final int casesWithBench;
  final int casesWithVerifiedBench;
  final int casesWithHoldings;
  final int casesWithVerifiedHoldings;
  final int casesWithRatio;
  final int casesWithReasoning;
  final int casesWithOutcome;
  final int casesWithSignificance;
  final int casesWithUpscIntelligence;
  final int casesWithTimeline;

  final Map<IssueCategory, int> issueCategoryDistribution;
  final Map<String, int> articleFrequency;
  final Map<int, int> significanceScoreDistribution;

  final int prelimsCoverageCount;
  final int mainsCoverageCount;
  final int interviewCoverageCount;

  /// Proportion of intelligence-bearing components that carry a registered,
  /// verified evidence reference.
  final double evidenceCoverage;

  /// Average share of the 8 intelligence layers populated.
  final double completenessIndex;

  const JudgmentIntelligenceAnalyticsReport({
    required this.totalCases,
    required this.missingIntelligenceCount,
    required this.casesWithBench,
    required this.casesWithVerifiedBench,
    required this.casesWithHoldings,
    required this.casesWithVerifiedHoldings,
    required this.casesWithRatio,
    required this.casesWithReasoning,
    required this.casesWithOutcome,
    required this.casesWithSignificance,
    required this.casesWithUpscIntelligence,
    required this.casesWithTimeline,
    required this.issueCategoryDistribution,
    required this.articleFrequency,
    required this.significanceScoreDistribution,
    required this.prelimsCoverageCount,
    required this.mainsCoverageCount,
    required this.interviewCoverageCount,
    required this.evidenceCoverage,
    required this.completenessIndex,
  });

  double _rate(int count) => totalCases == 0 ? 0.0 : count / totalCases;

  double get benchCoverageRate => _rate(casesWithBench);
  double get holdingCoverageRate => _rate(casesWithHoldings);
  double get ratioCoverageRate => _rate(casesWithRatio);
  double get reasoningCoverageRate => _rate(casesWithReasoning);
  double get outcomeCoverageRate => _rate(casesWithOutcome);
  double get upscCoverageRate => _rate(casesWithUpscIntelligence);
  double get prelimsCoverageRate => _rate(prelimsCoverageCount);
  double get mainsCoverageRate => _rate(mainsCoverageCount);
  double get interviewCoverageRate => _rate(interviewCoverageCount);

  Map<String, dynamic> toJson() => {
        'totalCases': totalCases,
        'missingIntelligenceCount': missingIntelligenceCount,
        'casesWithBench': casesWithBench,
        'casesWithVerifiedBench': casesWithVerifiedBench,
        'casesWithHoldings': casesWithHoldings,
        'casesWithVerifiedHoldings': casesWithVerifiedHoldings,
        'casesWithRatio': casesWithRatio,
        'casesWithReasoning': casesWithReasoning,
        'casesWithOutcome': casesWithOutcome,
        'casesWithSignificance': casesWithSignificance,
        'casesWithUpscIntelligence': casesWithUpscIntelligence,
        'casesWithTimeline': casesWithTimeline,
        'issueCategoryDistribution': {
          for (final e in issueCategoryDistribution.entries)
            e.key.name: e.value,
        },
        'articleFrequency': articleFrequency,
        'significanceScoreDistribution': {
          for (final e in significanceScoreDistribution.entries)
            e.key.toString(): e.value,
        },
        'prelimsCoverageCount': prelimsCoverageCount,
        'mainsCoverageCount': mainsCoverageCount,
        'interviewCoverageCount': interviewCoverageCount,
        'evidenceCoverage': evidenceCoverage,
        'completenessIndex': completenessIndex,
        'benchCoverageRate': benchCoverageRate,
        'holdingCoverageRate': holdingCoverageRate,
        'ratioCoverageRate': ratioCoverageRate,
        'reasoningCoverageRate': reasoningCoverageRate,
        'outcomeCoverageRate': outcomeCoverageRate,
        'upscCoverageRate': upscCoverageRate,
        'prelimsCoverageRate': prelimsCoverageRate,
        'mainsCoverageRate': mainsCoverageRate,
        'interviewCoverageRate': interviewCoverageRate,
      };
}

/// Computes Judgment Intelligence analytics over a corpus.
class JudgmentIntelligenceAnalytics {
  static JudgmentIntelligenceAnalyticsReport analyze(
      Iterable<CaseKnowledgeObject> cases) {
    final all = cases.toList();
    final total = all.length;
    var missing = 0;

    var bench = 0, verifiedBench = 0;
    var holdings = 0, verifiedHoldings = 0;
    var ratio = 0, reasoning = 0, outcome = 0, significance = 0;
    var upsc = 0, timeline = 0, prelims = 0, mains = 0, interview = 0;

    final categoryDist = <IssueCategory, int>{};
    final articleFreq = <String, int>{};
    final sigDist = <int, int>{};
    var verifiedComponents = 0;
    var totalComponents = 0;
    var layersSum = 0;

    for (final c in all) {
      final intel = c.judgmentIntelligence;
      if (intel == null) {
        missing++;
        continue;
      }
      layersSum += intel.populatedLayers;

      if (intel.bench != null) {
        bench++;
        if (intel.bench!.isEstablished) verifiedBench++;
        verifiedComponents += _evidenceCount(intel.bench!.evidence);
        totalComponents++;
      }
      if (intel.holdings.isNotEmpty) {
        holdings++;
        if (intel.holdings.every((h) => h.confidence == IntelligenceConfidence.verified)) {
          verifiedHoldings++;
        }
        for (final h in intel.holdings) {
          verifiedComponents += _evidenceCount(h.evidence);
          totalComponents++;
        }
      }
      if (intel.ratios.isNotEmpty) {
        ratio++;
        for (final r in intel.ratios) {
          verifiedComponents += _evidenceCount(r.evidence);
          totalComponents++;
        }
      }
      if (intel.reasoning != null) {
        reasoning++;
        verifiedComponents += _evidenceCount(intel.reasoning!.evidence);
        totalComponents++;
      }
      if (intel.outcome != null) {
        outcome++;
        verifiedComponents += _evidenceCount(intel.outcome!.evidence);
        totalComponents++;
      }
      if (intel.judicialSignificance != null) {
        significance++;
        sigDist[intel.judicialSignificance!.significanceScore] =
            (sigDist[intel.judicialSignificance!.significanceScore] ?? 0) + 1;
      }
      final u = intel.upscIntelligence;
      if (u != null) {
        upsc++;
        if (u.prelimsFacts.isNotEmpty) prelims++;
        if (u.mainsThemes.isNotEmpty) mains++;
        if (u.interviewAreas.isNotEmpty) interview++;
      }
      if (intel.timeline.isNotEmpty) {
        timeline++;
        for (final t in intel.timeline) {
          verifiedComponents += _evidenceCount(t.evidence);
          totalComponents++;
        }
      }
      for (final i in intel.issues) {
        categoryDist[i.category] = (categoryDist[i.category] ?? 0) + 1;
        for (final a in i.relatedArticles) {
          articleFreq[a] = (articleFreq[a] ?? 0) + 1;
        }
      }
    }

    return JudgmentIntelligenceAnalyticsReport(
      totalCases: total,
      missingIntelligenceCount: missing,
      casesWithBench: bench,
      casesWithVerifiedBench: verifiedBench,
      casesWithHoldings: holdings,
      casesWithVerifiedHoldings: verifiedHoldings,
      casesWithRatio: ratio,
      casesWithReasoning: reasoning,
      casesWithOutcome: outcome,
      casesWithSignificance: significance,
      casesWithUpscIntelligence: upsc,
      casesWithTimeline: timeline,
      issueCategoryDistribution: categoryDist,
      articleFrequency: _sortedFrequency(articleFreq),
      significanceScoreDistribution: sigDist,
      prelimsCoverageCount: prelims,
      mainsCoverageCount: mains,
      interviewCoverageCount: interview,
      evidenceCoverage:
          totalComponents == 0 ? 0.0 : verifiedComponents / totalComponents,
      completenessIndex: total == 0 ? 0.0 : layersSum / (total * 8),
    );
  }

  static int _evidenceCount(IntelligenceEvidence e) =>
      e.verified && e.evidenceId.isNotEmpty ? 1 : 0;

  static Map<String, int> _sortedFrequency(Map<String, int> freq) {
    final entries = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }
}
