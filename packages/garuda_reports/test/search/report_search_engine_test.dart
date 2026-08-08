import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportSearchEngine Tests', () {
    late List<ReportKnowledgeObject> mockReports;
    late List<IndexKnowledgeObject> mockIndices;
    late List<SurveyKnowledgeObject> mockSurveys;
    late List<IndicatorKnowledgeObject> mockIndicators;

    setUp(() {
      mockReports = ReportSeedCorpus.phase1Reports;
      mockIndices = ReportSeedCorpus.phase1Indices;
      mockSurveys = ReportSeedCorpus.phase1Surveys;
      mockIndicators = ReportSeedCorpus.phase1Indicators;
    });

    test('should search by report title and short name', () {
      const query = ReportSearchQuery(title: 'Economic Survey');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.first.id, equals('rep_es_2024_25'));
    });

    test('should search by publisher and organisation', () {
      const query = ReportSearchQuery(publisher: 'Reserve Bank');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, hasLength(1));
      expect(results.first.id, equals('rep_rbi_ar_2023_24'));

      const orgQuery = ReportSearchQuery(organisation: 'Ministry of Finance');
      final orgResults =
          ReportSearchEngine.search(reports: mockReports, query: orgQuery);
      expect(orgResults, isNotEmpty);
      expect(orgResults.any((r) => r.id == 'rep_ub_2025_26'), isTrue);
    });

    test('should search by indicator', () {
      const query = ReportSearchQuery(indicator: 'CPI Inflation');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.any((r) => r.id == 'rep_es_2024_25'), isTrue);
      expect(results.any((r) => r.id == 'rep_rbi_ar_2023_24'), isTrue);
    });

    test('should search by recommendation keyword', () {
      const query = ReportSearchQuery(recommendation: 'deregulation');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.first.id, equals('rep_es_2024_25'));
    });

    test('should search by linked Constitution Article', () {
      const query = ReportSearchQuery(article: 'Article 280');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.any((r) => r.id == 'rep_fc15_2021_26'), isTrue);
      expect(results.any((r) => r.id == 'rep_fc16_2026'), isTrue);
    });

    test('should search by linked Act', () {
      const query = ReportSearchQuery(act: 'FRBM');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.any((r) => r.id == 'rep_es_2024_25'), isTrue);
      expect(results.any((r) => r.id == 'rep_ub_2025_26'), isTrue);
    });

    test('should search by linked Committee', () {
      const query = ReportSearchQuery(committee: 'comm_fc_15th_2017');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.any((r) => r.id == 'rep_fc15_2021_26'), isTrue);
    });

    test('should search by linked Scheme', () {
      const query = ReportSearchQuery(scheme: 'PM Dhan-Dhaanya');
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, isNotEmpty);
      expect(results.first.id, equals('rep_ub_2025_26'));
    });

    test('should search by year and keyword', () {
      const query = ReportSearchQuery(keyword: 'Forest', year: 2023);
      final results =
          ReportSearchEngine.search(reports: mockReports, query: query);

      expect(results, hasLength(1));
      expect(results.first.id, equals('rep_isfr_2023'));
    });

    test('should search indices and surveys', () {
      final idxResults = ReportSearchEngine.searchIndices(
        indices: mockIndices,
        query: const ReportSearchQuery(keyword: 'Hunger'),
      );
      expect(idxResults, isNotEmpty);
      expect(idxResults.any((i) => i.id == 'idx_ghi_2024'), isTrue);
      expect(idxResults.any((i) => i.id == 'idx_sdg_2023_24'), isTrue);

      final srvResults = ReportSearchEngine.searchSurveys(
        surveys: mockSurveys,
        query: const ReportSearchQuery(title: 'NFHS'),
      );
      expect(srvResults, isNotEmpty);
      expect(srvResults.first.id, equals('srv_nfhs5_2019_21'));
    });

    test('should search first-class indicators', () {
      final results = ReportSearchEngine.searchIndicators(
        indicators: mockIndicators,
        query: 'stunting',
      );

      expect(results, isNotEmpty);
      expect(results.first.id, equals('ind_stunting_35_5'));
    });

    test('should generate autocomplete and keyword suggestions', () {
      final suggestions = ReportSearchEngine.autocomplete(
        reports: mockReports,
        prefix: 'Econ',
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.contains('Economic Survey')), isTrue);

      final kwSuggestions = ReportSearchEngine.suggestKeywords(
        reports: mockReports,
        prefix: 'Forest',
      );
      expect(kwSuggestions, isNotEmpty);
      expect(kwSuggestions.any((s) => s.contains('Forest')), isTrue);
    });
  });
}
