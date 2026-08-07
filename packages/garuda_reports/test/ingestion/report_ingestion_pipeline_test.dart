import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportIngestionPipeline Tests', () {
    late InMemoryReportRepository repository;
    late ReportEditorialService editorialService;
    late ReportIngestionPipeline pipeline;

    setUp(() {
      repository = InMemoryReportRepository(seedDefaultCorpus: false);
      editorialService = ReportEditorialService();
      pipeline = ReportIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );
    });

    test('should ingest raw JSON maps, validate and store in repository',
        () async {
      final rawPayloads = [
        {
          'id': 'rep_ingest_01',
          'officialTitle': 'Custom Annual Economic Report 2025',
          'shortName': 'Custom Economic Report',
          'category': 'economy',
          'publishingOrganisation': 'Ministry of Finance',
          'publishingMinistry': 'Ministry of Finance',
          'publicationYear': 2025,
          'officialUrl': 'https://example.gov.in/annual-report-2025',
          'evidenceIds': ['ev_ingest_01'],
        },
      ];

      final result = await pipeline.ingestRawPayloads(rawPayloads);

      expect(result.totalProcessed, equals(1));
      expect(result.totalValidated, equals(1));
      expect(result.objects.length, equals(1));

      final stored = await repository.getReportById('rep_ingest_01');
      expect(stored, isNotNull);
      expect(
          stored!.officialTitle, equals('Custom Annual Economic Report 2025'));
    });

    test('should reject payloads missing official URL and evidence', () async {
      final rawPayloads = [
        {
          'id': 'rep_invalid_ingest',
          'officialTitle': 'Missing Metadata Report',
          'publishingOrganisation': 'Unverified Body',
          'publicationYear': 2025,
        },
      ];

      final result = await pipeline.ingestRawPayloads(rawPayloads);

      expect(result.totalProcessed, equals(1));
      expect(result.totalValidated, equals(0));
      expect(result.validationReports.single.isValid, isFalse);
    });

    test('should ingest reports from a CSV payload', () async {
      const csv = '''
id,officialTitle,shortName,category,publishingOrganisation,publishingMinistry,publicationYear,edition,officialUrl,evidenceIds,keywords
rep_csv_01,State Health Report 2025,Health Report,health,State Health Society,State Government,2025,First,https://example.gov.in/health-2025,ev_csv_01;ev_csv_02,Health;Report
rep_csv_02,State Education Report 2025,Education Report,education,State Education Dept,State Government,2025,First,https://example.gov.in/edu-2025,ev_csv_03,Education;Report
''';

      final result = await pipeline.ingestCsv(csv);

      expect(result.totalProcessed, equals(2));
      expect(result.totalValidated, equals(2));

      final first = await repository.getReportById('rep_csv_01');
      expect(first, isNotNull);
      expect(first!.category, equals(ReportCategory.health));
      expect(first.evidenceIds, hasLength(2));
      expect(first.keywords, hasLength(2));
    });

    test('should build a Report Knowledge Object from PDF metadata (OCR-ready)',
        () {
      final report = pipeline.fromPdfMetadata(
        id: 'rep_pdf_01',
        officialTitle: 'Official PDF Extracted Report',
        extractedFields: {
          'publicationYear': 2025,
          'publishingOrganisation':
              'Ministry of Statistics and Programme Implementation',
          'officialUrl': 'https://example.gov.in/pdf-report',
        },
      );

      expect(report.id, equals('rep_pdf_01'));
      expect(report.publicationYear, equals(2025));
      expect(report.officialUrl, equals('https://example.gov.in/pdf-report'));
    });

    test('should handle empty CSV input gracefully', () async {
      final result = await pipeline.ingestCsv('');

      expect(result.totalProcessed, equals(0));
      expect(result.totalValidated, equals(0));
    });
  });
}
