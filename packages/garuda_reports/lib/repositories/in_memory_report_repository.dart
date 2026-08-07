library;

import '../data/report_seed_corpus.dart';
import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_enums.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';
import '../search/report_search_engine.dart';
import 'report_repository.dart';

/// In-memory implementation of ReportRepository pre-seeded with Phase-I corpus.
class InMemoryReportRepository implements ReportRepository {
  final Map<String, ReportKnowledgeObject> _reports = {};
  final Map<String, IndexKnowledgeObject> _indices = {};
  final Map<String, SurveyKnowledgeObject> _surveys = {};
  final Map<String, IndicatorKnowledgeObject> _indicators = {};

  InMemoryReportRepository({bool seedDefaultCorpus = true}) {
    if (seedDefaultCorpus) {
      for (final report in ReportSeedCorpus.phase1Reports) {
        _reports[report.id] = report;
      }
      for (final index in ReportSeedCorpus.phase1Indices) {
        _indices[index.id] = index;
      }
      for (final survey in ReportSeedCorpus.phase1Surveys) {
        _surveys[survey.id] = survey;
      }
      for (final indicator in ReportSeedCorpus.phase1Indicators) {
        _indicators[indicator.id] = indicator;
      }
    }
  }

  // ---- Reports ----

  @override
  Future<void> saveReport(ReportKnowledgeObject object) async {
    _reports[object.id] = object;
  }

  @override
  Future<ReportKnowledgeObject?> getReportById(String id) async {
    return _reports[id];
  }

  @override
  Future<List<ReportKnowledgeObject>> getAllReports() async {
    return List.unmodifiable(_reports.values.toList());
  }

  @override
  Future<List<ReportKnowledgeObject>> getReportsByCategory(
      ReportCategory category) async {
    return _reports.values.where((r) => r.category == category).toList();
  }

  @override
  Future<List<ReportKnowledgeObject>> getReportsByPublisher(
      String organisation) async {
    final lower = organisation.toLowerCase().trim();
    return _reports.values
        .where((r) => r.publishingOrganisation.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<List<ReportKnowledgeObject>> getReportsByMinistry(
      String ministry) async {
    final lower = ministry.toLowerCase().trim();
    return _reports.values
        .where((r) =>
            r.publishingMinistry.toLowerCase().contains(lower) ||
            r.publishingOrganisation.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<List<ReportKnowledgeObject>> getReportsByYear(int year) async {
    return _reports.values.where((r) => r.publicationYear == year).toList();
  }

  // ---- Indices ----

  @override
  Future<void> saveIndex(IndexKnowledgeObject object) async {
    _indices[object.id] = object;
  }

  @override
  Future<IndexKnowledgeObject?> getIndexById(String id) async {
    return _indices[id];
  }

  @override
  Future<List<IndexKnowledgeObject>> getAllIndices() async {
    return List.unmodifiable(_indices.values.toList());
  }

  // ---- Surveys ----

  @override
  Future<void> saveSurvey(SurveyKnowledgeObject object) async {
    _surveys[object.id] = object;
  }

  @override
  Future<SurveyKnowledgeObject?> getSurveyById(String id) async {
    return _surveys[id];
  }

  @override
  Future<List<SurveyKnowledgeObject>> getAllSurveys() async {
    return List.unmodifiable(_surveys.values.toList());
  }

  // ---- Indicators ----

  @override
  Future<IndicatorKnowledgeObject?> getIndicatorById(String id) async {
    return _indicators[id];
  }

  @override
  Future<List<IndicatorKnowledgeObject>> getAllIndicators() async {
    return List.unmodifiable(_indicators.values.toList());
  }

  // ---- Search & Coverage ----

  @override
  Future<List<ReportKnowledgeObject>> searchReports(
      ReportSearchQuery query) async {
    return ReportSearchEngine.search(
        reports: _reports.values.toList(), query: query);
  }

  @override
  Future<ReportCorpusReport> generateCorpusReport() async {
    final reports = _reports.values.toList();
    final indices = _indices.values.toList();
    final surveys = _surveys.values.toList();

    final categoryCounts = <ReportCategory, int>{};

    int totalRecs = 0;
    int totalChapters = 0;
    int totalStats = 0;
    int totalPyqs = 0;
    int totalCa = 0;

    for (final r in reports) {
      categoryCounts[r.category] = (categoryCounts[r.category] ?? 0) + 1;
      totalRecs += r.recommendations.length;
      totalChapters += r.chapters.length;
      totalStats += r.importantStatistics.length;
      totalPyqs += r.relatedPyqIds.length;
      totalCa += r.relatedCurrentAffairsIds.length;

      for (final chapter in r.chapters) {
        totalRecs += chapter.recommendations.length;
        totalStats += chapter.statistics.length;
        totalPyqs += chapter.relatedPyqIds.length;
        totalCa += chapter.relatedCurrentAffairsIds.length;
      }
    }

    for (final idx in indices) {
      totalPyqs += idx.relatedPyqIds.length;
      totalCa += idx.relatedCurrentAffairsIds.length;
    }

    for (final s in surveys) {
      totalStats += s.importantStatistics.length;
      totalPyqs += s.relatedPyqIds.length;
      totalCa += s.relatedCurrentAffairsIds.length;
    }

    double coverage(int imported, int expected) => expected > 0
        ? double.parse(((imported / expected) * 100).toStringAsFixed(1))
        : 100.0;

    return ReportCorpusReport(
      totalExpectedReports: ReportSeedCorpus.expectedReportCorpus,
      totalImportedReports: reports.length,
      reportCoveragePercentage:
          coverage(reports.length, ReportSeedCorpus.expectedReportCorpus),
      totalExpectedIndices: ReportSeedCorpus.expectedIndexCorpus,
      totalImportedIndices: indices.length,
      indexCoveragePercentage:
          coverage(indices.length, ReportSeedCorpus.expectedIndexCorpus),
      totalExpectedSurveys: ReportSeedCorpus.expectedSurveyCorpus,
      totalImportedSurveys: surveys.length,
      surveyCoveragePercentage:
          coverage(surveys.length, ReportSeedCorpus.expectedSurveyCorpus),
      totalRecommendations: totalRecs,
      totalIndicators: _indicators.length,
      totalChapters: totalChapters,
      totalStatistics: totalStats,
      totalPyqLinks: totalPyqs,
      totalCurrentAffairsLinks: totalCa,
      categoryCounts: Map.unmodifiable(categoryCounts),
    );
  }

  void clear() {
    _reports.clear();
    _indices.clear();
    _surveys.clear();
    _indicators.clear();
  }
}
