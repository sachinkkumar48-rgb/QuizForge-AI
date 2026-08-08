import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportSearchEngine Phase-2 filters', () {
    late List<ReportKnowledgeObject> reports;

    setUp(() {
      reports = ReportSeedCorpus.phase1Reports;
    });

    test('should search by institution (publishing organisation)', () {
      const query = ReportSearchQuery(institution: 'Central Electricity Authority');
      final results =
          ReportSearchEngine.search(reports: reports, query: query);

      expect(results, isNotEmpty);
      expect(results.any((r) => r.id == 'rep_cea_2023_24'), isTrue);
    });

    test('should search by ministry', () {
      const query = ReportSearchQuery(ministry: 'Ministry of Health and Family Welfare');
      final results =
          ReportSearchEngine.search(reports: reports, query: query);

      expect(results, isNotEmpty);
      expect(results.any((r) => r.id == 'rep_nha_2020_21'), isTrue);
    });

    test('should not match institution when only ministry matches', () {
      const query = ReportSearchQuery(institution: 'Ministry of Finance');
      final results =
          ReportSearchEngine.search(reports: reports, query: query);

      expect(
        results.any((r) => r.publishingOrganisation == 'Ministry of Finance'),
        isFalse,
      );
    });
  });

  group('ReportSearchEngine related-report discovery', () {
    test('finds related reports for Economic Survey', () {
      final es = ReportSeedCorpus.phase1Reports
          .firstWhere((r) => r.id == 'rep_es_2024_25');
      final related = ReportSearchEngine.findRelatedReports(
        report: es,
        reports: ReportSeedCorpus.phase1Reports,
      );

      expect(related, isNotEmpty);
      expect(related.any((r) => r.id == 'rep_ub_2025_26'), isTrue,
          reason: 'Budget shares economy category and themes with Economic Survey');
      expect(related.any((r) => r.id == 'rep_es_2024_25'), isFalse,
          reason: 'source report must be excluded');
    });

    test('returns related reports through the repository API', () async {
      final repository = InMemoryReportRepository();
      final related =
          await repository.getRelatedReports('rep_es_2024_25', maxResults: 5);

      expect(related, isNotEmpty);
      expect(related.length, lessThanOrEqualTo(5));
      expect(related.any((r) => r.id == 'rep_es_2024_25'), isFalse);
    });

    test('returns empty for unknown report id', () async {
      final repository = InMemoryReportRepository();
      final related = await repository.getRelatedReports('rep_does_not_exist');
      expect(related, isEmpty);
    });
  });
}
