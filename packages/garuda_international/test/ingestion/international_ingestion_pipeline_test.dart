import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InternationalIngestionPipeline', () {
    test('ingests a valid raw JSON payload end-to-end', () async {
      final repo = InMemoryInternationalRepository();
      final pipeline = InternationalIngestionPipeline(repository: repo);

      final result = await pipeline.ingestRawPayloads([
        {
          'id': 'int_unodc',
          'officialName': 'United Nations Office on Drugs and Crime',
          'shortName': 'UN Office on Drugs and Crime',
          'acronym': 'UNODC',
          'bodyType': 'programme',
          'category': 'unitedNations',
          'institutionalStatus': 'active',
          'treatyStatus': 'establishedByResolution',
          'establishedYear': 1997,
          'foundingTreaty':
              'Established 1997 by UN General Assembly (merger of UNDCP and the Centre for International Crime Prevention)',
          'headquarters': 'Vienna, Austria',
          'headquartersRegion': 'europe',
          'mandate':
              'Assist the UN in better addressing a coordinated response to drugs and crime.',
          'membershipType': 'fullMember',
          'geographicalRegion': 'global',
          'issueAreas': ['counterTerrorism', 'antiMoneyLaundering'],
          'indiaMembership': 'fullMember',
          'officialSource': 'https://www.unodc.org/',
          'evidenceIds': [
            'ev_unodc_official',
            'ev_unodc_pib',
            'ev_unodc_portal',
          ],
          'lastVerifiedDate': '2026-06-30',
          'relatedArticleIds': ['Article 51', 'Article 253'],
          'keywords': ['UNODC', 'Drugs', 'Crime', 'Organised Crime'],
        },
      ]);

      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 1);
      expect(result.validationReports, hasLength(1));
      expect(result.validationReports.first.isValid, isTrue);

      final saved = await repo.getOrganisationById('int_unodc');
      expect(saved, isNotNull);
      expect(saved!.officialName, 'United Nations Office on Drugs and Crime');
      expect(saved.acronym, 'UNODC');
      expect(saved.bodyType, InternationalBodyType.programme);
      expect(saved.issueAreas, contains(GlobalIssueArea.counterTerrorism));
    });

    test('rejects an invalid payload (missing evidence) and does not persist',
        () async {
      final repo = InMemoryInternationalRepository();
      final pipeline = InternationalIngestionPipeline(repository: repo);

      final result = await pipeline.ingestRawPayloads([
        {
          'id': 'int_bad',
          'officialName': 'Bad Organisation',
          'shortName': 'Bad Org',
          'acronym': 'BAD',
          'bodyType': 'organisation',
          'category': 'regionalGrouping',
          'establishedYear': 2019,
          'officialSource': 'https://www.un.org/',
          // no evidenceIds -> invalid
        },
      ]);

      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 0);
      expect(result.validationReports.first.isValid, isFalse);
      expect(await repo.getOrganisationById('int_bad'), isNull);
    });

    test('detects duplicates during ingestion (existing + in-batch)',
        () async {
      final repo = InMemoryInternationalRepository();
      final pipeline = InternationalIngestionPipeline(repository: repo);

      final payload = {
        'id': 'int_dup_batch',
        'officialName': 'Batch Duplicate Org',
        'shortName': 'Batch Duplicate',
        'acronym': 'BDO',
        'bodyType': 'organisation',
        'category': 'regionalGrouping',
        'establishedYear': 2020,
        'headquarters': 'New Delhi',
        'mandate': 'Duplicate test organisation.',
        'officialSource': 'https://www.un.org/',
        'evidenceIds': ['ev_bdo'],
      };

      final first = await pipeline.ingestRawPayloads([payload]);
      expect(first.totalValidated, 1);

      final second = await pipeline.ingestRawPayloads([payload]);
      expect(second.totalValidated, 0);
      expect(second.validationReports.first.isValid, isFalse);

      final inBatch = {
        ...payload,
        'id': 'int_dup_inbatch',
        'officialName': 'In-Batch Duplicate Org',
      };
      final third = await pipeline.ingestRawPayloads([inBatch, inBatch]);
      expect(third.totalProcessed, 2);
      expect(third.totalValidated, 1);
      expect(third.validationReports[1].isValid, isFalse);
    });

    test('ingests from CSV and maps list columns', () async {
      final repo = InMemoryInternationalRepository();
      final pipeline = InternationalIngestionPipeline(repository: repo);

      const csv = 'id,officialName,shortName,acronym,bodyType,category,'
          'establishedYear,headquarters,foundingTreaty,mandate,officialSource,'
          'evidenceIds,keywords,issueAreas\n'
          'int_wmo,World Meteorological Organization,World Meteorological Organization,WMO,'
          'specialisedAgency,unitedNations,1950,Geneva Switzerland,'
          'WMO Convention 1947,Coordinate meteorological and climate services.,'
          'https://wmo.int/,ev_wmo_official;ev_wmo_pib,WMO;Meteorology;Climate,climate;environment\n';

      final result = await pipeline.ingestCsv(csv);
      expect(result.totalProcessed, 1);
      expect(result.totalValidated, 1);

      final saved = await repo.getOrganisationById('int_wmo');
      expect(saved, isNotNull);
      expect(saved!.keywords, contains('Meteorology'));
      expect(saved.evidenceIds, hasLength(2));
      expect(saved.issueAreas, contains(GlobalIssueArea.climate));
      expect(saved.establishedYear, 1950);
    });

    test('submits every ingested organisation into the editorial workflow',
        () async {
      final repo = InMemoryInternationalRepository();
      final editorialService = InternationalEditorialService();
      final pipeline = InternationalIngestionPipeline(
        repository: repo,
        editorialService: editorialService,
      );

      await pipeline.ingestRawPayloads([
        {
          'id': 'int_editorial_flow',
          'officialName': 'Editorial Flow Org',
          'shortName': 'Editorial Flow',
          'acronym': 'EFO',
          'bodyType': 'organisation',
          'category': 'regionalGrouping',
          'establishedYear': 2021,
          'headquarters': 'New Delhi',
          'mandate': 'Editorial flow test organisation.',
          'officialSource': 'https://www.un.org/',
          'evidenceIds': ['ev_efo'],
        },
      ]);

      final ko = editorialService.workflowEngine
          .getKnowledgeObject('int_editorial_flow');
      expect(ko, isNotNull);
      expect(ko!.package, 'garuda_international');
    });
  });
}
