import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('InMemoryReportRepository Tests', () {
    late InMemoryReportRepository repository;

    setUp(() {
      repository = InMemoryReportRepository();
    });

    test('should initialize with pre-seeded Phase-I corpus', () async {
      final reports = await repository.getAllReports();
      final indices = await repository.getAllIndices();
      final surveys = await repository.getAllSurveys();
      final indicators = await repository.getAllIndicators();

      expect(reports, hasLength(ReportSeedCorpus.expectedReportCorpus));
      expect(indices, hasLength(ReportSeedCorpus.expectedIndexCorpus));
      expect(surveys, hasLength(ReportSeedCorpus.expectedSurveyCorpus));
      expect(indicators, hasLength(ReportSeedCorpus.expectedIndicatorCorpus));

      final es = await repository.getReportById('rep_es_2024_25');
      expect(es, isNotNull);
      expect(es!.officialTitle, contains('Economic Survey'));
    });

    test('should save and retrieve a custom Report Knowledge Object', () async {
      final custom = ReportKnowledgeObject(
        id: 'rep_custom_1',
        officialTitle: 'Custom State Policy Report 2025',
        shortName: 'Custom Report',
        category: ReportCategory.governance,
        publishingOrganisation: 'State Planning Commission',
        publishingMinistry: 'State Government',
        publicationYear: 2025,
        officialUrl: 'https://example.gov.in/report',
        evidenceIds: const ['ev_custom'],
      );

      await repository.saveReport(custom);

      final retrieved = await repository.getReportById('rep_custom_1');
      expect(retrieved, isNotNull);
      expect(
          retrieved!.officialTitle, equals('Custom State Policy Report 2025'));
    });

    test('should query reports by category', () async {
      final finance =
          await repository.getReportsByCategory(ReportCategory.finance);
      expect(finance, hasLength(2));
      expect(finance.any((r) => r.id == 'rep_rbi_ar_2023_24'), isTrue);
      expect(finance.any((r) => r.id == 'rep_sebi_ar_2023_24'), isTrue);
    });

    test('should query reports by publisher, ministry and year', () async {
      final rbi = await repository.getReportsByPublisher('Reserve Bank');
      expect(rbi, hasLength(1));
      expect(rbi.first.id, equals('rep_rbi_ar_2023_24'));

      final financeMinistry = await repository.getReportsByMinistry('Finance');
      expect(financeMinistry, isNotEmpty);
      expect(financeMinistry.any((r) => r.id == 'rep_ub_2025_26'), isTrue);

      final y2024 = await repository.getReportsByYear(2024);
      expect(y2024.length, greaterThanOrEqualTo(8));
      expect(y2024.any((r) => r.id == 'rep_ipcc_ar6_2023'), isFalse);
    });

    test('should retrieve index and survey knowledge objects', () async {
      final ghi = await repository.getIndexById('idx_ghi_2024');
      expect(ghi, isNotNull);
      expect(ghi!.indiasRanking, contains('105'));

      final nfhs = await repository.getSurveyById('srv_nfhs5_2019_21');
      expect(nfhs, isNotNull);
      expect(nfhs!.shortName, equals('NFHS-5'));
    });

    test('should generate accurate Corpus Coverage Report', () async {
      final report = await repository.generateCorpusReport();

      expect(report.totalImportedReports, equals(18));
      expect(report.reportCoveragePercentage, equals(100.0));
      expect(report.totalImportedIndices, equals(9));
      expect(report.indexCoveragePercentage, equals(100.0));
      expect(report.totalImportedSurveys, equals(4));
      expect(report.totalIndicators,
          equals(ReportSeedCorpus.expectedIndicatorCorpus));
      expect(report.totalRecommendations, greaterThan(0));
      expect(report.totalChapters, greaterThan(0));
      expect(report.totalStatistics, greaterThan(0));
      expect(report.totalPyqLinks, greaterThan(0));
      expect(report.totalCurrentAffairsLinks, greaterThan(0));
      expect(report.categoryCounts.containsKey(ReportCategory.economy), isTrue);
    });
  });
}
