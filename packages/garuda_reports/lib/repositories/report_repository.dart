library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_enums.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';
import '../search/report_search_engine.dart';

/// Corpus Coverage Metrics Report for the Reports & Indices Library.
class ReportCorpusReport {
  final int totalExpectedReports;
  final int totalImportedReports;
  final double reportCoveragePercentage;
  final int totalExpectedIndices;
  final int totalImportedIndices;
  final double indexCoveragePercentage;
  final int totalExpectedSurveys;
  final int totalImportedSurveys;
  final double surveyCoveragePercentage;
  final int totalRecommendations;
  final int totalIndicators;
  final int totalChapters;
  final int totalStatistics;
  final int totalPyqLinks;
  final int totalCurrentAffairsLinks;
  final Map<ReportCategory, int> categoryCounts;

  const ReportCorpusReport({
    required this.totalExpectedReports,
    required this.totalImportedReports,
    required this.reportCoveragePercentage,
    required this.totalExpectedIndices,
    required this.totalImportedIndices,
    required this.indexCoveragePercentage,
    required this.totalExpectedSurveys,
    required this.totalImportedSurveys,
    required this.surveyCoveragePercentage,
    required this.totalRecommendations,
    required this.totalIndicators,
    required this.totalChapters,
    required this.totalStatistics,
    required this.totalPyqLinks,
    required this.totalCurrentAffairsLinks,
    required this.categoryCounts,
  });
}

/// Abstract repository interface for Reports, Indices, Surveys and Indicators.
abstract class ReportRepository {
  // Reports
  Future<void> saveReport(ReportKnowledgeObject object);
  Future<ReportKnowledgeObject?> getReportById(String id);
  Future<List<ReportKnowledgeObject>> getAllReports();
  Future<List<ReportKnowledgeObject>> getReportsByCategory(
      ReportCategory category);
  Future<List<ReportKnowledgeObject>> getReportsByPublisher(
      String organisation);
  Future<List<ReportKnowledgeObject>> getReportsByMinistry(String ministry);
  Future<List<ReportKnowledgeObject>> getReportsByYear(int year);

  // Indices
  Future<void> saveIndex(IndexKnowledgeObject object);
  Future<IndexKnowledgeObject?> getIndexById(String id);
  Future<List<IndexKnowledgeObject>> getAllIndices();

  // Surveys
  Future<void> saveSurvey(SurveyKnowledgeObject object);
  Future<SurveyKnowledgeObject?> getSurveyById(String id);
  Future<List<SurveyKnowledgeObject>> getAllSurveys();

  // Indicators
  Future<void> saveIndicator(IndicatorKnowledgeObject object);
  Future<IndicatorKnowledgeObject?> getIndicatorById(String id);
  Future<List<IndicatorKnowledgeObject>> getAllIndicators();

  // Search & Coverage
  Future<List<ReportKnowledgeObject>> searchReports(ReportSearchQuery query);
  Future<List<ReportKnowledgeObject>> getRelatedReports(String reportId,
      {int maxResults = 10});
  Future<ReportCorpusReport> generateCorpusReport();
}
