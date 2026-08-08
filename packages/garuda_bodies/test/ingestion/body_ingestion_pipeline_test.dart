import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';

void main() {
  group('BodyIngestionPipeline', () {
    test('ingests a valid raw JSON payload end-to-end', () async {
      final repo = InMemoryBodyRepository();
      final pipeline = BodyIngestionPipeline(repository: repo);

      final result = await pipeline.ingestRawPayloads([
        {
          'id': 'bod_gst_council',
          'officialName': 'Goods and Services Tax Council',
          'shortName': 'GST Council',
          'bodyType': 'constitutional',
          'category': 'council',
          'constitutionalBasis': 'directArticle',
          'statutoryBasis': 'constitutionItself',
          'bodyStatus': 'active',
          'bodyIndependence': 'constitutionallyIndependent',
          'yearEstablished': 2017,
          'establishingArticleIds': ['Article 279A'],
          'establishingActIds': [],
          'parentMinistry': 'Constituted under the Constitution (Article 279A)',
          'headquarters': 'New Delhi',
          'jurisdiction': 'national',
          'mandate':
              'Recommend taxes and rates of the Goods and Services Tax to the Union and States.',
          'composition':
              'Union Finance Minister (Chairperson) and State Finance/Taxation Ministers',
          'appointmentMechanism':
              'Members are the Union Finance Minister and State Finance/Taxation Ministers',
          'appointmentAuthority': 'membersElection',
          'tenure': 'Continuing body; meets as decided',
          'tenureType': 'notApplicable',
          'removalMechanism': 'Not applicable (ex-officio membership)',
          'reportingAuthority': 'unionCouncilOfMinisters',
          'officialSource': 'https://gstcouncil.gov.in/',
          'evidenceIds': [
            'ev_gst_council_official',
            'ev_gst_council_pib',
            'ev_gst_council_portal',
          ],
          'lastVerifiedDate': '2026-06-30',
          'relatedArticleIds': ['Article 279A', 'Article 246A'],
          'keywords': ['GST Council', 'Goods and Services Tax', 'GST', 'Tax Reform'],
        },
      ]);

      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 1);
      expect(result.validationReports, hasLength(1));
      expect(result.validationReports.first.isValid, isTrue);

      final saved = await repo.getBodyById('bod_gst_council');
      expect(saved, isNotNull);
      expect(saved!.officialName, 'Goods and Services Tax Council');
      expect(saved.bodyType, BodyType.constitutional);
      expect(saved.category, BodyCategory.council);
      expect(saved.establishingArticleIds, const ['Article 279A']);
    });

    test('rejects an invalid payload (missing evidence) and does not persist',
        () async {
      final repo = InMemoryBodyRepository();
      final pipeline = BodyIngestionPipeline(repository: repo);

      final result = await pipeline.ingestRawPayloads([
        {
          'id': 'bod_bad',
          'officialName': 'Bad Body',
          'shortName': 'BAD',
          'bodyType': 'statutory',
          'category': 'authority',
          'yearEstablished': 2019,
          'establishingActIds': ['Test Act, 2018'],
          'officialSource': 'https://eci.gov.in/',
          // no evidenceIds -> invalid
        },
      ]);

      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 0);
      expect(result.validationReports.first.isValid, isFalse);
      expect(await repo.getBodyById('bod_bad'), isNull);
    });

    test('detects duplicates during ingestion (existing + in-batch)',
        () async {
      final repo = InMemoryBodyRepository();
      final pipeline = BodyIngestionPipeline(repository: repo);

      final payload = {
        'id': 'bod_dup_batch',
        'officialName': 'Batch Duplicate Body',
        'shortName': 'BDB',
        'bodyType': 'statutory',
        'category': 'authority',
        'yearEstablished': 2020,
        'establishingActIds': ['Test Act, 2019'],
        'mandate': 'Duplicate test body.',
        'officialSource': 'https://eci.gov.in/',
        'evidenceIds': ['ev_bdb'],
      };

      final first = await pipeline.ingestRawPayloads([payload]);
      expect(first.totalValidated, 1);

      final second = await pipeline.ingestRawPayloads([payload]);
      expect(second.totalValidated, 0);
      expect(second.validationReports.first.isValid, isFalse);

      final inBatch = {
        ...payload,
        'id': 'bod_dup_inbatch',
        'officialName': 'In-Batch Duplicate Body',
      };
      final third = await pipeline.ingestRawPayloads([inBatch, inBatch]);
      expect(third.totalProcessed, 2);
      expect(third.totalValidated, 1);
      expect(third.validationReports[1].isValid, isFalse);
    });

    test('ingests from CSV and maps list columns', () async {
      final repo = InMemoryBodyRepository();
      final pipeline = BodyIngestionPipeline(repository: repo);

      const csv = 'id,officialName,shortName,bodyType,category,statutoryBasis,'
          'yearEstablished,establishingActIds,mandate,officialSource,evidenceIds,'
          'keywords,relatedArticleIds\n'
          'bod_aera,Airports Economic Regulatory Authority of India,AERA,'
          'statutory,authority,parliamentaryAct,2009,'
          '"Airports Economic Regulatory Authority of India Act, 2008",'
          'Regulate economic tariffs at major airports.,https://aera.gov.in/,'
          'ev_aera_official;ev_aera_pib,AERA;Airports;Regulator,Article 246\n';

      final result = await pipeline.ingestCsv(csv);
      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 1);

      final saved = await repo.getBodyById('bod_aera');
      expect(saved, isNotNull);
      expect(saved!.keywords, contains('Regulator'));
      expect(saved.evidenceIds, hasLength(2));
      expect(saved.establishingActIds,
          contains('Airports Economic Regulatory Authority of India Act, 2008'));
      expect(saved.yearEstablished, 2009);
    });

    test('submits every ingested body into the editorial workflow', () async {
      final repo = InMemoryBodyRepository();
      final editorialService = BodyEditorialService();
      final pipeline = BodyIngestionPipeline(
        repository: repo,
        editorialService: editorialService,
      );

      await pipeline.ingestRawPayloads([
        {
          'id': 'bod_editorial_flow',
          'officialName': 'Editorial Flow Body',
          'shortName': 'EFB',
          'bodyType': 'statutory',
          'category': 'authority',
          'yearEstablished': 2021,
          'establishingActIds': ['Test Act, 2020'],
          'mandate': 'Editorial flow test body.',
          'officialSource': 'https://eci.gov.in/',
          'evidenceIds': ['ev_efb'],
        },
      ]);

      final ko = editorialService.workflowEngine
          .getKnowledgeObject('bod_editorial_flow');
      expect(ko, isNotNull);
      expect(ko!.package, 'garuda_bodies');
    });
  });
}
