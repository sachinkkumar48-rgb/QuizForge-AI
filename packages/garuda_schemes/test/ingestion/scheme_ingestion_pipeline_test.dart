import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('SchemeIngestionPipeline', () {
    test('ingests a valid raw JSON payload end-to-end', () async {
      final repo = InMemorySchemeRepository();
      final pipeline = SchemeIngestionPipeline(repository: repo);

      final result = await pipeline.ingestRawPayloads([
        {
          'id': 'sch_ingested_2024',
          'officialName': 'Test Ingested Scheme',
          'shortName': 'TIS',
          'ministry': 'finance',
          'category': 'financialInclusion',
          'sector': 'financialInclusion',
          'schemeType': 'centralSector',
          'status': 'operational',
          'launchDate': '2024-01-01',
          'funding': {
            'fundingPattern': 'fullCentral',
            'centralShare': '100%',
            'financialAssistance': 'Test assistance',
          },
          'beneficiaries': ['women'],
          'officialSource': 'https://pmjdy.gov.in/',
          'evidenceIds': ['ev_ingested'],
          'lastVerifiedDate': '2026-06-30',
          'keywords': ['Test', 'Ingested'],
        },
      ]);

      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 1);
      expect(result.validationReports, hasLength(1));
      expect(result.validationReports.first.isValid, isTrue);

      final saved = await repo.getSchemeById('sch_ingested_2024');
      expect(saved, isNotNull);
      expect(saved!.officialName, 'Test Ingested Scheme');
      expect(saved.ministry, SchemeMinistry.finance);
      expect(saved.beneficiaries, contains(BeneficiaryGroup.women));
    });

    test('rejects an invalid payload (missing evidence) and does not persist',
        () async {
      final repo = InMemorySchemeRepository();
      final pipeline = SchemeIngestionPipeline(repository: repo);

      final result = await pipeline.ingestRawPayloads([
        {
          'id': 'sch_bad',
          'officialName': 'Bad Scheme',
          'shortName': 'BAD',
          'officialSource': 'https://nhm.gov.in/',
          // no evidenceIds -> invalid
        },
      ]);

      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 0);
      expect(result.validationReports.first.isValid, isFalse);
      expect(await repo.getSchemeById('sch_bad'), isNull);
    });

    test('detects duplicates during ingestion (existing + in-batch)',
        () async {
      final repo = InMemorySchemeRepository();
      final pipeline = SchemeIngestionPipeline(repository: repo);

      final payload = {
        'id': 'sch_dup_batch',
        'officialName': 'Batch Duplicate Scheme',
        'shortName': 'BDS',
        'ministry': 'finance',
        'category': 'financialInclusion',
        'sector': 'financialInclusion',
        'launchDate': '2021-03-01',
        'beneficiaries': ['women'],
        'officialSource': 'https://pmjdy.gov.in/',
        'evidenceIds': ['ev_bds'],
      };

      // First run: persisted.
      final first = await pipeline.ingestRawPayloads([payload]);
      expect(first.totalValidated, 1);

      // Second run: duplicate against the existing persisted object.
      final second = await pipeline.ingestRawPayloads([payload]);
      expect(second.totalValidated, 0);
      expect(second.validationReports.first.isValid, isFalse);

      // In-batch duplicate: two identical payloads with a fresh id -> only one persists.
      final inBatch = {
        ...payload,
        'id': 'sch_dup_inbatch',
        'officialName': 'In-Batch Duplicate Scheme',
      };
      final third = await pipeline.ingestRawPayloads([inBatch, inBatch]);
      expect(third.totalProcessed, 2);
      expect(third.totalValidated, 1);
      expect(third.validationReports[1].isValid, isFalse);
      expect(await repo.getSchemeById('sch_dup_inbatch'), isNotNull);
    });

    test('ingests from CSV and maps list columns', () async {
      final repo = InMemorySchemeRepository();
      final pipeline = SchemeIngestionPipeline(repository: repo);

      const csv = 'id,officialName,shortName,ministry,category,sector,'
          'launchDate,officialSource,evidenceIds,keywords,beneficiaries\n'
          'sch_csv_1,CSV Scheme,CSV,education,education,education,'
          '2022-05-01,https://www.education.gov.in/,ev_csv_1;ev_csv_2,'
          'CSV;Education;Digital,students;youth\n';

      final result = await pipeline.ingestCsv(csv);
      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 1);

      final saved = await repo.getSchemeById('sch_csv_1');
      expect(saved, isNotNull);
      expect(saved!.keywords, contains('Education'));
      expect(saved.beneficiaries, contains(BeneficiaryGroup.students));
      expect(saved.evidenceIds, hasLength(2));
    });

    test('submits every ingested scheme into the editorial workflow', () async {
      final repo = InMemorySchemeRepository();
      final editorialService = SchemeEditorialService();
      final pipeline = SchemeIngestionPipeline(
        repository: repo,
        editorialService: editorialService,
      );

      await pipeline.ingestRawPayloads([
        {
          'id': 'sch_editorial_flow',
          'officialName': 'Editorial Flow Scheme',
          'shortName': 'EFS',
          'ministry': 'healthFamilyWelfare',
          'category': 'health',
          'sector': 'health',
          'officialSource': 'https://nhm.gov.in/',
          'evidenceIds': ['ev_efs'],
        },
      ]);

      final ko = editorialService.workflowEngine
          .getKnowledgeObject('sch_editorial_flow');
      expect(ko, isNotNull);
      expect(ko!.package, 'garuda_schemes');
    });
  });
}
