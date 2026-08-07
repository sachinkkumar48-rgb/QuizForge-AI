library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';
import 'report_corpus_indices.dart';
import 'report_corpus_reports.dart';
import 'report_corpus_reports_global.dart';
import 'report_corpus_surveys.dart';
import 'report_indicator_corpus.dart';

/// Phase-I Seed Corpus for the GARUDA National Reports & Indices Library.
/// Combines Indian official reports, international/multilateral reports,
/// national & global indices, official surveys and first-class indicators.
class ReportSeedCorpus {
  ReportSeedCorpus._();

  static final List<ReportKnowledgeObject> phase1Reports = [
    ...ReportCorpusIndian.reports,
    ...ReportCorpusGlobal.reports,
  ];

  static final List<IndexKnowledgeObject> phase1Indices =
      ReportCorpusIndices.indices;

  static final List<SurveyKnowledgeObject> phase1Surveys =
      ReportCorpusSurveys.surveys;

  static final List<IndicatorKnowledgeObject> phase1Indicators =
      ReportCorpusIndicators.indicators;

  /// Total expected Phase-I Reports (excluding indices & surveys).
  static const int expectedReportCorpus = 18;

  /// Total expected Phase-I Indices.
  static const int expectedIndexCorpus = 9;

  /// Total expected Phase-I Surveys.
  static const int expectedSurveyCorpus = 4;

  /// Total expected Phase-I Indicators.
  static const int expectedIndicatorCorpus = 15;
}
