import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('GARUDA International Organisations Library End-to-End Regression', () {
    test(
        'end-to-end flow: Seed Corpus, Validate, Ingest, Editorial, Search, Analytics, Related Orgs, Corpus Report',
        () async {
      final repository = InMemoryInternationalRepository();
      final editorialService = InternationalEditorialService();
      final pipeline = InternationalIngestionPipeline(
        repository: repository,
        editorialService: editorialService,
      );

      // 1. Ingest a real official organisation (UNODC — not in the seed corpus)
      // via the Pipeline.
      final rawPayload = [
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
          'relatedArticleIds': ['Article 51', 'Article 253'],
          'officialSource': 'https://www.unodc.org/',
          'evidenceIds': [
            'ev_unodc_official',
            'ev_unodc_pib',
            'ev_unodc_portal',
          ],
          'lastVerifiedDate': '2026-06-30',
          'keywords': ['UNODC', 'Drugs', 'Crime', 'Organised Crime'],
        }
      ];

      final ingestResult = await pipeline.ingestRawPayloads(rawPayload);
      expect(ingestResult.totalValidated, equals(1));

      // 2. Query Repository
      final allOrgs = await repository.getAllOrganisations();
      expect(allOrgs.length,
          greaterThanOrEqualTo(InternationalSeedCorpus.expectedInternationalCorpus + 1));

      final unodc = await repository.getOrganisationById('int_unodc');
      expect(unodc, isNotNull);
      expect(unodc!.acronym, 'UNODC');
      expect(unodc.evidenceIds, isNotEmpty);

      // 3. Multi-field Search
      final searchResults = await repository.searchOrganisations(
        const InternationalSearchQuery(acronym: 'UNODC'),
      );
      expect(searchResults, isNotEmpty);
      expect(searchResults.any((o) => o.id == 'int_unodc'), isTrue);

      final treatyResults = await repository.searchOrganisations(
        const InternationalSearchQuery(
            treaty: 'General Assembly'),
      );
      expect(treatyResults.any((o) => o.id == 'int_unodc'), isTrue);

      // 4. Editorial Workflow
      editorialService.advanceEditorialStage(
          objectId: unodc.id, actorId: 'ed1', actorName: 'Editor');
      editorialService.advanceEditorialStage(
          objectId: unodc.id, actorId: 'ed2', actorName: 'Peer');
      editorialService.advanceEditorialStage(
          objectId: unodc.id, actorId: 'ed3', actorName: 'Chief');

      final approved = unodc.copyWith(editorialStatus: EditorialStatus.approved);
      final published = editorialService.publishObject(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, EditorialStatus.published);

      // 5. Related-Organisation Discovery
      final related = await repository.getRelatedOrganisations(unodc);
      expect(related, isNotEmpty);
      expect(related.every((o) => o.id != 'int_unodc'), isTrue);

      // 6. Analytics
      final analytics = InternationalAnalyticsEngine.generateReport(
        organisations: allOrgs,
        expectedOrganisations: InternationalSeedCorpus.expectedInternationalCorpus,
      );
      expect(analytics.totalOrganisations, allOrgs.length);
      expect(analytics.categoryDistribution, isNotEmpty);
      expect(analytics.topTreaties, isNotEmpty);
      expect(analytics.mostInterconnectedOrganisations, isNotEmpty);
      expect(analytics.indiaRelevantOrganisations, isNotEmpty);

      // 7. Corpus Coverage Report
      final corpusReport = await repository.generateCorpusReport();
      expect(corpusReport.totalImportedOrganisations, allOrgs.length);
      expect(corpusReport.totalTreatyLinks, greaterThan(0));
      expect(corpusReport.totalEvidenceReferences, greaterThan(0));
      expect(corpusReport.totalOrganisationLinks, greaterThan(0));
      expect(corpusReport.totalIndiaRelevantOrganisations, greaterThan(0));

      // 8. Whole seed corpus is production-valid
      for (final o in InternationalSeedCorpus.phase1Organisations) {
        final report = InternationalValidator.validate(o);
        expect(report.isValid, isTrue,
            reason: 'Seed org ${o.id} must be valid: '
                '${report.issues.map((i) => i.message).join(' | ')}');
      }
    });
  });
}
