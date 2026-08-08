import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportIngestionPipeline multi-type ingestion', () {
    late InMemoryReportRepository repository;
    late ReportIngestionPipeline pipeline;

    setUp(() {
      repository = InMemoryReportRepository(seedDefaultCorpus: false);
      pipeline = ReportIngestionPipeline(
        repository: repository,
        editorialService: ReportEditorialService(),
      );
    });

    test('ingests an Index payload', () async {
      final imported = await pipeline.importIndices([
        {
          'id': 'idx_test_2025',
          'indexName': 'Test Innovation Index 2025',
          'publisher': 'Test Institute',
          'latestEditionYear': 2025,
          'officialUrl': 'https://test.gov.in/index',
          'latestRanking': 'India rank 45',
          'indiasRanking': '45',
          'trend': 'improving',
          'evidenceIds': ['ev_test_index_official'],
        },
      ]);

      expect(imported, hasLength(1));
      expect(await repository.getIndexById('idx_test_2025'), isNotNull);
    });

    test('rejects an invalid Index payload (no publisher, no evidence)',
        () async {
      final imported = await pipeline.importIndices([
        {
          'id': 'idx_bad',
          'indexName': 'Bad Index',
          'publisher': '',
          'latestEditionYear': 0,
        },
      ]);

      expect(imported, isEmpty);
      expect(await repository.getIndexById('idx_bad'), isNull);
    });

    test('ingests a Survey payload', () async {
      final imported = await pipeline.importSurveys([
        {
          'id': 'srv_test_2025',
          'officialTitle': 'Test Labour Survey 2024-25',
          'publishingOrganisation': 'Test Statistics Office',
          'publishingMinistry': 'Test Ministry',
          'surveyYear': 2025,
          'officialUrl': 'https://test.gov.in/survey',
          'evidenceIds': ['ev_test_survey_official'],
        },
      ]);

      expect(imported, hasLength(1));
      expect(await repository.getSurveyById('srv_test_2025'), isNotNull);
    });

    test('ingests an Indicator payload', () async {
      final imported = await pipeline.importIndicators([
        {
          'id': 'ind_test_1_5',
          'name': 'Test Indicator',
          'value': '1.5',
          'source': 'Test Source 2025',
          'referenceYear': 2025,
          'trend': 'improving',
          'category': 'economy',
          'evidenceIds': ['ev_test_indicator_official'],
        },
      ]);

      expect(imported, hasLength(1));
      expect(await repository.getIndicatorById('ind_test_1_5'), isNotNull);
    });

    test('ingests a mixed-type structured payload stream', () async {
      await pipeline.ingestStructured([
        {
          'objectType': 'report',
          'id': 'rep_mixed_01',
          'officialTitle': 'Mixed Annual Report 2025',
          'category': 'economy',
          'publishingOrganisation': 'Ministry of Finance',
          'publicationYear': 2025,
          'officialUrl': 'https://example.gov.in/mixed',
          'evidenceIds': ['ev_mixed_official'],
        },
        {
          'objectType': 'index',
          'id': 'idx_mixed_01',
          'indexName': 'Mixed Index 2025',
          'publisher': 'Mixed Publisher',
          'latestEditionYear': 2025,
          'officialUrl': 'https://example.gov.in/mixed-idx',
          'evidenceIds': ['ev_mixed_index_official'],
        },
        {
          'objectType': 'survey',
          'id': 'srv_mixed_01',
          'officialTitle': 'Mixed Survey 2024-25',
          'publishingOrganisation': 'Mixed Stats Office',
          'surveyYear': 2025,
          'officialUrl': 'https://example.gov.in/mixed-srv',
          'evidenceIds': ['ev_mixed_survey_official'],
        },
        {
          'objectType': 'indicator',
          'id': 'ind_mixed_01',
          'name': 'Mixed Indicator',
          'value': '42',
          'source': 'Mixed Source',
          'referenceYear': 2025,
          'category': 'statistics',
          'evidenceIds': ['ev_mixed_indicator_official'],
        },
      ]);

      expect(await repository.getReportById('rep_mixed_01'), isNotNull);
      expect(await repository.getIndexById('idx_mixed_01'), isNotNull);
      expect(await repository.getSurveyById('srv_mixed_01'), isNotNull);
      expect(await repository.getIndicatorById('ind_mixed_01'), isNotNull);
    });

    test('deduplicates unchanged Index on re-ingestion', () async {
      final payload = {
        'id': 'idx_dup_test',
        'indexName': 'Dup Index 2025',
        'publisher': 'Dup Publisher',
        'latestEditionYear': 2025,
        'officialUrl': 'https://example.gov.in/dup-idx',
        'evidenceIds': ['ev_dup_index_official'],
      };

      final first = await pipeline.importIndices([payload]);
      final second = await pipeline.importIndices([payload]);

      expect(first, hasLength(1));
      expect(second, isEmpty);
      expect((await repository.getIndexById('idx_dup_test'))!.version, 1);
    });
  });
}
