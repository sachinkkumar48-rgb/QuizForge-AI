library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';
import 'report_corpus_indices.dart';
import 'report_corpus_reports.dart';
import 'report_corpus_reports_global.dart';
import 'report_corpus_surveys.dart';
import 'report_corpus_support.dart';
import 'report_indicator_corpus.dart';

/// Phase-I Seed Corpus for the GARUDA National Reports & Indices Library.
/// Combines Indian official reports, international/multilateral reports,
/// national & global indices, official surveys and first-class indicators.
///
/// Every seeded record is enriched through [ReportCorpusSupport] so that each
/// record carries `lastVerifiedDate`, `evidenceVerified` editorial status and
/// resolvable evidence against [ReportOfficialSources].
class ReportSeedCorpus {
  ReportSeedCorpus._();

  static final List<ReportKnowledgeObject> phase1Reports = [
    ...ReportCorpusIndian.reports.map(ReportCorpusSupport.enrichReport),
    ...ReportCorpusGlobal.reports.map(ReportCorpusSupport.enrichReport),
  ];

  static final List<IndexKnowledgeObject> phase1Indices =
      ReportCorpusIndices.indices
          .map(ReportCorpusSupport.enrichIndex)
          .toList();

  static final List<SurveyKnowledgeObject> phase1Surveys =
      ReportCorpusSurveys.surveys
          .map(ReportCorpusSupport.enrichSurvey)
          .toList();

  static final List<IndicatorKnowledgeObject> phase1Indicators =
      ReportCorpusIndicators.indicators
          .map(ReportCorpusSupport.enrichIndicator)
          .toList();

  /// Total expected Phase-I Reports (excluding indices & surveys).
  static const int expectedReportCorpus = 31;

  /// Total expected Phase-I Indices.
  static const int expectedIndexCorpus = 9;

  /// Total expected Phase-I Surveys.
  static const int expectedSurveyCorpus = 4;

  /// Total expected Phase-I Indicators.
  static const int expectedIndicatorCorpus = 25;

  /// Overall evidence coverage across the Phase-I corpus (0..1).
  static double get corpusEvidenceCoverage {
    final all = <dynamic>[
      ...phase1Reports,
      ...phase1Indices,
      ...phase1Surveys,
      ...phase1Indicators,
    ];
    return ReportCorpusSupport.evidenceCoverage(all);
  }
}
